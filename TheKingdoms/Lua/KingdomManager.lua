local K=MapModData.TheKingdoms
function K.CityKey(c) return c:GetX()..':'..c:GetY()..':'..c:GetGameTurnFounded()..':'..c:GetOriginalOwner() end
function K.City(k)
 local plot=Map.GetPlot(k.x,k.y);local c=plot and plot:GetPlotCity()
 if c and K.CityKey(c)==k.id then return c end
end
function K.HouseTarget(pop)
 return pop<4 and 2 or pop<7 and 3 or pop<10 and 4 or pop<14 and 5 or pop<19 and 6 or 7
end
function K.ReconcileKingdoms(s)
 local p=Players[s.pid]
 K.HouseViews[s]=nil
 for _,k in pairs(s.kingdoms) do k.active=false end
 for c in p:Cities() do
  local key=K.CityKey(c);local k=s.kingdoms[key]
  if not k then
   k={id=key,x=c:GetX(),y=c:GetY(),name=c:GetName(),founded=c:GetGameTurnFounded(),original=c:GetOriginalOwner(),owner=s.pid,
    houses={},stability=60,population=c:GetPopulation(),formationNext=K.Now()+K.Scale(8),history={}}
   s.kingdoms[key]=k;k.active=true
   K.History(s,'KINGDOMS','KINGDOM_FOUNDED',{k.name},nil,key)
   K.NewHouse(s,k);K.NewHouse(s,k)
  end
  k.active=true;k.owner=s.pid;k.name=c:GetName();k.cityID=c:GetID();k.population=c:GetPopulation();k.occupied=c:IsOccupied() and not c:IsNoOccupiedUnhappiness()
 end
 if not s.capitalKey then local capital=p:GetCapitalCity();if capital then s.capitalKey=K.CityKey(capital) end end
 if s.capitalKey then
  local capital=s.kingdoms[s.capitalKey];local owned=capital and capital.active
  if not owned and not s.capitalLost then
   s.capitalLost=true;s.capitalPenaltyUntil=K.Now()+K.Scale(20)
   local ruler=s.ruler and s.characters[s.ruler]
   if ruler then ruler.legitimacy=K.Clamp(ruler.legitimacy-25,0,100);local h=s.houses[ruler.house];h.prestige=math.max(0,h.prestige-15);h.claimBonus=h.claimBonus-20 end
   K.History(s,'KINGDOMS','CAPITAL_LOST',{capital and capital.name or K.Text('CAPITAL')})
   K.Notify(s.pid,'CAPITAL_LOST',capital and capital.name or K.Text('CAPITAL'))
  elseif owned and s.capitalLost then
   s.capitalLost=false;s.capitalPenaltyUntil=0
   local ruler=s.ruler and s.characters[s.ruler];if ruler then ruler.legitimacy=K.Clamp(ruler.legitimacy+15,0,100) end
   K.History(s,'KINGDOMS','CAPITAL_RESTORED',{capital.name});K.Notify(s.pid,'CAPITAL_RESTORED',capital.name)
  end
 end
 for _,k in pairs(s.kingdoms) do
  if not k.active then local c=K.City(k);k.owner=c and c:GetOwner() or -1;k.razed=not c end
 end
 K.HouseViews[s]=nil
end
function K.KingdomTick(s)
 K.ReconcileKingdoms(s)
 for _,key in ipairs(K.Keys(s.kingdoms)) do
  local k=s.kingdoms[key]
  if k.active and #k.houses<K.HouseTarget(k.population) and K.Now()>=k.formationNext then
   local parent
   if K.Rand(s,4)==0 then
    for _,h in ipairs(K.ActiveHouses(s,key)) do if K.Now()>=h.splitNext and (not parent or h.influence>parent.influence) then parent=h end end
   end
   K.NewHouse(s,k,parent);k.formationNext=K.Now()+K.Scale(8+K.Rand(s,5))
  end
 end
end
function K.RefreshRealm(s)
 local weighted,pop,hostile,count=0,0,0,0
 local ruler=s.ruler and s.characters[s.ruler]
 for _,h in ipairs(K.ActiveHouses(s)) do count=count+1;if h.loyalty<-20 then hostile=hostile+1 end end
 for _,key in ipairs(K.Keys(s.kingdoms)) do
  local k=s.kingdoms[key]
  if k.active then
   local value,rivalry=0,0
   for _,h in ipairs(K.ActiveHouses(s,key)) do
    value=value+(50+h.loyalty*.4+K.TraitSum(h,'stability'))*K.Influence(s,h)/100
    for rid,n in pairs(h.relations) do if n<-40 and s.houses[rid] and s.houses[rid].kingdom==key then rivalry=rivalry+1 end end
   end
   local c=K.City(k)
   value=value+(ruler and (ruler.legitimacy-50)*.15+K.TraitSum(ruler,'stability',K.RulerTraits) or -10)
   if c and c:GetNumBuilding(K.ID('BUILDING_KINGDOMS_WALL'))>0 then value=value+5 end
   value=value-math.min(10,rivalry*2)-(k.occupied and 12 or 0)-K.Wars(s.pid)*2-(s.war and 15 or 0)
   if (k.riotUntil or 0)>K.Now() then value=value-10 end
   k.stability=K.Clamp(math.floor(value+.5),0,100);weighted=weighted+k.stability*k.population;pop=pop+k.population
  end
 end
 local value=pop>0 and weighted/pop or 0
 value=value-(count>0 and hostile/count*12 or 0)-K.Wars(s.pid)*2
 if (s.capitalPenaltyUntil or 0)>K.Now() then value=value-20 end
 if s.war then value=value-8 end
 s.realm=K.Clamp(math.floor(value+.5),0,100)
 if s.realm<20 and not s.critical then s.critical=true;K.Notify(s.pid,'REALM_CRITICAL') elseif s.realm>=30 then s.critical=false end
 K.ApplyEffects(s)
end
