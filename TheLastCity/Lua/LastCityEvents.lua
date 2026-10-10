local L=MapModData.TheLastCity
function L.ReturnExtraCities(s)
 if s.incompatible then return end
 -- Native acquisition deletes/recreates the city object. Defer transfers until
 -- the next player turn, and retain only coordinate records across callbacks.
 local extra={}
 for c in Players[s.pid]:Cities() do
  if not s.capital or c:GetX()~=s.capital.x or c:GetY()~=s.capital.y or c:GetGameTurnFounded()~=s.capital.founded then
   extra[#extra+1]={x=c:GetX(),y=c:GetY(),founded=c:GetGameTurnFounded(),original=c:GetOriginalOwner(),previous=c:GetPreviousOwner()}
  end
 end
 for _,r in ipairs(extra) do local plot=Map.GetPlot(r.x,r.y);local c=plot and plot:GetPlotCity()
  if c and c:GetOwner()==s.pid and c:GetGameTurnFounded()==r.founded then
   local recipient
   for _,pid in ipairs({r.previous,r.original}) do
    if pid and pid>=0 and pid~=s.pid and Players[pid] and Players[pid]:IsAlive() and not Players[pid]:IsBarbarian() then recipient=pid;break end
   end
   if recipient then
    -- AcquireCity is the verified native transfer, including foreign capitals.
    Players[recipient]:AcquireCity(c,false,true)
    L.History(s,'CITY_RETURNED',tostring(r.x)..','..r.y)
   else
    -- Never delete/raze a capital or resurrect a dead civilization via an
    -- unverified call. Retain a documented exceptional puppet and report it.
    if not c:IsPuppet() then c:SetPuppet(true) end
    L.Notify(s,'RETURN_BLOCKED');L.Log('No living return recipient for gifted city')
   end
  end
 end
end
GameEvents.PlayerDoTurn.Add(L.Turn)
GameEvents.PlayerCanFoundCity.Add(function(pid)
 if not L.IsCity(pid) then return true end
 local s=L.State(pid);return not s.incompatible and not s.capital and Players[pid]:GetNumCities()==0
end)
GameEvents.PlayerCanTrain.Add(function(pid,unitType)
 if not L.IsCity(pid) then return true end
 local u=GameInfo.Units[unitType]
 if L.Founds(u) and L.State(pid).capital then return false end
 return true
end)
GameEvents.PlayerCityFounded.Add(function(pid) if L.IsCity(pid) then L.Initialize(pid) end end)
GameEvents.CityCanConstruct.Add(function(pid,cityID,building)
 local row=GameInfo.Buildings[building]
 if not row then return true end
 local key=row.Type:match('^BUILDING_LC_(.+)$')
 local infrastructure=false;for _,b in ipairs(L.Infrastructure) do if b.key==key then infrastructure=true;break end end
 if not infrastructure then return true end
 if not L.IsCity(pid) then return false end
 return L.CanInfrastructure(L.State(pid),key)
end)
GameEvents.CityConstructed.Add(function(pid,cityID,building)
 if not L.IsCity(pid) then return end
 local s=L.State(pid);if s.incompatible or L.Busy[pid] then return end
 local c=L.City(s);if not c or c:GetID()~=cityID then return end
 if building==L.ID('BUILDING_LC_DAWN') and s.dawn=='LOCKED' then
  -- Completion consumes supplies only once; a valid unlock was required by
  -- CityCanConstruct. Recheck the resource conditions at actual completion.
  if s.provisions>=150 and s.morale>=55 and s.wavesSurvived>=12 then
   L.Provisions(s,-150);s.dawn='FINAL_PENDING'
   if not s.wave then s.nextWave=L.Now()+L.Scale(L.Config.Warning);s.warning=nil end
   L.History(s,'DAWN_LAUNCHED');L.Notify(s,'DAWN_LAUNCHED')
  else
   s.dawn='AWAITING_SUPPLIES';L.Notify(s,'DAWN_AWAITING')
  end
 end
 L.Changed(s)
end)
GameEvents.UnitCreated.Add(function(pid,uid)
 if not L.IsCity(pid) then return end
 local s=L.State(pid);if s.incompatible then return end
 L.RefreshUnit(s,Players[pid]:GetUnitByID(uid))
 if not L.Busy[pid] then L.Save(pid) end
end)
GameEvents.UnitSetXY.Add(function(pid,uid)
 if L.IsCity(pid) then local s=L.State(pid);if not s.incompatible then L.RefreshUnit(s,Players[pid]:GetUnitByID(uid)) end end
end)
GameEvents.UnitConverted.Add(function(oldOwner,newOwner,oldID,newID,isUpgrade)
 local u=Players[newOwner] and Players[newOwner]:GetUnitByID(newID)
 if not u then return end
 if oldOwner~=newOwner then
  if u:IsHasPromotion(L.ID('PROMOTION_LC_INVADER')) then
   local def=GameInfo.Units[u:GetUnitType()]
   for row in GameInfo.Unit_FreePromotions{UnitType=def.Type} do
    if row.PromotionType=='PROMOTION_OCEAN_IMPASSABLE' or row.PromotionType=='PROMOTION_OCEAN_IMPASSABLE_UNTIL_ASTRONOMY' then
     u:SetHasPromotion(L.ID(row.PromotionType),true)
    end
   end
  end
  for _,key in ipairs({'INVADER','BOSS','COMMAND','PLAGUE','ELITE'}) do L.Promotion(u,key,false) end
 end
 if L.IsCity(newOwner) then
  local s=L.State(newOwner);if not s.incompatible then L.RefreshUnit(s,u);L.Save(newOwner) end
 elseif L.IsCity(oldOwner) then
  -- Capture conversion is not always gifting; explicitly remove all sanctuary
  -- modifiers from foreign-owned survivors after native promotion copying.
  for row in GameInfo.UnitPromotions() do
   if row.Type:match('^PROMOTION_LC_') then L.Promotion(u,row.Type:sub(14),false) end
  end
 end
end)
GameEvents.UnitUpgraded.Add(function(pid,oldID,newID)
 local new=Players[pid] and Players[pid]:GetUnitByID(newID);if not new then return end
 for _,target in ipairs(L.Players) do local s=L.State(target)
  if s.wave then
   for _,r in ipairs(s.wave.units) do if r.owner==pid and r.id==oldID and not r.dead then
    local tag=r.tag;local boss=r.boss;local replacement=L.Record(new,tag)
    for k,v in pairs(replacement) do r[k]=v end;r.boss=boss
   end end
   local r=s.wave.participants[tostring(oldID)]
   if r and r.owner==pid then
    s.wave.participants[tostring(oldID)]=nil;s.wave.participants[tostring(newID)]=L.Record(new,r.tag)
   end
  end
  for _,r in ipairs(s.temporary) do if r.owner==pid and r.id==oldID then
   local expiry=r.expiry;local replacement=L.Record(new,r.tag);for k,v in pairs(replacement) do r[k]=v end;r.expiry=expiry
  end end
  if target==pid then L.RefreshUnit(s,new) end
  L.Save(target)
 end
end)
GameEvents.UnitPrekill.Add(function(pid,uid,unitType,x,y,delay,killer)
 for _,target in ipairs(L.Players) do local s=L.State(target)
  if not s.incompatible then
   local changed=false
   if s.wave then
    for _,r in ipairs(s.wave.units) do
     if r.owner==pid and r.id==uid and not r.dead and killer and killer>=0 and L.Unit(r) then
      r.dead=true;s.wave.defeated=s.wave.defeated+1
      if r.boss then s.wave.bossKilled=true end
      changed=true
     end
    end
   end
   if target==pid and killer and killer>=0 and GameInfo.Units[unitType] and (GameInfo.Units[unitType].Combat or 0)>0 then
    local u=Players[pid]:GetUnitByID(uid)
    if u then
     local token=(u:GetScriptData() or ''):match('|(LCDEF_'..pid..'_%d+)|')
     if token and not s.lossSeen[token] then
      s.lossSeen[token]=true;L.Morale(s,-2);s.losses=s.losses+1;L.History(s,'SOLDIER_LOST');changed=true
     end
    end
   end
   if changed then L.Changed(s) end
  end
 end
end)
-- Capture callbacks only record observations. The next turn safely transfers
-- additional cities; gameplay never mutates a city within acquireCity's stack.
GameEvents.CityCaptureComplete.Add(function(oldOwner,capital,x,y,newOwner)
 if L.IsCity(newOwner) then local s=L.State(newOwner);if not s.incompatible then L.History(s,'EXTRA_CITY_PENDING');L.Save(newOwner) end end
 if L.IsCity(oldOwner) then local s=L.State(oldOwner);if not s.incompatible then L.History(s,'CAPITAL_LOST');L.Save(oldOwner) end end
end)
-- Every reload reconciles native effects from saved state, without processing
-- a turn or claiming pending event rewards a second time.
Events.LoadScreenClose.Add(function() for _,pid in ipairs(L.Players) do L.Initialize(pid) end end)
