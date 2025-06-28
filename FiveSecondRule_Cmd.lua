FiveSecondRule_Cmd = {}
FiveSecondRule_AddonName = "FiveSecondRule"

SLASH_FIVESECONDRULE1 = "/fsr"
SLASH_FIVESECONDRULE2 = "/fivesecondrule"

-- print message on game load
DEFAULT_CHAT_FRAME:AddMessage(FiveSecondRule_AddonName .. " loaded. Type " .. SLASH_FIVESECONDRULE1 .. " or " .. SLASH_FIVESECONDRULE2 .. " for settings help.")

SlashCmdList["FIVESECONDRULE"] = function(msg) FiveSecondRule_Cmd:Handle(msg) end

function FiveSecondRule_Cmd:Handle(msg)
    args = self:SplitByWhitespace(msg)
    if args then
        arg = self:NextArg(args)
        if arg == "stats" then
            self:HandleStatsCmd(args)
        elseif arg == "color" then
            self:HandleColorCmd(args)
        elseif arg == "reset" then
            self:ResetSettings()
        else
            self:PrintHelp("fsr")
        end
    else
        self:PrintHelp("info")
    end
end

function FiveSecondRule_Cmd:HandleStatsCmd(args)
    local base, effective, posBuff, negBuff = UnitStat("player", 5)
    DEFAULT_CHAT_FRAME:AddMessage("Spirit - Base: " .. base .. ", Effective: " .. effective .. ", +Buff: " .. posBuff .. ", -Buff: " .. negBuff)
end

function FiveSecondRule_Cmd:HandleColorCmd(args)
    local arg = self:NextArg(args)
    if arg and (arg == "manaloss" or arg == "managain") then
        local color = self:NextArg(args)
        if self:IsValidHexColor(color) then
            if arg == "manaloss" then
                self:ChangeSettings("manaLossColor", color)
            else
                self:ChangeSettings("manaGainColor", color)
            end
        else
            self:PrintHelp("color_hex_format")
        end
    else
        self:PrintHelp("color")
    end
end

function FiveSecondRule_Cmd:SplitByWhitespace(str)
    local words = {}
    for word in string.gfind(str, "%S+") do
        table.insert(words, word)
    end
    if table.getn(words) > 0 then return words else return nil end
end

function FiveSecondRule_Cmd:NextArg(args)
    if table.getn(args) == 0 then return nil end
    local arg = args[1]
    for i = 1, table.getn(args) - 1 do
       args[i] = args[i + 1]
    end
    args[table.getn(args)] = nil  -- remove duplicate last element
    return arg
end

function FiveSecondRule_Cmd:IsValidHexColor(color)
    return type(color) == "string" and string.find(string.lower(color), "^%x%x%x%x%x%x$") ~= nil
end

function FiveSecondRule_Cmd:ChangeSettings(name, value)
    DEFAULT_CHAT_FRAME:AddMessage(FiveSecondRule_AddonName .. ": Changed '" .. name .. "' from " .. FiveSecondRule_Settings[name] .. " to " .. value)
    FiveSecondRule_Settings[name] = value
end

function FiveSecondRule_Cmd:ResetSettings()
    FiveSecondRule_Settings = FiveSecondRule_Utils:ShallowCopy(FiveSecondRule_Defaults)
    DEFAULT_CHAT_FRAME:AddMessage(FiveSecondRule_AddonName .. ": Default settings restored.")
end

function FiveSecondRule_Cmd:PrintHelp(topic)
    if topic == "info" then
        DEFAULT_CHAT_FRAME:AddMessage(FiveSecondRule_AddonName .. ": Addon for five-second rule (FSR), mana tick (MP5), and mana gain tracking.")
        DEFAULT_CHAT_FRAME:AddMessage("Available commands:")
        DEFAULT_CHAT_FRAME:AddMessage("    /fsr stats -- print character spirit info")
        DEFAULT_CHAT_FRAME:AddMessage("    /fsr color <manaloss|managain> |cffdd2222RR|r|cff22dd22GG|r|cff2222ddBB|r -- change mana loss/gain text color (color in hex format)")
        DEFAULT_CHAT_FRAME:AddMessage("    /fsr reset -- reset to default settings")
    elseif topic == "fsr" then
        DEFAULT_CHAT_FRAME:AddMessage(FiveSecondRule_AddonName .. ": |cffdd2222Invalid command.")
        DEFAULT_CHAT_FRAME:AddMessage("Correct syntax:")
        DEFAULT_CHAT_FRAME:AddMessage("    /fsr stats -- print character spirit info")
        DEFAULT_CHAT_FRAME:AddMessage("    /fsr color <manaloss|managain> |cffdd2222RR|r|cff22dd22GG|r|cff2222ddBB|r -- change mana loss/gain text color (color in hex format)")
        DEFAULT_CHAT_FRAME:AddMessage("    /fsr reset -- reset to default settings")
    elseif topic == "color" then
        DEFAULT_CHAT_FRAME:AddMessage(FiveSecondRule_AddonName .. ": |cffdd2222Invalid command.")
        DEFAULT_CHAT_FRAME:AddMessage("Correct syntax:")
        DEFAULT_CHAT_FRAME:AddMessage("    /fsr color <manaloss|managain> |cffdd2222RR|r|cff22dd22GG|r|cff2222ddBB|r")
    elseif topic == "color_hex_format" then
        DEFAULT_CHAT_FRAME:AddMessage(FiveSecondRule_AddonName .. ": |cffdd2222Invalid command.")
        DEFAULT_CHAT_FRAME:AddMessage("Invalid color hex format or color not specified.")
        DEFAULT_CHAT_FRAME:AddMessage("Correct syntax:")
        DEFAULT_CHAT_FRAME:AddMessage("    /fsr color <manaloss|managain> |cffdd2222RR|r|cff22dd22GG|r|cff2222ddBB|r")
    end
end
