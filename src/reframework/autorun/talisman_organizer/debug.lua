local debug = false
local logString = ''
local getSkillName = nil

local SKILL_ID_MAX = sdk.find_type_definition('snow.data.DataDef.PlEquipSkillId'):get_field('PlEquipSkillId_Max'):get_data()
local DECO_ID_MAX = sdk.find_type_definition('snow.equip.DecorationsId'):get_field('Deco_Max'):get_data()
local getBaseDeco = sdk.find_type_definition('snow.data.ContentsIdDataManager'):get_method('getBaseData(snow.equip.DecorationsId)')

local function setup(skillNameMethod)
    getSkillName = skillNameMethod
end

local function debugLog(str)
    if debug then
        logString = logString .. str
    end
end

local function dump(o)
    if type(o) == 'table' then
       local s = '{ '
       for k,v in pairs(o) do
          if type(k) ~= 'number' then k = '"'..k..'"' end
          s = s .. '['..k..'] = ' .. dump(v) .. ','
       end
       return s .. '} '
    else
       return tostring(o)
    end
end

local function logTalisman(talisman)
    local result = ''

    local skillIdList = talisman:get_field('_TalismanSkillIdList')
    local lvList = talisman:get_field('_TalismanSkillLvList')
    local decoList = talisman:get_field('_TalismanDecoSlotNumList')

    result = result .. getSkillName:call(nil, skillIdList:call('get_Item', 0)) .. ',' .. lvList:call('get_Item',0) .. ','
    result = result .. getSkillName:call(nil, skillIdList:call("get_Item", 1)) .. ',' .. lvList:call('get_Item',1) .. '|'

    local lv4 = decoList:call("get_Item", 4)
    local lv3 = decoList:call("get_Item", 3)
    local lv2 = decoList:call("get_Item", 2)
    local lv1 = decoList:call("get_Item", 1)
    local decoString = ''
    if lv4 > 0 then
        for i = 1, lv4, 1 do
            decoString = decoString .. '4,'
        end
    end
    if lv3 > 0 then
        for i = 1, lv3, 1 do
            decoString = decoString .. '3,'
        end
    end
    if lv2 > 0 then
        for i = 1, lv2, 1 do
            decoString = decoString .. '2,'
        end
    end
    if lv1 > 0 then
        for i = 1, lv1, 1 do
            decoString = decoString .. '1,'
        end
    end

    while string.len(decoString) < string.len('0,0,0') do
        decoString = decoString .. '0,'
    end
    decoString = string.sub(decoString, 0,string.len('0,0,0'))

    result = result .. decoString .. "\n"
    return result
end

local function updateSkillJSON()   
    local skillMap = {}
    for decoID = 1, DECO_ID_MAX - 1 do
        local baseDeco = getBaseDeco:call(nil, decoID)
        if baseDeco then
            local skillID = tostring(baseDeco:get_SkillIdList()[0].value__)
            local skillLv = baseDeco:get_SkillLvList()[0].mValue
            local decoLv = baseDeco:get_DecorationLv()
            local skillName = getSkillName:call(nil, tonumber(skillID))

            if (skillMap[skillID] == nil) then
                skillMap[skillID] = {
                    name = skillName,
                    deco = {},
                }
            end
            skillMap[skillID]['deco'][skillLv] = decoLv + 0.0
        end
    end

    -- fill out any missing values with 0's
    for skillIDIdx = 1, SKILL_ID_MAX do
        local skillID = tostring(skillIDIdx)
        if (skillMap[skillID] == nil) then
            skillMap[skillID] = {
                name = '',
                deco = { 0.0, 0.0, 0.0, 0.0 },
            }
        else
            skillDecos = skillMap[skillID]['deco']
            for skillLv = 1, 4 do
                if skillDecos[skillLv] == nil then
                    skillDecos[skillLv] = 0.0
                end
            end
        end
    end

    json.dump_file('talisman_organizer/skill_decoration_data.json', skillMap)
end

local function outputLog()
    if debug then
        fs.write("talisman_organizer/log.txt", logString)
    end
end

return {
    debugLog = debugLog,
    logTalisman = logTalisman,
    outputLog = outputLog,
    updateSkillJSON = updateSkillJSON,
    setup = setup,
}
