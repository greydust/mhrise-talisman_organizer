-- Keybinding Variables
-- Copied from Infinite Wirebugs
require("talisman_organizer.key_enums")

local hwKB = nil
local kbToggleKey = 36 -- Default: [HOME]

local hwPad = nil
local padToggleKey = 4096 -- Default: [L3/LS]

local enableController = false
local enableKeyboard = false
local enabledKeybinding = false

re.on_pre_application_entry("UpdateBehavior", function() 
    if not hwKB then
        hwKB = sdk.get_managed_singleton("snow.GameKeyboard"):get_field("hardKeyboard")
    end
    if not hwPad then
        hwPad = sdk.get_managed_singleton("snow.Pad"):get_field("hard")
    end
end)

re.on_frame(function()
    if (hwKB:call("getTrg", kbToggleKey) and enableKeyboard) or (hwPad:call("orTrg", padToggleBtn) and enableController) then
        if enabledKeybinding then
            enabledKeybinding = false
        else
            enabledKeybinding = true
        end
    end
end)

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
        
        -- Added Keybinding Option
        if imgui.tree_node("Keybinding") then
            changed, enabledKeybinding = imgui.checkbox("Enable", enabledKeybinding)
            if imgui.tree_node("Shortcut keys") then
                changed, enableController = imgui.checkbox("Controller (default: [LS/L3])", enableController)
				changed, enableKeyboard = imgui.checkbox("Keyboard (default: [HOME])", enableKeyboard)
                imgui.tree_pop()
            end

            if not enabledKeybinding then
                organizer.OrganizeTalisman()
            end

            imgui.tree_pop()
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
