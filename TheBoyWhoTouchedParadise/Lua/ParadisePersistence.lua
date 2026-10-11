-- Length-prefixed data, never executable Lua. Player-scoped, versioned save keys.
ParadisePersistence = {}
local P = ParadisePersistence
local save = Modding.OpenSaveData()
local function encode(value)
    local kind = type(value)
    if kind == 'string' then return 's' .. #value .. ':' .. value end
    if kind == 'number' then return 'n' .. tostring(value) .. ';' end
    if kind == 'boolean' then return value and 'b1' or 'b0' end
    if kind == 'table' then
        local keys, parts = {}, {}
        for k in pairs(value) do keys[#keys + 1] = k end
        table.sort(keys, function(a,b) return tostring(a) < tostring(b) end)
        for _,k in ipairs(keys) do parts[#parts+1] = encode(k) .. encode(value[k]) end
        return 't' .. #keys .. ':' .. table.concat(parts)
    end
    error('Unsupported Paradise save value: '..kind)
end
local function decode(data, pos, depth)
    assert(depth < 20 and pos <= #data, 'Malformed Paradise save')
    local kind = data:sub(pos,pos)
    pos = pos + 1
    if kind == 'b' then
        local b = data:sub(pos,pos); assert(b=='0' or b=='1')
        return b=='1',pos+1
    end
    local delimiter = kind=='n' and ';' or ':'
    local last = assert(data:find(delimiter,pos,true))
    local n = assert(tonumber(data:sub(pos,last-1)))
    pos = last+1
    if kind=='n' then return n,pos end
    assert(n>=0 and n==math.floor(n) and n<=#data)
    if kind=='s' then
        assert(pos+n-1<=#data)
        return data:sub(pos,pos+n-1),pos+n
    end
    assert(kind=='t')
    local result = {}
    for _=1,n do
        local key,value
        key,pos=decode(data,pos,depth+1);value,pos=decode(data,pos,depth+1)
        result[key]=value
    end
    return result,pos
end
function P.Read(playerID)
    local data=save.GetValue('PARADISE_v1|'..playerID)
    if not data then return nil end
    local ok,value,pos=pcall(decode,data,1,0)
    if not ok or pos~=#data+1 or type(value)~='table' then
        error('Paradise state cannot be read; refusing to reset an existing journey')
    end
    return value
end
function P.Write(playerID,state)
    save.SetValue('PARADISE_v1|'..playerID,encode(state))
end
function P.Copy(state)
    return (decode(encode(state),1,0))
end
