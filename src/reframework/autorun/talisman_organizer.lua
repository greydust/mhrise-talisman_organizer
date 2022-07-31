local dataShortcutType = sdk.find_type_definition('snow.data.DataShortcut')
local getSkillName = dataShortcutType:get_method('getName(snow.data.DataDef.PlEquipSkillId)')
local skillIdType = sdk.find_type_definition('snow.data.DataDef.PlEquipSkillId')
local SKILL_ID_MAX = skillIdType:get_field('PlEquipSkillId_Max'):get_data()

local THE_MORE_THE_BETTER = 1
local THE_MORE_THE_BETTER_TEXT = 'The more the better'
local KEEP_EVERY_LEVEL = 2
local KEEP_EVERY_LEVEL_TEXT = 'Keep every level'
local KEEP_OPTIONS = {THE_MORE_THE_BETTER_TEXT, KEEP_EVERY_LEVEL_TEXT}
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

local skillDecorationData = json.load_file('talisman_organizer/skill_decoration_data.json')

local settings = {
    language = 1,
}
local loadedFonts = {}

local debug = require("talisman_organizer.debug")
debug.setup(getSkillName)

function initSettings()
    for i = 1, SKILL_ID_MAX, 1 do
        local skillId = tostring(i)
        local skillName = getSkillName:call(nil, i)
        if skillName ~= '' then
            settings[skillId] = {
                want = true,
                keep = THE_MORE_THE_BETTER
            }
        end
    end
end

local function saveSettings()
	json.dump_file('talisman_organizer.json', settings)
end

local function loadSettings()
	local loadedSettings = json.load_file('talisman_organizer.json')
	if loadedSettings then
        for skillId, loadedSetting in pairs(loadedSettings) do
            if type(loadedSetting) == 'table' and type(settings[skillId]) == 'table' then
                for k, v in pairs(loadedSetting) do
                    settings[skillId][k] = v
                end
            end
        end
	end
    if loadedSettings and loadedSettings.language then
        settings.language = loadedSettings.language
    end
end

initSettings()
loadSettings()

local function countTable(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

local function skillFillable(skillNeeded, decoLeft)
    for skillId, skillLv in pairs(skillNeeded) do
        -- get first skill and DFS
        if skillLv > 0 then
            for targetLv = skillLv, 1, -1 do
                local decoNeeded = skillDecorationData[skillId]['deco'][targetLv]
                if decoNeeded > 0 then
                    for targetDecoLv = decoNeeded, 4, 1 do
                        if decoLeft[targetDecoLv] > 0 then
                            skillNeeded[skillId] = skillNeeded[skillId] - targetLv
                            decoLeft[targetDecoLv] = decoLeft[targetDecoLv] - 1
                            local result = skillFillable(skillNeeded, decoLeft)
                            if result then
                                return result
                            end
                            
                            skillNeeded[skillId] = skillNeeded[skillId] + targetLv
                            decoLeft[targetDecoLv] = decoLeft[targetDecoLv] + 1

                            break
                        end
                    end
                end
            end

            return false
        end
    end

    return true
end

local function isBetter(talisman1, talisman2)
    local skillIdList1 = talisman1:get_field('_TalismanSkillIdList')
    local lvList1 = talisman1:get_field('_TalismanSkillLvList')
    local decoList1 = talisman1:get_field('_TalismanDecoSlotNumList')

    local skillIdList2 = talisman2:get_field('_TalismanSkillIdList')
    local lvList2 = talisman2:get_field('_TalismanSkillLvList')
    local decoList2 = talisman2:get_field('_TalismanDecoSlotNumList')

    -- compare decoration slots
    local decoLeft = {0, 0, 0, 0}
    for i = 1, 4, 1 do
        decoLeft[i] = decoLeft[i] + decoList1:call("get_Item", i)
    end
    for i = 1, 4, 1 do
        local need = decoList2:call("get_Item", i)
        if need > 0 then
            -- we need to find a slot at least as large as the slot in talisman2
            for j = i, 4, 1 do
                if need <= decoLeft[j] then
                    decoLeft[j] = decoLeft[j] - need
                    need = 0
                    break
                else
                    need = need - decoLeft[j]
                    decoLeft[j] = 0
                end
            end
            if need > 0 then
                return false
            end
        end
    end

    local skillNeeded = {}
    for i = 0, skillIdList2:call("get_Count")-1, 1 do
        local skillId = tostring(skillIdList2:call('get_Item', i))
        local skillLv = lvList2:call('get_Item', i)
        if skillId and skillLv then
            if settings[skillId] and settings[skillId].want then
                skillNeeded[skillId] = skillLv
            end
        end
    end
    for i = 0, skillIdList1:call("get_Count")-1, 1 do
        local skillId = tostring(skillIdList1:call('get_Item', i))
        local skillLv = lvList1:call('get_Item', i)
        if skillId and skillLv then
            if skillNeeded[skillId] ~= nil then
                if settings[skillId] and settings[skillId].keep == KEEP_EVERY_LEVEL and skillLv > skillNeeded[skillId] then
                    return false
                end
                if skillLv >= skillNeeded[skillId] then
                    skillNeeded[skillId] = nil
                else
                    skillNeeded[skillId] = skillNeeded[skillId] - skillLv
                end
            end
        end
    end

    if countTable(skillNeeded) == 0 then
        return true
    end

    if skillFillable(skillNeeded, decoLeft) then
        return true
    end

    return false
end

local function sendMessage(total, locked)
    local chatManager = sdk.get_managed_singleton("snow.gui.ChatManager")
    local msg = "Organized " .. total .. " talismans.\nLocked " .. locked .. '.'
    chatManager:call("reqAddChatInfomation", msg, 0)
end

local function organizeTalisman()
    logString = ''

    local count = 0
    local data = sdk.get_managed_singleton('snow.data.DataManager')
    if data then
        local equipBox = data:get_field('_PlEquipBox')
        if equipBox then
            local equipList = equipBox:call('getInventoryDataList(snow.data.EquipBox.InventoryType)', 0)
            if equipList then
                local bests = {}
                for id = 0, equipList:call("get_Count") - 1, 1 do
                    local equip = equipList:call("get_Item", id)
                    if equip:get_field('_IdType') == 3 then
                        count = count + 1
                        equip:call('set_IsLock', false)
                        noBetter = true

                        for tId in pairs(bests) do
                            talisman = equipList:call("get_Item", tonumber(tId))
                            if isBetter(talisman, equip) then
                                debug.debugLog(tId .. ' is better than ' .. id .. "\n")
                                debug.debugLog(debug.logTalisman(talisman))
                                debug.debugLog(debug.logTalisman(equip))
                                noBetter = false
                                break
                            end
                            if isBetter(equip, talisman) then
                                debug.debugLog(id .. ' is better than ' .. tId .. "\n")
                                debug.debugLog(debug.logTalisman(equip))
                                debug.debugLog(debug.logTalisman(talisman))
                                bests[tId] = nil
                            end
                        end
                        if noBetter then
                            debug.debugLog('Add ' .. id .. " to best list\n")
                            bests[tostring(id)] = true
                        end
                    end
                end

                local lockedCount = 0
                for id in pairs(bests) do
                    local equip = equipList:call("get_Item", tonumber(id))
                    equip:call('set_IsLock', true)
                    lockedCount = lockedCount + 1
                end

                sendMessage(count, lockedCount)
                debug.outputLog(count, lockedCount)
            end
        end
    end
end

local settingsWindow = false
re.on_draw_ui(function()
    if imgui.tree_node('Talisman Organizer') then
        changed, value = imgui.combo('Language', settings.language, LANGUAGE_OPTIONS)
        if changed then
            settings.language = value
            saveSettings()
        end

        if imgui.button('Talisman Organizer settings') then
            settingsWindow = not settingsWindow
        end

        local currentLanguage = LANGUAGE_OPTIONS[settings.language]
        if not loadedFonts[currentLanguage] then
            loadedFonts[currentLanguage] = imgui.load_font(LANGUAGES[currentLanguage], 18, FONT_RANGE)
        end
        if imgui.begin_window('Talisman Organizer settings', settingsWindow, 0) then
            for i = 1, skillIdType:get_field('PlEquipSkillId_Max'):get_data(), 1 do
                local skillId = tostring(i)
                local skillName = getSkillName:call(nil, i)
                if skillName ~= '' then
                    imgui.begin_group()

                    imgui.push_font(loadedFonts[currentLanguage])
                    changed, value = imgui.checkbox("Want " .. skillName, settings[skillId].want)
                    if changed then
                        settings[skillId].want = value
                        saveSettings()
                    end
                    imgui.pop_font()

                    imgui.same_line()
                    changed, value = imgui.combo(skillId, settings[skillId].keep, KEEP_OPTIONS)
                    if changed then
                        settings[skillId].keep = value
                        saveSettings()
                    end
                    imgui.end_group()
                end
            end

            imgui.end_window()
        else
            settingsWindow = false
        end

        if imgui.button('Organize talisman') then
            organizeTalisman()
        end

        imgui.tree_pop();
    end
end)
