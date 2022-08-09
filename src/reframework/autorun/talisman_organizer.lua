local debug = require("talisman_organizer.debug")
local nativeUI = require('talisman_organizer.native_ui')
local organizer = require('talisman_organizer.organizer')
local setting = require('talisman_organizer.setting')
local util = require('talisman_organizer.util')

local dataShortcutType = sdk.find_type_definition('snow.data.DataShortcut')
local getSkillName = dataShortcutType:get_method('getName(snow.data.DataDef.PlEquipSkillId)')
local skillIdType = sdk.find_type_definition('snow.data.DataDef.PlEquipSkillId')
local SKILL_ID_MAX = skillIdType:get_field('PlEquipSkillId_Max'):get_data()

local LANGUAGES = {
    default = 'NotoSans-Regular.ttf',
    ar = 'NotoSansArabic-Regular.ttf',
    ja = 'NotoSansJP-Regular.otf',
    kr = 'NotoSansKR-Regular.otf',
    ['zh-cn'] = 'NotoSansSC-Regular.otf',
    ['zh-tw'] = 'NotoSansTC-Regular.otf',
}
local LANGUAGE_OPTIONS = {'default', 'ar', 'ja', 'kr', 'zh-cn', 'zh-tw'}
local FONT_RANGE = { 0x1, 0xFFFF, 0 }

local loadedFonts = {}

debug.setup(getSkillName)

setting.InitSettings()
setting.LoadSettings()

nativeUI.Init()

local settingsWindow = false
re.on_draw_ui(function()
    if imgui.tree_node('Talisman Organizer') then
        changed, value = imgui.combo('Language', setting.Settings.language, LANGUAGE_OPTIONS)
        if changed then
            setting.Settings.language = value
            setting.SaveSettings()
        end

        if imgui.button('Talisman Organizer Settings') then
            settingsWindow = not settingsWindow
        end

        local currentLanguage = LANGUAGE_OPTIONS[setting.Settings.language]
        if not loadedFonts[currentLanguage] then
            loadedFonts[currentLanguage] = imgui.load_font(LANGUAGES[currentLanguage], 18, FONT_RANGE)
        end
        if imgui.begin_window('Talisman Organizer Settings', settingsWindow, 0) then
            for i = 1, SKILL_ID_MAX, 1 do
                local skillId = tostring(i)
                local skillName = getSkillName:call(nil, i)
                if skillName ~= '' then
                    imgui.begin_group()

                    imgui.push_font(loadedFonts[currentLanguage])
                    changed, value = imgui.checkbox("Want " .. skillName, setting.Settings[skillId].want)
                    if changed then
                        setting.Settings[skillId].want = value
                        setting.SaveSettings()
                    end
                    imgui.pop_font()

                    imgui.same_line()
                    changed, value = imgui.combo(skillId, setting.Settings[skillId].keep, util.Settings.KEEP_OPTIONS)
                    if changed then
                        setting.Settings[skillId].keep = value
                        setting.SaveSettings()
                    end
                    imgui.end_group()
                end
            end

            imgui.end_window()
        else
            settingsWindow = false
        end

        if imgui.button('Organize Talismans') then
            organizer.OrganizeTalisman()
        end

        imgui.tree_pop();
    end
end)

re.on_config_save(function()
	setting.SaveSettings();
end)
