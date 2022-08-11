local util = require('talisman_organizer.util')

local Setting = {
    Settings = {
        language = 1,
        enabled = false,
        enableController = false,
        enableKeyboard = false,
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
        for skillId, loadedSetting in pairs(loadedSettings) do
            if type(loadedSetting) == 'table' and type(Setting.Settings[skillId]) == 'table' then
                for k, v in pairs(loadedSetting) do
                    Setting.Settings[skillId][k] = v
                end
            end
        end
        if loadedSettings.language then
            Setting.Settings.language = loadedSettings.language
        end

        -- Keybinding Settings
        if loadedSettings.enabled then
            Setting.Settings.enabled = loadedSettings.enabled
        end

        if loadedSettings.enableKeyboard then
            Setting.Settings.enableKeyboard = loadedSettings.enableKeyboard
        end

        if loadedSettings.enableController then
            Setting.Settings.enableController = loadedSettings.enableController
        end
    end
end

return Setting
