local K=MapModData.TheKingdoms
local yields={'food','production','gold','science','culture','faith'}
local bits={1,2,4,8,16}
K.Dummies={}
local function register(name) K.Dummies[#K.Dummies+1]='BUILDING_KINGDOMS_'..name end
for _,yield in ipairs(yields) do for _,sign in ipairs({'P','N'}) do for _,bit in ipairs(bits) do register(yield:upper()..'_'..sign..bit) end end end
for _,field in ipairs({'MILITARY','XP','ARCHITECT'}) do for _,bit in ipairs(bits) do register(field..'_'..bit) end end
for _,n in ipairs({'CIVILWAR','RIOT','ESTATES','SUPPLIES'}) do register(n) end
function K.Building(c,name,count)
 local id=K.ID('BUILDING_KINGDOMS_'..name)
 if id and c:GetNumRealBuilding(id)~=count then c:SetNumRealBuilding(id,count) end
end
function K.ClearCity(c)
 if not c then return end
 for _,name in ipairs(K.Dummies) do local id=K.ID(name);if id and c:GetNumRealBuilding(id)>0 then c:SetNumRealBuilding(id,0) end end
end
local function binary(c,name,value,signed)
 value=K.Clamp(math.floor(value+.5),signed and -20 or 0,20)
 for _,bit in ipairs(bits) do
  local present=math.floor(math.abs(value)/bit)%2==1
  if signed then
   K.Building(c,name..'_P'..bit,present and value>0 and 1 or 0)
   K.Building(c,name..'_N'..bit,present and value<0 and 1 or 0)
  else K.Building(c,name..'_'..bit,present and 1 or 0) end
 end
end
function K.ApplyEffects(s)
 if K.ApplyingEffects then return end
 K.ApplyingEffects=true
 local ruler=s.ruler and s.characters[s.ruler]
 local royal=ruler and s.houses[ruler.house]
 if royal and not s.kingdoms[royal.kingdom].active then royal=nil end
 for _,key in ipairs(K.Keys(s.kingdoms)) do
  local k=s.kingdoms[key];local c=K.City(k)
  if c and k.active then
   local effects={military=0,xp=0}
   for _,yield in ipairs(yields) do effects[yield]=0 end
   for _,h in ipairs(K.ActiveHouses(s,key)) do
    local weight=K.Influence(s,h)/100*(1+math.min(5,#k.houses-2)*.12)
    local loyalty=h.loyalty>=20 and 1 or h.loyalty>=-19 and .5 or h.loyalty>=-49 and .1 or -.5
    for field in pairs(effects) do effects[field]=effects[field]+K.TraitSum(h,field)*weight*loyalty end
   end
   for field,value in pairs(effects) do
    value=K.Clamp(value,-4,6)
    if royal then value=value+K.TraitSum(royal,field)*.7*(royal.loyalty>=0 and 1 or .25) end
    if ruler then value=value+K.TraitSum(ruler,field,K.RulerTraits) end
    if field=='military' or field=='xp' then binary(c,field:upper(),value,false) else binary(c,field:upper(),value,true) end
   end
   binary(c,'ARCHITECT',ruler and K.TraitSum(ruler,'building',K.RulerTraits) or 0,false)
   K.Building(c,'CIVILWAR',s.war and 1 or 0)
   K.Building(c,'RIOT',(k.riotUntil or 0)>K.Now() and 1 or 0)
   K.Building(c,'ESTATES',(k.estatesUntil or 0)>K.Now() and 1 or 0)
   K.Building(c,'SUPPLIES',(s.suppliesUntil or 0)>K.Now() and 1 or 0)
  elseif c then K.ClearCity(c) end
 end
 for u in Players[s.pid]:Units() do
  if u:IsCombatUnit() then K.Promotion(u,'CIVILWAR',s.war~=nil);K.Promotion(u,'RULER_COMBAT',ruler and K.TraitSum(ruler,'combat',K.RulerTraits)>0 or false) end
 end
 K.ApplyingEffects=false
end
