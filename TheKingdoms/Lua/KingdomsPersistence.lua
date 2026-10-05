-- Versioned, dual-bank, chunked snapshots in the game's save database.
-- No executable serialized Lua, external files, or UI-only globals.
local K = MapModData.TheKingdoms
local save = Modding.OpenSaveData()
local VERSION, CHUNK = 1, 6000
local function encode(v)
    local t = type(v)
    if t == 'nil' then return 'z' end
    if t == 'boolean' then return v and 't' or 'f' end
    if t == 'number' then return 'n' .. tostring(v) .. ';' end
    if t == 'string' then return 's' .. #v .. ':' .. v end
    assert(t == 'table', 'Unsupported political data type: ' .. t)
    local keys = {}
    for key in pairs(v) do keys[#keys + 1] = key end
    table.sort(keys, function(a,b) return type(a) == type(b) and a < b or type(a) < type(b) end)
    local parts = {'m', tostring(#keys), ':'}
    for _, key in ipairs(keys) do parts[#parts+1]=encode(key); parts[#parts+1]=encode(v[key]) end
    return table.concat(parts)
end
local function decode(s)
    local cursor = 1
    local function read(depth)
        assert(depth < 64 and cursor <= #s, 'Damaged snapshot')
        local t=s:sub(cursor,cursor); cursor=cursor+1
        if t=='z' then return nil elseif t=='t' then return true elseif t=='f' then return false end
        local delimiter=t=='n' and ';' or ':'
        local finish=assert(s:find(delimiter,cursor,true), 'Missing delimiter')
        local n=assert(tonumber(s:sub(cursor,finish-1)), 'Invalid length/number'); cursor=finish+1
        if t=='n' then return n end
        assert(n>=0 and n==math.floor(n) and n<=#s, 'Invalid length')
        if t=='s' then
            assert(cursor+n-1<=#s, 'Truncated string')
            local result=s:sub(cursor,cursor+n-1);cursor=cursor+n;return result
        end
        assert(t=='m', 'Unknown type')
        local result={}
        for _=1,n do local key=read(depth+1);assert(key~=nil);result[key]=read(depth+1) end
        return result
    end
    local result=read(0);assert(cursor==#s+1, 'Trailing data');return result
end
local function checksum(s)
    local h=0
    for i=1,#s do h=(h*31+s:byte(i))%2147483647 end
    return h
end
local function prefix(pid) return 'KINGDOMS_V1_P'..pid..'_' end
local function bank(pid, b)
    local key=prefix(pid)..b..'_'
    local count=save.GetValue(key..'count')
    if not count or count<1 or count>100000 then return nil end
    local chunks={}
    for i=1,count do local c=save.GetValue(key..i);if type(c)~='string' then return nil end;chunks[i]=c end
    local s=table.concat(chunks)
    if checksum(s)~=save.GetValue(key..'checksum') then return nil end
    local ok, result=pcall(decode,s)
    if ok and type(result)=='table' then return result end
end
local function migrate(s,pid)
    assert((s.version or 0)<=VERSION, 'Save uses a newer Kingdoms schema')
    s.version=VERSION;s.pid=pid
    for _,key in ipairs({'kingdoms','houses','characters','history','guards','pending','regnal','counters','claims'}) do s[key]=s[key] or {} end
    local function nextID(records,existing)
        local n=existing or 1;for id in pairs(records) do if type(id)=='number' then n=math.max(n,id+1) end end;return n
    end
    s.nextHouse=nextID(s.houses,s.nextHouse);s.nextCharacter=nextID(s.characters,s.nextCharacter)
    s.nextHistory=s.nextHistory or 1
    for i,e in ipairs(s.history) do e.id=e.id or i;s.nextHistory=math.max(s.nextHistory,e.id+1);e.args=e.args or {} end
    s.rng=s.rng or (713+pid*997);s.lastTurn=s.lastTurn or -1;s.realm=s.realm or 60
    for _,h in pairs(s.houses) do
        h.relations=h.relations or {};h.children=h.children or {};h.timeline=h.timeline or {}
        h.stats=h.stats or {};h.stats.rulers=h.stats.rulers or 0;h.stats.guards=h.stats.guards or 0
        h.stats.wars=h.stats.wars or 0;h.stats.completed=h.stats.completed or 0;h.stats.failed=h.stats.failed or 0
        h.completed=h.completed or {};h.claimBonus=h.claimBonus or 0
        h.traits=h.traits or {'Traditionalist','Loyalist'};h.prestige=h.prestige or 10;h.influence=h.influence or 40
        h.loyalty=h.loyalty or 35;h.claim=h.claim or 0;h.power=h.power or 0;h.founded=h.founded or 0
        h.origin=h.origin or h.kingdom;h.demandNext=h.demandNext or K.Now()+K.Scale(20);h.actionNext=h.actionNext or 0
        h.splitNext=h.splitNext or K.Now()+K.Scale(60);h.crest=h.crest or {symbol='Crown',background=0,color=0}
    end
    for _,k in pairs(s.kingdoms) do
        k.houses=k.houses or {};k.population=k.population or 1;k.stability=k.stability or 50
        k.formationNext=k.formationNext or K.Now()+K.Scale(8)
    end
    return s
end
function K.Load(pid)
    local active=save.GetValue(prefix(pid)..'active') or 'A'
    local state=bank(pid,active) or bank(pid,active=='A' and 'B' or 'A') or {}
    K.States[pid]=migrate(state,pid)
    K.Log('PERSISTENCE','Loaded player '..pid)
    return K.States[pid]
end
function K.State(pid) return K.States[pid] or K.Load(pid) end
function K.Save(pid)
    local state=K.States[pid];if not state then return end
    local s=encode(state);local active=save.GetValue(prefix(pid)..'active') or 'A'
    local b=active=='A' and 'B' or 'A';local key=prefix(pid)..b..'_'
    local count=math.ceil(#s/CHUNK)
    for i=1,count do save.SetValue(key..i,s:sub((i-1)*CHUNK+1,i*CHUNK)) end
    save.SetValue(key..'checksum',checksum(s));save.SetValue(key..'count',count)
    save.SetValue(prefix(pid)..'active',b)
    K.Log('PERSISTENCE','Saved '..#s..' bytes for player '..pid)
end
K.Encode, K.Decode = encode, decode
