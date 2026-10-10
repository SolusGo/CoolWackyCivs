-- Length-prefixed data; no loadstring or executable save content.
local L=MapModData.TheLastCity
local store=Modding.OpenSaveData()
function L.ReloadPersistence()
 store=Modding.OpenSaveData();L.States={};L.Caches={}
end
local function encode(v)
 local t=type(v)
 if t=='nil' then return 'z' elseif t=='boolean' then return v and 't' or 'f'
 elseif t=='number' then return 'n'..tostring(v)..';' elseif t=='string' then return 's'..#v..':'..v end
 assert(t=='table','Unsupported Last City snapshot type')
 local keys={};for k in pairs(v) do keys[#keys+1]=k end
 table.sort(keys,function(a,b) if type(a)==type(b) then return a<b end;return type(a)<type(b) end)
 local out={'m',#keys,':'}
 for _,k in ipairs(keys) do out[#out+1]=encode(k);out[#out+1]=encode(v[k]) end
 return table.concat(out)
end
local function decode(s)
 local pos=1
 local function read(depth)
  assert(depth<48 and pos<=#s,'Corrupt Last City snapshot')
  local t=s:sub(pos,pos);pos=pos+1
  if t=='z' then return nil elseif t=='t' then return true elseif t=='f' then return false end
  local finish=assert(s:find(t=='n' and ';' or ':',pos,true))
  local n=assert(tonumber(s:sub(pos,finish-1)));pos=finish+1
  if t=='n' then assert(n==n and math.abs(n)<1e14);return n end
  assert(n>=0 and n==math.floor(n) and n<=#s)
  if t=='s' then assert(pos+n-1<=#s);local v=s:sub(pos,pos+n-1);pos=pos+n;return v end
  assert(t=='m');local v={}
  for _=1,n do local k=read(depth+1);assert(k~=nil);v[k]=read(depth+1) end
  return v
 end
 local result=read(0);assert(pos==#s+1);return result
end
local function checksum(v) local h=0;for i=1,#v do h=(h*31+v:byte(i))%2147483647 end;return h end
local function prefix(pid) return 'LASTCITY_P'..pid..'_' end
local function anchor(pid)
 return (Players[pid]:GetScriptData() or ''):match('|LCSTATE2_'..pid..'_(%d+)|')
end
local function bank(pid,name)
 local k=prefix(pid)..name..'_';local count=store.GetValue(k..'count')
 if type(count)~='number' or count<1 or count>1000 then return end
 local parts={};for n=1,count do local v=store.GetValue(k..n);if type(v)~='string' then return end;parts[n]=v end
 local raw=table.concat(parts);if checksum(raw)~=store.GetValue(k..'sum') then return end
 local ok,v=pcall(decode,raw);if ok and type(v)=='table' then return v,checksum(raw) end
end
function L.Migrate(s,pid)
 if (s.version or 0)>L.Config.Version then
  s.incompatible=true;print('[LastCity] Newer save schema; simulation disabled for player '..pid);return s
 end
 s.version=L.Config.Version;s.pid=pid
 local defaults={provisions=L.Config.StartProvisions,capacity=L.Config.Storage,morale=L.Config.StartMorale,
 housing=L.Config.Housing,ration='STANDARD',rationNext=0,starvation=0,lastTurn=-1,
 rng=71933+pid*971,sequence=0,nextEvent=1,waveNumber=0,wavesSurvived=0,majorSieges=0,
 bosses=0,losses=0,refused=0,accepted=0,medicalCases=0,dawn='LOCKED',peakMilitary=0,
 foodRemainder=0,lastDamage=0,lastPillaged=0,gatesUntil=0,gates=0,nextUnit=1,collapse=0,infectionNext=0}
 for k,v in pairs(defaults) do if s[k]==nil then s[k]=v end end
 for _,k in ipairs({'experts','assigned','history','survivors','veterans','temporary','returns','lossSeen'}) do s[k]=s[k] or {} end
 for _,k in ipairs(L.Skills) do
  s.experts[k]=L.Clamp(s.experts[k] or 0,0,50)
  s.assigned[k]=L.Clamp(s.assigned[k] or 0,0,math.min(L.Config.ExpertCap,s.experts[k]))
 end
 if not L.Rations[s.ration] then s.ration='STANDARD' end
 s.provisions=L.Clamp(s.provisions,0,s.capacity);s.morale=L.Clamp(s.morale,0,100)
 return s
end
function L.State(pid)
 if L.States[pid] then return L.States[pid] end
 local active=store.GetValue(prefix(pid)..'active') or 'A'
 local s,sum=bank(pid,active)
 if not s then s,sum=bank(pid,active=='A' and 'B' or 'A') end
 local expected=anchor(pid)
 if (expected and (not s or tostring(sum)~=expected)) or (s and ((s.version or 0)>=2 and not expected or (s.lastTurn or -1)>L.Now())) then
  -- Never replay an earlier bank's refugee/reward against newer native city
  -- state. The marker travels inside the SAME native save as Population/units.
  s={incompatible=true,pid=pid};print('[LastCity] Snapshot/native save mismatch; simulation disabled')
 elseif not s and (store.GetValue(prefix(pid)..'active') or expected) then
  -- Corruption must not mint fresh starting resources or repeat population.
  s={incompatible=true,pid=pid};print('[LastCity] Both save banks invalid; player simulation disabled')
 else s=L.Migrate(s or {},pid) end
 L.States[pid]=s;return s
end
function L.Save(pid)
 local s=L.States[pid];if not s or s.incompatible then return end
 local raw=encode(s);local active=store.GetValue(prefix(pid)..'active') or 'A'
 local cache=L.Caches[pid] or {};L.Caches[pid]=cache
 if cache.saved==raw and anchor(pid)==tostring(checksum(raw)) then return end
 local name=active=='A' and 'B' or 'A';local k=prefix(pid)..name..'_'
 local count=math.ceil(#raw/6000);local old=store.GetValue(k..'count') or 0
 for n=1,count do store.SetValue(k..n,raw:sub((n-1)*6000+1,n*6000)) end
 for n=count+1,old do store.SetValue(k..n,nil) end
 store.SetValue(k..'sum',checksum(raw));store.SetValue(k..'count',count)
 store.SetValue(prefix(pid)..'active',name)
 local p=Players[pid];local data=p:GetScriptData() or ''
 data=data:gsub('|LCSTATE2_'..pid..'_%d+|','')
 p:SetScriptData(data..'|LCSTATE2_'..pid..'_'..checksum(raw)..'|');cache.saved=raw
end
L.Encode,L.Decode=encode,decode
