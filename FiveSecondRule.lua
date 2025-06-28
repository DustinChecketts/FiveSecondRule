-- FiveSecondRule
-- Minimal addon for WoW 1.12 to track mana usage, mana regeneration, and mana ticks.
-- Expected mana regen per tick is calculated dynamically based on class and spirit attribute.
-- Formulas (from https://vanilla-wow-archive.fandom.com/wiki/Spirit):
--   Priests and Mages:  13 + (spirit / 4)
--   Warlocks:           8 + (spirit / 4)
--   Druids, Shamans, Paladins, Hunters: 15 + (spirit / 5)
--
-- This version displays:
--   - FSRSpark: A 5-second countdown spark shown when mana is consumed.
--   - tickSpark: A left-to-right animation over 2 seconds that represents passive mana ticks.
--       * tickSpark is hidden when FSRSpark is active.
--       * tickSpark resets only when the observed mana gain is at least 90% of the expected value.
--   - manaTickText: A text display showing every mana change.
--       * Positive values (in light blue) are shown for regeneration.
--       * Negative values (in deep purple) are shown when mana is consumed.
--
-- Chat logging is commented out for normal operation; uncomment for debugging if needed.

-- Global addon table.
FiveSecondRule = {
    lastManaUseTime = 0,        -- Time when mana was last used (to start FSRSpark countdown)
    mp5Delay = 5,               -- 5-second rule delay for FSRSpark
    previousMana = UnitMana("player"),  -- Tracks the player's last known mana
    lastTickTime = nil,         -- Time of the last mana tick (for elapsed time calc)
    manaTickTimer = 0,          -- Timer for displaying manaTickText
    fadeTimer = 0,              -- Timer for fading manaTickText
    tickStartTime = nil,        -- Start time for tickSpark animation
}

local FiveSecondRuleFrame = CreateFrame("Frame", "FiveSecondRuleFrame", UIParent)
FiveSecondRuleFrame:SetFrameStrata("HIGH")

-----------------------------------------------------------
-- FSRSpark: The 5-second countdown spark
local fsrSpark = FiveSecondRuleFrame:CreateTexture(nil, "OVERLAY")
fsrSpark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
fsrSpark:SetBlendMode("ADD")
fsrSpark:SetWidth(16)
fsrSpark:SetHeight(32)
fsrSpark:SetDrawLayer("OVERLAY", 7)
fsrSpark:Hide()

-----------------------------------------------------------
-- tickSpark: The left-to-right animation for passive mana ticks (2 seconds duration)
local tickSpark = FiveSecondRuleFrame:CreateTexture(nil, "OVERLAY")
tickSpark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
tickSpark:SetBlendMode("ADD")
tickSpark:SetWidth(16)
tickSpark:SetHeight(32)
tickSpark:SetDrawLayer("OVERLAY", 8)
tickSpark:Hide()

-----------------------------------------------------------
-- manaTickText: Displays the mana change (positive for regen, negative for consumption)
local manaTickText = FiveSecondRuleFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
manaTickText:SetPoint("LEFT", PlayerFrameManaBar, "RIGHT", 2, 0)
manaTickText:SetFont("Fonts\\FRIZQT__.TTF", 11)
manaTickText:Hide()

-----------------------------------------------------------
-- CalculateExpectedRegen:
-- Determines expected mana regeneration per tick based on player class and effective Spirit.
function FiveSecondRule:CalculateExpectedRegen()
    local _, effectiveSpirit = UnitStat("player", 5)
    local _, playerClass = UnitClass("player")
    local expected = 0

    if playerClass == "PRIEST" or playerClass == "MAGE" then
        expected = 13 + (effectiveSpirit / 4)
    elseif playerClass == "WARLOCK" then
        expected = 8 + (effectiveSpirit / 4)
    elseif playerClass == "DRUID" or playerClass == "SHAMAN" or 
           playerClass == "PALADIN" or playerClass == "HUNTER" then
        expected = 15 + (effectiveSpirit / 5)
    else
        expected = 15 + (effectiveSpirit / 5)  -- fallback
    end

    return math.floor(expected + 0.5) -- round to nearest integer
end

-----------------------------------------------------------
-- UpdateFSRSpark:
-- Updates the FSRSpark position along the mana bar based on the 5-second countdown.
function FiveSecondRule:UpdateFSRSpark()
    local now = GetTime()
    local barWidth = PlayerFrameManaBar:GetWidth() or 100
    if now < self.lastManaUseTime + self.mp5Delay then
        local progress = (now - self.lastManaUseTime) / self.mp5Delay
        local pos = barWidth * (1 - progress)
        fsrSpark:ClearAllPoints()
        fsrSpark:SetPoint("CENTER", PlayerFrameManaBar, "LEFT", pos, 0)
        fsrSpark:Show()
    else
        fsrSpark:Hide()
    end
end

-----------------------------------------------------------
-- UpdateTickSpark:
-- Animates tickSpark from left-to-right over 2 seconds, unless FSRSpark is active.
function FiveSecondRule:UpdateTickSpark()
    if fsrSpark:IsShown() then
        tickSpark:Hide()
        return
    end

    if self.tickStartTime then
        local now = GetTime()
        local elapsed = now - self.tickStartTime
        if elapsed <= 2 then
            local barWidth = PlayerFrameManaBar:GetWidth() or 100
            local progress = elapsed / 2  -- progress over 2 seconds (0 to 1)
            local pos = barWidth * progress
            tickSpark:ClearAllPoints()
            tickSpark:SetPoint("CENTER", PlayerFrameManaBar, "LEFT", pos, 0)
            tickSpark:Show()
        else
            tickSpark:Hide()
            -- Do not reset tickStartTime here to allow current animation to finish.
        end
    else
        tickSpark:Hide()
    end
end

-----------------------------------------------------------
-- HideManaTickText:
-- Gradually fades out manaTickText over 2 seconds.
function FiveSecondRule:HideManaTickText()
    if GetTime() - self.manaTickTimer <= 2 then
        local fadeProgress = (GetTime() - self.fadeTimer) / 2
        manaTickText:SetAlpha(1 - fadeProgress)
        if fadeProgress >= 1 then
            manaTickText:Hide()
        end
    end
end

-----------------------------------------------------------
-- OnUpdate:
-- Main update function which detects mana consumption and regeneration.
function FiveSecondRule:OnUpdate()
    -- Hide UI if mana is full or if max mana is very low.
    if UnitManaMax("player") <= 100 or UnitMana("player") >= UnitManaMax("player") then
        fsrSpark:Hide()
        tickSpark:Hide()
        manaTickText:Hide()
        return
    end

    self:UpdateFSRSpark()

    local currentMana = UnitMana("player")
    local prevMana = self.previousMana

    -- If mana is consumed (decrease)
    if currentMana < prevMana then
        self.lastManaUseTime = GetTime()
        fsrSpark:Show()
        tickSpark:Hide()  -- Ensure tickSpark is hidden when FSRSpark is active

        local manaUsed = prevMana - currentMana
        -- Set manaTickText to display consumed mana in deep purple (hex color 800080)
        manaTickText:SetText(self:ManaLossText(manaUsed))
        manaTickText:SetAlpha(1)
        manaTickText:Show()

        -- Uncomment for debugging if needed:
        -- DEFAULT_CHAT_FRAME:AddMessage("Mana used: -" .. manaUsed)

        self.tickStartTime = nil  -- Reset tickSpark animation

    -- If mana is regenerated (increase)
    elseif currentMana > prevMana then
        local observedGain = currentMana - prevMana
        local expectedGain = self:CalculateExpectedRegen()
        local now = GetTime()
        local elapsed = self.lastTickTime and (now - self.lastTickTime) or 0
        self.lastTickTime = now

        -- Display observed gain as a positive number
        manaTickText:SetText(self:ManaGainText(observedGain))
        manaTickText:SetAlpha(1)
        manaTickText:Show()
        self.manaTickTimer = now
        self.fadeTimer = now

        -- Uncomment for debugging if needed:
        -- DEFAULT_CHAT_FRAME:AddMessage("Mana tick: +" .. observedGain .. " mana (expected: " .. expectedGain .. "). Elapsed: " .. string.format("%.2f", elapsed) .. " seconds.")

        -- Only reset the tickSpark animation if the observed gain is at least 90% of the expected value.
        if observedGain >= (0.9 * expectedGain) then
            self.tickStartTime = now
        end
    end

    -- Update previousMana at end of update cycle.
    self.previousMana = currentMana
    self:HideManaTickText()

    -- Update tickSpark animation (if applicable).
    self:UpdateTickSpark()
end

function FiveSecondRule:OnEvent(event)
    if event == "SPELLCAST_STOP" then
        local currentMana = UnitMana("player")
        if currentMana and currentMana < FiveSecondRule.previousMana then
            FiveSecondRule.lastManaUseTime = GetTime()
            fsrSpark:Show()
            tickSpark:Hide()
            local manaUsed = FiveSecondRule.previousMana - currentMana
            manaTickText:SetText(self:ManaLossText(manaUsed))
            manaTickText:SetAlpha(1)
            manaTickText:Show()
            -- Uncomment for debugging if needed:
            -- DEFAULT_CHAT_FRAME:AddMessage("Mana used (event): -" .. manaUsed)
            FiveSecondRule.tickStartTime = nil
        end
        FiveSecondRule.previousMana = currentMana or 0
    end
end

function FiveSecondRule:ManaLossText(msg)
    return "|cff" .. FiveSecondRule_Settings.manaLossColor .. "-" .. msg .. "|r"
end

function FiveSecondRule:ManaGainText(msg)
    return "|cff" .. FiveSecondRule_Settings.manaGainColor .. "+" .. msg .. "|r"
end

-----------------------------------------------------------
-- OnUpdate handler for the addon frame.
FiveSecondRuleFrame:SetScript("OnUpdate", function()
    FiveSecondRule:OnUpdate()
end)

-----------------------------------------------------------
-- SPELLCAST_STOP event handler: Detects mana consumption when spells end.
FiveSecondRuleFrame:RegisterEvent("SPELLCAST_STOP")
FiveSecondRuleFrame:SetScript("OnEvent", function(self, event)
    FiveSecondRule:OnEvent(event)
end)
