local debug = require('talisman_organizer.debug')
local setting = require('talisman_organizer.setting')
local util = require('talisman_organizer.util')

local Organizer = {};

local skillDecorationData = json.load_file('talisman_organizer/skill_decoration_data.json')

function Organizer.countTable(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

function Organizer.skillFillable(skillNeeded, decoLeft)
    debug.debugLog('  Try filling ' .. debug.dump(skillNeeded) .. ' with ' .. debug.dump(decoLeft) .. '\n')
    for skillId, skillLv in pairs(skillNeeded) do
        -- Find the first skill that need to be filled and DFS from here.
        if skillLv > 0 then
            -- Assuming that we're filling targetLv levels.
            for targetLv = skillLv, 1, -1 do
                local availableDecoList = skillDecorationData[skillId]['deco']
                local finalTargetLv = Organizer.hasDeco(availableDecoList, targetLv, setting.Settings[skillId].keep == util.Settings.THE_MORE_THE_BETTER)
                debug.debugLog('    Filling ' .. targetLv .. ' level(s) of ' .. skillId .. '. Availability: ' .. debug.dump(finalTargetLv) .. '\n')
                if finalTargetLv then
                    -- Find the smallest slot that can fit the deco.
                    for targetDecoLv = availableDecoList[finalTargetLv], 4, 1 do
                        if decoLeft[targetDecoLv] > 0 then
                            skillNeeded[skillId] = skillNeeded[skillId] - finalTargetLv
                            decoLeft[targetDecoLv] = decoLeft[targetDecoLv] - 1

                            local result = Organizer.skillFillable(skillNeeded, decoLeft)
                            if result then
                                return result
                            end

                            skillNeeded[skillId] = skillNeeded[skillId] + finalTargetLv
                            decoLeft[targetDecoLv] = decoLeft[targetDecoLv] + 1

                            break
                        end
                    end
                end
            end

            -- If we can't fill the first skill, return false.
            return false
        end
    end

    return true
end

-- Check the deco list for decos that match the skill level required.
-- If it wants "the more the better", it'll look for the decos that has higher or equal level.
-- If it wants "keep every level", it'll look for the decos that has the exact level.
-- Returns the level of the skill on the matched deco. If none, return false.
function Organizer.hasDeco(decoList, targetLv, moreIsBetter)
    debug.debugLog('      Testing deco availability for ' .. targetLv .. ' level(s) with ' .. debug.dump(decoList) .. '. moreIsBetter: ' .. debug.dump(moreIsBetter) .. '\n')
    if #decoList < targetLv then
        return false
    end

    if moreIsBetter then
        for lv = targetLv, 4, 1 do
            if decoList[lv] and decoList[lv] > 0 then
                return lv
            end
        end
    else
        if decoList[targetLv] and decoList[targetLv] > 0 then
            return targetLv
        end
    end
    return false
end

function Organizer.isBetter(talisman1, talisman2)
    local skillIdList1 = talisman1:get_field('_TalismanSkillIdList')
    local lvList1 = talisman1:get_field('_TalismanSkillLvList')
    local decoList1 = talisman1:get_field('_TalismanDecoSlotNumList')

    local skillIdList2 = talisman2:get_field('_TalismanSkillIdList')
    local lvList2 = talisman2:get_field('_TalismanSkillLvList')
    local decoList2 = talisman2:get_field('_TalismanDecoSlotNumList')

    -- compare decoration slots
    local decoLeft = {0, 0, 0, 0}
    for i = 1, 4, 1 do
        decoLeft[i] = decoLeft[i] + decoList1:call('get_Item', i)
    end
    for i = 1, 4, 1 do
        local need = decoList2:call('get_Item', i)
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
    for i = 0, skillIdList2:call('get_Count')-1, 1 do
        local skillId = tostring(skillIdList2:call('get_Item', i))
        local skillLv = lvList2:call('get_Item', i)
        if skillId and skillLv then
            if setting.Settings[skillId] and setting.Settings[skillId].want then
                skillNeeded[skillId] = skillLv
            end
        end
    end
    for i = 0, skillIdList1:call('get_Count')-1, 1 do
        local skillId = tostring(skillIdList1:call('get_Item', i))
        local skillLv = lvList1:call('get_Item', i)
        if skillId and skillLv then
            if skillNeeded[skillId] ~= nil then
                if setting.Settings[skillId] and setting.Settings[skillId].keep == util.Settings.KEEP_EVERY_LEVEL and skillLv > skillNeeded[skillId] then
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

    if Organizer.countTable(skillNeeded) == 0 then
        return true
    end

    if Organizer.skillFillable(skillNeeded, decoLeft) then
        return true
    end

    return false
end

function Organizer.sendMessage(total, locked, comparison)
    local chatManager = sdk.get_managed_singleton('snow.gui.ChatManager')
    local msg = 'Organized ' .. total .. ' talismans.\nLocked ' .. locked .. '.\n' .. comparison .. ' comparisons made.'
    chatManager:call('reqAddChatInfomation', msg, 0)
end

function Organizer.OrganizeTalisman()
    local logString = ''

    local data = sdk.get_managed_singleton('snow.data.DataManager')
    if data then
        local equipBox = data:get_field('_PlEquipBox')
        if equipBox then
            local equipList = equipBox:get_field("_WeaponArmorInventoryList")
            if equipList then
                local count = 0
                local comparison = 0
                local bests = {}

                -- Save all locked talisman as best if skipLocked is enabled.
                if setting.Settings.skipLocked then
                    for id = 0, equipList:call('get_Count') - 1, 1 do
                        local equip = equipList:call('get_Item', id)
                        if equip:get_field('_IdType') == 3 and equip:call('get_IsLock') == true then
                            debug.debugLog('Add ' .. id .. ' to best list\n')
                            bests[tostring(id)] = true
                        end
                    end
                end

                for id = 0, equipList:call('get_Count') - 1, 1 do
                    local equip = equipList:call('get_Item', id)
                    if equip:get_field('_IdType') == 3 then
                        count = count + 1

                        local noBetter = true
                        if equip:call('get_IsLock') == false or not setting.Settings.skipLocked then
                            debug.debugLog('Checking ' .. id .. '\n')
                            equip:call('set_IsLock', false)

                            for tId in pairs(bests) do
                                comparison = comparison + 1
                                local talisman = equipList:call('get_Item', tonumber(tId))
                                if Organizer.isBetter(talisman, equip) then
                                    debug.debugLog(tId .. ' is better than ' .. id .. '\n')
                                    debug.debugLog(debug.logTalisman(talisman))
                                    debug.debugLog(debug.logTalisman(equip))
                                    noBetter = false
                                    break
                                end
                                if Organizer.isBetter(equip, talisman) then
                                    debug.debugLog(id .. ' is better than ' .. tId .. '\n')
                                    debug.debugLog(debug.logTalisman(equip))
                                    debug.debugLog(debug.logTalisman(talisman))
                                    bests[tId] = nil
                                end
                            end
                        end
                        if noBetter then
                            debug.debugLog('Add ' .. id .. ' to best list\n')
                            bests[tostring(id)] = true
                        end
                    end
                end

                local lockedCount = 0
                for id in pairs(bests) do
                    local equip = equipList:call('get_Item', tonumber(id))
                    equip:call('set_IsLock', true)
                    lockedCount = lockedCount + 1
                end

                if count == 0 then
                    local chatManager = sdk.get_managed_singleton('snow.gui.ChatManager')
                    chatManager:call('reqAddChatInfomation', 'Please talk to the blacksmith first.', 0)
                else
                    Organizer.sendMessage(count, lockedCount, comparison)
                end
                debug.outputLog()
            end
        end
    end
end

return Organizer
