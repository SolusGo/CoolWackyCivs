-- Deterministic non-executable snapshots with checksum and previous-bank recovery.
local I=MapModData.TheShatteredEmpire
local save=Modding.OpenSaveData()
local VERSION,CHUNK=1,6000
local function encode(v)
 local t=type(v)
 if t=='nil' then return 'z' elseif t=='boolean' then return v and 't' or 'f'
 elseif t=='number' then return 'n'..tostring(v)..';' elseif t=='string' then return 's'..#v..':'..v end
 assert(t=='table','Unsupported imperial data: '..t)
 local keys={};for k in pairs(v) do keys[#keys+1]=k end
 table.sort(keys,function(a,b) if type(a)==type(b) then return a<b end;return type(a)<type(b) end)
 local parts={'m',tostring(#keys),':'}
 for _,key in ipairs(keys) do parts[#parts+1]=encode(key);parts[#parts+1]=encode(v[key]) end
 return table.concat(parts)
end
local function decode(s)
 local cursor=1
 local function read(depth)
  assert(depth<64 and cursor<=#s,'Damaged imperial snapshot')
  local t=s:sub(cursor,cursor);cursor=cursor+1
  if t=='z' then return nil elseif t=='t' then return true elseif t=='f' then return false end
  local finish=assert(s:find(t=='n' and ';' or ':',cursor,true));local n=assert(tonumber(s:sub(cursor,finish-1)));cursor=finish+1
  if t=='n' then assert(n==n and math.abs(n)<1e15);return n end
  assert(n>=0 and n==math.floor(n) and n<=#s)
  if t=='s' then assert(cursor+n-1<=#s);local v=s:sub(cursor,cursor+n-1);cursor=cursor+n;return v end
  assert(t=='m');local result={}
  for _=1,n do local key=read(depth+1);assert(key~=nil);result[key]=read(depth+1) end
  return result
 end
 local result=read(0);assert(cursor==#s+1);return result
end
local function checksum(s) local h=0;for n=1,#s do h=(h*31+s:byte(n))%2147483647 end;return h end
local function prefix(pid) return 'SHATTERED_V1_P'..pid..'_' end
local function bank(pid,b)
 local key=prefix(pid)..b..'_';local count=save.GetValue(key..'count')
 if type(count)~='number' or count<1 or count>2000 then return end
 local parts={};for n=1,count do local v=save.GetValue(key..n);if type(v)~='string' then return end;parts[n]=v end
 local data=table.concat(parts);if checksum(data)~=save.GetValue(key..'checksum') then return end
 local ok,result=pcall(decode,data);if ok and type(result)=='table' then return result end
end
function I.Migrate(s,pid)
 assert((s.version or 0)<=VERSION,'Newer Shattered Empire save schema')
 s.version=VERSION;s.pid=pid
 for _,key in ipairs({'governors','units','factions','history','wars','conquests','entitlements','dynasty'}) do s[key]=s[key] or {} end
 for _,key in ipairs({'nextGovernor','nextUnit','nextFaction','nextHistory','nextWarID','nextSuccession'}) do s[key]=s[key] or 1 end
 s.rng=s.rng or 9137+pid*997;s.authority=s.authority or 82;s.lastTurn=s.lastTurn or -1
 s.nextPolitical=s.nextPolitical or I.Now()+I.Scale(5);s.nextPalace=s.nextPalace or I.Now()+I.Scale(10)
 s.reform=s.reform or 'NONE';s.reformNext=s.reformNext or 0;s.nextWar=s.nextWar or 0
 s.successionNext=s.successionNext or I.Now()+I.Scale(40);s.eraSeen=s.eraSeen or Players[pid]:GetCurrentEra()
 s.warTurns=s.warTurns or 0;s.strain=s.strain or 0;s.averageLoyalty=s.averageLoyalty or 75
 s.startBusy=nil;s.actionBusy=nil
 if #s.dynasty==0 then s.dynasty[1]={name='Aurelius I',archetype='FOUNDER',trait=I.Text('HEIR_TRAIT_FOUNDER'),start=I.Now(),wars=0,rebellions=0,acquired=0,lost=0,reforms=0,circumstance='FOUNDING'} end
 for _,g in pairs(s.governors) do
  g.history=g.history or {};g.relationship=g.relationship or 0;g.stage=g.stage or 0;g.critical=g.critical or 0;g.actionNext=g.actionNext or 0
  g.loyalty=I.Clamp(g.loyalty or 75,0,100);g.ambition=I.Clamp(g.ambition or 25,0,100);g.prestige=g.prestige or 0
  g.demandNext=g.demandNext or I.Now()+I.Scale(20);g.population=g.population or 1
  s.nextGovernor=math.max(s.nextGovernor,(g.id or 0)+1)
 end
 for _,r in pairs(s.units) do s.nextUnit=math.max(s.nextUnit,(r.id or 0)+1) end
 for _,f in pairs(s.factions) do s.nextFaction=math.max(s.nextFaction,(f.id or 0)+1);f.units=f.units or {} end
 for _,e in ipairs(s.history) do s.nextHistory=math.max(s.nextHistory,(e.id or 0)+1) end
 if s.war then
  for _,field in ipairs({'authorityLost','authorityRecovered','troops','defections','restored'}) do s.war[field]=s.war[field] or 0 end
 end
 return s
end
function I.Load(pid)
 local active=save.GetValue(prefix(pid)..'active') or 'A'
 local s=bank(pid,active) or bank(pid,active=='A' and 'B' or 'A') or {}
 I.States[pid]=I.Migrate(s,pid);return I.States[pid]
end
function I.State(pid) return I.States[pid] or I.Load(pid) end
function I.Save(pid)
 local s=I.States[pid];if not s then return end
 local data=encode(s);local active=save.GetValue(prefix(pid)..'active') or 'A';local b=active=='A' and 'B' or 'A';local key=prefix(pid)..b..'_'
 local count=math.ceil(#data/CHUNK);local oldCount=save.GetValue(key..'count') or 0
 for n=1,count do save.SetValue(key..n,data:sub((n-1)*CHUNK+1,n*CHUNK)) end
 for n=count+1,oldCount do save.SetValue(key..n,nil) end
 save.SetValue(key..'checksum',checksum(data));save.SetValue(key..'count',count);save.SetValue(prefix(pid)..'active',b)
end
I.Encode,I.Decode=encode,decode
