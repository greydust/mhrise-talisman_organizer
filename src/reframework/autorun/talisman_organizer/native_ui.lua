local modUI = nil
local organizer = require('talisman_organizer.organizer')
local setting = require('talisman_organizer.setting')
local util = require('talisman_organizer.util')

local NativeUI = {}

local getSkillName = sdk.find_type_definition('snow.data.DataShortcut'):get_method('getName(snow.data.DataDef.PlEquipSkillId)')
local skillIdType = sdk.find_type_definition('snow.data.DataDef.PlEquipSkillId')
local SKILL_ID_MAX = skillIdType:get_field('PlEquipSkillId_Max'):get_data()


local detail = false
local skillSettingButtonLabel = 'Open skill settings'
local function updateSkillSettingLabel()
    if detail then
        skillSettingButtonLabel = 'Close skill settings'
    else
        skillSettingButtonLabel = 'Open skill settings'
    end
end

function NativeUI.draw()
    modUI.Header('Talisman Organizer')
    if modUI.Button('Organize', '', false, 'Organize talismans.') then
        organizer.OrganizeTalisman()
    end

    if modUI.Button(skillSettingButtonLabel, '', true, 'WARNING: this list contains all of the skills.') then
        detail = not detail
        updateSkillSettingLabel()
    end
    if detail then
        for i = 1, SKILL_ID_MAX, 1 do
            local skillId = tostring(i)
            local skillName = getSkillName:call(nil, i)
            if skillName ~= '' then
                modUI.Header(skillName)
                changed, value = modUI.CheckBox('Want', setting.Settings[skillId].want)
                if changed then
                    setting.Settings[skillId].want = value
                    setting.SaveSettings()
                end

                changed, value = modUI.Options('Level', setting.Settings[skillId].keep, util.Settings.KEEP_OPTIONS, util.Settings.KEEP_OPTIONS_MESSAGES)
                if changed then
                    setting.Settings[skillId].keep = value
                    setting.SaveSettings()
                end
            end
        end
    end
end

function NativeUI.Init()
    modUI = util.SafeRequire('ModOptionsMenu.ModMenuApi')
    if modUI then
        modUI.OnMenu('Talisman Organizer', 'Helps organize your talismans by locking only the useful ones.', NativeUI.draw)
    end
end

return NativeUI
