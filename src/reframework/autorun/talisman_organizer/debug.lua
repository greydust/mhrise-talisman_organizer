local debug = false
local logString = ''
local getSkillName = nil

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

local function outputLog()
    if debug then
        fs.write("talisman_organizer/log.txt", logString)
    end
end

return {
    debugLog = debugLog,
    logTalisman = logTalisman,
    outputLog = outputLog,
    setup = setup,
}