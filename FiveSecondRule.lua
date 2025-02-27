-- FiveSecondRule
-- Five-second rule (FSR), mana tick (MP5), and mana gain tracking for TurtleWoW (1.12)

FiveSecondRule = {
    tickPreviousMana = UnitMana("player"),
    frame = "FiveSecondRuleFrame",
    lastManaUseTime = 0,
    mp5Delay = 5, -- 5-second rule delay
    previousMana = UnitMana("player"),
    enabled = true,
    manaTickTimer = 0,   -- Timer for displaying manaTickText
    fadeTimer = 0,       -- Timer for fading the manaTickText
    fadeStarted = false, -- Flag to indicate if fade has started
    tickInterval = 2,    -- Assumed tick interval (in seconds)
    tickStartTime = 0,   -- Time at which the most recent tick occurred
}

-- Create frame
local FiveSecondRuleFrame = CreateFrame("Frame", "FiveSecondRuleFrame", UIParent)
FiveSecondRuleFrame:SetFrameStrata("HIGH")

-- FSR Countdown Spark (moves right-to-left as a five-second countdown)
local fsrSpark = FiveSecondRuleFrame:CreateTexture(nil, "OVERLAY")
fsrSpark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
fsrSpark:SetBlendMode("ADD")
fsrSpark:SetWidth(16)
fsrSpark:SetHeight(32)
fsrSpark:SetDrawLayer("OVERLAY", 7)
fsrSpark:Hide()

-- Tick Spark (moves left-to-right over the tick interval)
local tickSpark = FiveSecondRuleFrame:CreateTexture(nil, "OVERLAY")
tickSpark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
tickSpark:SetBlendMode("ADD")
tickSpark:SetWidth(16)
tickSpark:SetHeight(32)
tickSpark:SetDrawLayer("OVERLAY", 8)
tickSpark:Hide()

-- Mana Tick Text
local manaTickText = FiveSecondRuleFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
manaTickText:SetPoint("LEFT", PlayerFrameManaBar, "RIGHT", 2, 0)
manaTickText:SetTextColor(0.5, 0.65, 1) -- Light blue (for mana)
manaTickText:SetFont("Fonts\\FRIZQT__.TTF", 11) -- FrizQT font (default)
manaTickText:Hide()

-- Function to update the FSR countdown spark (right-to-left)
function FiveSecondRule:UpdateFSRSpark()
    local now = GetTime()
    local barWidth = PlayerFrameManaBar:GetWidth() or 100
    
    if now < FiveSecondRule.lastManaUseTime + FiveSecondRule.mp5Delay then
        local progress = (now - FiveSecondRule.lastManaUseTime) / FiveSecondRule.mp5Delay
        local pos = barWidth * (1 - progress)
        
        fsrSpark:ClearAllPoints()
        fsrSpark:SetPoint("CENTER", PlayerFrameManaBar, "LEFT", pos, 0)
        fsrSpark:Show()
    else
        fsrSpark:Hide()
    end
end

-- Function to update the tick spark (left-to-right) over the tick interval.
function FiveSecondRule:UpdateTickSpark()
    -- Only update if a tick has been recorded
    if FiveSecondRule.tickStartTime > 0 then
        local barWidth = PlayerFrameManaBar:GetWidth() or 100
        local progress = (GetTime() - FiveSecondRule.tickStartTime) / FiveSecondRule.tickInterval
        if progress < 1 then
            tickSpark:ClearAllPoints()
            tickSpark:SetPoint("CENTER", PlayerFrameManaBar, "LEFT", barWidth * progress, 0)
            tickSpark:Show()
        else
            tickSpark:Hide()
        end
    end
end

-- Event handler function
function FiveSecondRule:OnEvent(event)
    if event == "SPELLCAST_STOP" then
        local currentMana = UnitMana("player")
        if currentMana and FiveSecondRule.previousMana and currentMana < FiveSecondRule.previousMana then
            FiveSecondRule.lastManaUseTime = GetTime()
            fsrSpark:Show()  -- Force visibility of countdown spark
            tickSpark:Show() -- Also show tick spark (it will be reset in DetectManaTicks)
            -- Chat message commented out:
            -- DEFAULT_CHAT_FRAME:AddMessage("Mana used, beginning countdown.")
        end
        FiveSecondRule.previousMana = currentMana or 0
    end
end

-- Polling check for mana consumption in case no event fires
function FiveSecondRule:CheckMana()
    local currentMana = UnitMana("player")
    if currentMana and FiveSecondRule.previousMana and currentMana < FiveSecondRule.previousMana then
        FiveSecondRule.lastManaUseTime = GetTime()
        fsrSpark:Show()
        tickSpark:Show()
        -- DEFAULT_CHAT_FRAME:AddMessage("Mana used! Spark should begin.")
    end
    FiveSecondRule.previousMana = currentMana or 0
end

-- Function to detect mana regeneration ticks.
-- When a tick is detected (i.e. currentMana > tickPreviousMana), we update
-- the mana tick text and record the tick start time for the tickSpark.
function FiveSecondRule:DetectManaTicks()
    local currentMana = UnitMana("player")
    local maxMana = UnitManaMax("player")
    
    if currentMana >= maxMana then
        return -- No need to track if resource is full
    end
    
    if currentMana > FiveSecondRule.tickPreviousMana then
        local manaGained = currentMana - FiveSecondRule.tickPreviousMana
        -- Display the mana gain as a "+x" value
        manaTickText:SetText("+" .. manaGained)
        manaTickText:Show()
        
        -- Reset the fade timer for the text
        FiveSecondRule.manaTickTimer = GetTime()
        FiveSecondRule.fadeTimer = GetTime()
        
        -- Record tick start time for the tick spark
        FiveSecondRule.tickStartTime = GetTime()
        
        -- DEFAULT_CHAT_FRAME:AddMessage("Mana tick generated " .. manaGained .. " mana.")
    end
    
    FiveSecondRule.tickPreviousMana = currentMana
end

-- Fade out the mana tick text gradually over 2 seconds
function FiveSecondRule:HideManaTickText()
    if GetTime() - FiveSecondRule.manaTickTimer <= 2 then
        local fadeProgress = (GetTime() - FiveSecondRule.fadeTimer) / 2
        manaTickText:SetAlpha(1 - fadeProgress)
        if fadeProgress >= 1 then
            manaTickText:Hide()
        end
    end
end

-- OnUpdate handler:
-- If the player's maximum power is 100 or less (i.e. non-mana resource), hide addon features.
FiveSecondRuleFrame:SetScript("OnUpdate", function()
    if UnitManaMax("player") <= 100 then
        fsrSpark:Hide()
        tickSpark:Hide()
        manaTickText:Hide()
        return
    end
    FiveSecondRule:DetectManaTicks()
    FiveSecondRule:UpdateFSRSpark()
    FiveSecondRule:CheckMana()
    FiveSecondRule:HideManaTickText()
    FiveSecondRule:UpdateTickSpark() -- Update the tick spark's position
end)

-- Register events
FiveSecondRuleFrame:RegisterEvent("SPELLCAST_STOP")
FiveSecondRuleFrame:SetScript("OnEvent", function(self, event)
    FiveSecondRule:OnEvent(event)
end)
