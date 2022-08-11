require('talisman_organizer.input.joy_con_button')
require('talisman_organizer.input.keyboard_key')
require('talisman_organizer.input.ps_button')
require('talisman_organizer.input.steam_button')
require('talisman_organizer.input.xbox_button')

local THE_MORE_THE_BETTER_TEXT = 'The more the better'
local KEEP_EVERY_LEVEL_TEXT = 'Keep every level'

local Util = {
    Settings = {
        THE_MORE_THE_BETTER = 1,
        KEEP_EVERY_LEVEL = 2,
        KEEP_OPTIONS = {THE_MORE_THE_BETTER_TEXT, KEEP_EVERY_LEVEL_TEXT},
        KEEP_OPTIONS_MESSAGES = {'More levels is better.', 'More levels is not better nor worse.'},
        SettingGamepadShortcut = false,
        SettingKeyboardShortcut = false,
    },
    HardwareGamepad = nil,
    HardwareKeyboard = nil,
    QuestManager = nil,
    PadButton = require('talisman_organizer.input.xbox_button'),
    KeyboardKey = require('talisman_organizer.input.keyboard_key'),
}

function Util.SafeRequire(name)
    local success = pcall(function() require(name) end) 
    if success then
        return require(name)
    end
    return nil
end

function Util.DeepCopy(target, source)
    if type(source) ~= 'table' then return end
    
    for k, v in pairs(source) do
        if type(v) == 'table' then
            if type(target[k]) ~= 'table' then
                target[k] = {}
            end
            Util.DeepCopy(target[k], v)
        else
            target[k] = v
        end
    end
end

return Util
