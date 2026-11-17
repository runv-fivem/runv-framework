lib.string = string

local string_char = string.char
local math_random = math.random

local function getLetter() return string_char(math_random(65, 90)) end
local function getLowerLetter() return string_char(math_random(97, 122)) end
local function getInt() return math_random(0, 9) end
local function getAlphanumeric() return math_random(0, 1) == 1 and getLetter() or getInt() end

local formatChar = {
    ['1'] = getInt,
    ['A'] = getLetter,
    ['a'] = getLowerLetter,
    ['.'] = getAlphanumeric,
}

function string.random(pattern, length)
    local len = length or #pattern:gsub('%^', '')
    local arr = table.create(len, 0)
    local size = 0
    local i = 0

    while size < len do
        i = i + 1
        local char = pattern:sub(i, i)

        if char == '' then
            arr[size + 1] = string.rep(' ', len - size)
            break
        elseif char == '^' then
            i = i + 1
            char = pattern:sub(i, i)
        else
            local fn = formatChar[char]
            char = fn and fn() or char
        end

        size = size + 1
        arr[size] = char
    end

    return table.concat(arr)
end

function string.capitalize(str)
    return (str:gsub('^%l', string.upper))
end

function string.startsWith(str, prefix)
    return str:sub(1, #prefix) == prefix
end

function string.endsWith(str, suffix)
    return suffix == '' or str:sub(-#suffix) == suffix
end

function string.contains(str, value, plain)
    return str:find(value, 1, plain ~= false) ~= nil
end

function string.isBlank(str)
    return str:match('^%s*$') ~= nil
end

function string.escapePattern(str)
    return (str:gsub('([%(%)%.%%%+%-%*%?%[%]%^%$])', '%%%1'))
end

function string.replace(str, search, replacement, plain)
    if plain ~= false then
        search = string.escapePattern(search)
        replacement = replacement:gsub('%%', '%%%%')
    end

    return (str:gsub(search, replacement))
end

return lib.string
