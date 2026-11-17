-- DataView (MIT, see NOTICE.md)



local DataView = Class('DataView')

function DataView:constructor(length)
    length = math.tointeger(length)

    self.blob = string.blob(length)
    self.length = length
    self.offset = 1
    self.cangrow = true
end

local codes = {
    Int8 = 'i1',
    Uint8 = 'I1',
    Int16 = 'i2',
    Uint16 = 'I2',
    Int32 = 'i4',
    Uint32 = 'I4',
    Int64 = 'i8',
    Uint64 = 'I8',
    Float32 = 'f',
    Float64 = 'd',
    LuaInt = 'j',
    UluaInt = 'J',
    LuaNum = 'n',
    String = 'z'
}

local sizes = {
    String = -1,
}

local function format(big, code)
    return (big and '>' or '<') .. code
end

local function packblob(self, offset, value, code)
    local packed = self.blob:blob_pack(offset, code, value)

    if self.cangrow or packed == self.blob then
        self.blob = packed
        self.length = packed:len()
        return true
    else
        return false
    end
end

for type, code in pairs(codes) do
    local size = sizes[type] or string.packsize(code)
    sizes[type] = size

    DataView['get' .. type] = function(self, offset, bigEndian)
        offset = offset or 0

        if offset >= 0 then
            local value = self.blob:blob_unpack(self.offset + offset, format(bigEndian, code))

            return value
        end
    end

    DataView['set' .. type] = function(self, offset, value, bigEndian)
        if offset >= 0 and value then
            local o = self.offset + offset
            local length = (size < 0 and value:len()) or size

            if self.cangrow or ((o + (length - 1)) <= self.length) then
                if not packblob(self, o, value, format(bigEndian, code)) then
                    error('cannot grow subview')
                end
            else
                error('cannot grow dataview')
            end
        end

        return self
    end
end

return DataView
