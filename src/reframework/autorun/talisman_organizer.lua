local debug = require('talisman_organizer.debug')
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

re.on_pre_application_entry('UpdateBehavior', function()
    if not util.HardwareGamepad then
        local pad = sdk.get_managed_singleton('snow.Pad')
        if pad then
            util.HardwareGamepad = pad:get_field('hard')
            local padType = util.HardwareGamepad:get_field('_DeviceKindDetails')
            if padType ~= nil then
                if padType >= 5 and padType <= 9 then
                    util.PadButton = require('talisman_organizer.input.ps_button')
                elseif padType >= 10 and padType <= 14 then
                    util.PadButton = require('talisman_organizer.input.xbox_button')
                elseif padType >= 16 and padType <= 18 then
                    util.PadButton = require('talisman_organizer.input.joy_con_button')
                else
                    util.PadButton = require('talisman_organizer.input.xbox_button')
                end
            else
                util.PadButton = require('talisman_organizer.input.xbox_button')
            end
        end
    end

    if not util.HardwareKeyboard then
        local keyboard = sdk.get_managed_singleton('snow.GameKeyboard')
        if keyboard then
            util.HardwareKeyboard = keyboard:get_field('hardKeyboard')
        end
    end

    if not util.QuestManager then
        util.QuestManager = sdk.get_managed_singleton("snow.QuestManager")
    end

    setting.UpdateKeyBinding()
end)

re.on_frame(function()
    if (util.QuestManager and util.QuestManager:get_field("_QuestStatus") == 0) and 
            ((setting.Settings.enableGamepad and util.HardwareGamepad and util.HardwareGamepad:call('orTrg', setting.Settings.gamepadShortcut)) 
                or (setting.Settings.enableKeyboard and util.HardwareKeyboard and util.HardwareKeyboard:call('getTrg', setting.Settings.keyboardShortcut))) then
        organizer.OrganizeTalisman()
    end
end)

local settingsWindow = false
re.on_draw_ui(function()
    if imgui.tree_node('Talisman Organizer') then
        local changed, value = imgui.combo('Language', setting.Settings.language, LANGUAGE_OPTIONS)
        if changed then
            setting.Settings.language = value
            setting.SaveSettings()
        end

        
        if imgui.button('Organize Talismans') then
            organizer.OrganizeTalisman()
        end

        if imgui.button('Talisman Organizer Settings') then
            settingsWindow = not settingsWindow
        end

        if imgui.begin_window('Talisman Organizer Settings', settingsWindow, 0) then
            local currentLanguage = LANGUAGE_OPTIONS[setting.Settings.language]
            if not loadedFonts[currentLanguage] then
                loadedFonts[currentLanguage] = imgui.load_font(LANGUAGES[currentLanguage], 18, FONT_RANGE)
            end
    
            for i = 1, SKILL_ID_MAX, 1 do
                local skillId = tostring(i)
                local skillName = getSkillName:call(nil, i)
                if skillName ~= '' then
                    imgui.begin_group()

                    imgui.push_font(loadedFonts[currentLanguage])
                    changed, value = imgui.checkbox('Want ' .. skillName, setting.Settings[skillId].want)
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

        changed, value = imgui.checkbox('Enable Gamepad Shortcut', setting.Settings.enableGamepad)
        if changed then
            setting.Settings.enableGamepad = value
            setting.SaveSettings()
        end
        imgui.text('Gamepad Shortcut')
        imgui.same_line()
        if imgui.button(util.PadButton[setting.Settings.gamepadShortcut]) then
            if util.HardwareGamepad then
                util.Settings.SettingGamepadShortcut = true
            end
        end

        changed, value = imgui.checkbox('Enable Keyboard Shortcut', setting.Settings.enableKeyboard)
        if changed then
            setting.Settings.enableKeyboard = value
            setting.SaveSettings()
        end
        imgui.text('Keyboard Shortcut')
        imgui.same_line()
        if imgui.button(util.KeyboardKey[setting.Settings.keyboardShortcut]) then
            if util.HardwareKeyboard then
                util.Settings.SettingKeyboardShortcut = true
            end
        end        

        if imgui.button('Update Skill JSON') then
            debug.updateSkillJSON()
        end

        imgui.tree_pop();
    end
end)

re.on_config_save(function()
	setting.SaveSettings();
end)
