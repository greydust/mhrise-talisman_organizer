local util = require('talisman_organizer.util')

local Settings = {
    Settings = {
        language = 1,
    },
}

local getSkillName = sdk.find_type_definition('snow.data.DataShortcut'):get_method('getName(snow.data.DataDef.PlEquipSkillId)')
local SKILL_ID_MAX = sdk.find_type_definition('snow.data.DataDef.PlEquipSkillId'):get_field('PlEquipSkillId_Max'):get_data()

function Settings.InitSettings()
    for i = 1, SKILL_ID_MAX, 1 do
        local skillId = tostring(i)
        local skillName = getSkillName:call(nil, i)
        if skillName ~= '' then
            Settings.Settings[skillId] = {
                want = true,
                keep = util.Settings.THE_MORE_THE_BETTER
            }
        end
    end
end

function Settings.SaveSettings()
	json.dump_file('talisman_organizer.json', Settings.Settings)
end

function Settings.LoadSettings()
	local loadedSettings = json.load_file('talisman_organizer.json')
	if loadedSettings then
        for skillId, loadedSetting in pairs(loadedSettings) do
            if type(loadedSetting) == 'table' and type(Settings.Settings[skillId]) == 'table' then
                for k, v in pairs(loadedSetting) do
                    Settings.Settings[skillId][k] = v
                end
            end
        end
        if loadedSettings.language then
            Settings.Settings.language = loadedSettings.language
        end
    end
end

return Settings
