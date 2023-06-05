local util = require('talisman_organizer.util')

local Setting = {
    Settings = {
        language = 1,
        enableGamepad = false,
        gamepadShortcut = 8192,
        enableKeyboard = false,
        keyboardShortcut = 36,
        skipLocked = true,
    },
}

local getSkillName = sdk.find_type_definition('snow.data.DataShortcut'):get_method('getName(snow.data.DataDef.PlEquipSkillId)')
local SKILL_ID_MAX = sdk.find_type_definition('snow.data.DataDef.PlEquipSkillId'):get_field('PlEquipSkillId_Max'):get_data()

function Setting.InitSettings()
    for i = 1, SKILL_ID_MAX, 1 do
        local skillId = tostring(i)
        local skillName = getSkillName:call(nil, i)
        if skillName ~= '' then
            Setting.Settings[skillId] = {
                want = true,
                keep = util.Settings.THE_MORE_THE_BETTER
            }
        end
    end
end

function Setting.SaveSettings()
	json.dump_file('talisman_organizer.json', Setting.Settings)
end

function Setting.LoadSettings()
	local loadedSettings = json.load_file('talisman_organizer.json')
	if loadedSettings then
        util.DeepCopy(Setting.Settings, loadedSettings)
    end
end

function Setting.UpdateKeyBinding()
    if util.Settings.SettingGamepadShortcut then
        Setting.Settings.gamepadShortcut = 0
        local button = util.HardwareGamepad:get_field('_on')
        if button > 0 and util.PadButton[button] ~= nil then
            Setting.Settings.gamepadShortcut = button
            util.Settings.SettingGamepadShortcut = false
            Setting.SaveSettings()
        end
    end
    if util.Settings.SettingKeyboardShortcut then
        Setting.Settings.keyboardShortcut = 0
        for k, _ in pairs(util.KeyboardKey) do
            if util.HardwareKeyboard:call("getTrg", k) then
                Setting.Settings.keyboardShortcut = k
                util.Settings.SettingKeyboardShortcut = false
                Setting.SaveSettings()
                break
            end
        end
    end
end

return Setting
