local THE_MORE_THE_BETTER_TEXT = 'The more the better'
local KEEP_EVERY_LEVEL_TEXT = 'Keep every level'

local Util = {
    Settings = {
        THE_MORE_THE_BETTER = 1,
        KEEP_EVERY_LEVEL = 2,
        KEEP_OPTIONS = {THE_MORE_THE_BETTER_TEXT, KEEP_EVERY_LEVEL_TEXT},
        KEEP_OPTIONS_MESSAGES = {'More levels is better.', 'More levels is not better nor worse.'}
    },
}

function Util.SafeRequire(name)
    local success = pcall(function() require(name) end) 
    if success then
        return require(name)
    end
    return nil
end

return Util
