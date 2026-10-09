local I=MapModData.TheShatteredEmpire
local function valid(s,plot)
 if not plot or plot:IsWater() or plot:IsMountain() or plot:IsImpassable() or plot:IsCity() or plot:GetNumUnits()>0 then return false end
 if plot:GetOwner()~=-1 and plot:GetOwner()~=s.pid then return false end
 local p=Players[s.pid];if not p:CanFound(plot:GetX(),plot:GetY()) then return false end
 local range=GameDefines.MIN_CITY_RANGE or 3
 for pid=0,GameDefines.MAX_MAJOR_CIVS-1 do local other=Players[pid]
  if other and other:IsAlive() then
   local start=other:GetStartingPlot()
   if pid~=s.pid and start and Map.PlotDistance(start:GetX(),start:GetY(),plot:GetX(),plot:GetY())<=range+3 then return false end
   for c in other:Cities() do if Map.PlotDistance(c:GetX(),c:GetY(),plot:GetX(),plot:GetY())<=range then return false end end
  end
 end
 return true
end
function I.Start(s)
 if s.startComplete or s.startBusy then return end
 local p=Players[s.pid];local cap=p:GetCapitalCity();if not cap then return end
 -- Existing saves receive politics, never a mid-campaign free empire.
 if not s.startBegun and cap:GetGameTurnFounded()<I.Now()-1 then s.startComplete=true;return end
 s.startBusy=true
 if not s.startBegun then
  s.startBegun=true;cap:SetPopulation(math.max(2,cap:GetPopulation()),true)
  I.History(s,'FOUNDING',I.Text('HISTORY_FOUNDING',cap:GetName()))
 end
 for slot=1,2 do if not s.entitlements[slot] then
  local choices={}
  I.Near(cap:GetX(),cap:GetY(),8,function(plot)
   if valid(s,plot) then
    local food=0;I.Near(plot:GetX(),plot:GetY(),1,function(adj) if not adj:IsWater() and not adj:IsMountain() then food=food+1 end;if adj:GetResourceType(p:GetTeam())>=0 then food=food+2 end end)
    choices[#choices+1]={plot=plot,score=food-Map.PlotDistance(cap:GetX(),cap:GetY(),plot:GetX(),plot:GetY())}
   end
  end)
  table.sort(choices,function(a,b) if a.score~=b.score then return a.score>b.score end;if a.plot:GetX()~=b.plot:GetX() then return a.plot:GetX()<b.plot:GetX() end;return a.plot:GetY()<b.plot:GetY() end)
  local c
  if choices[1] then
   local plot=choices[1].plot
   -- Found performs the normal founding pipeline; InitCity alone bypasses it.
   p:Found(plot:GetX(),plot:GetY());c=plot:GetPlotCity()
  end
  if c and c:GetOwner()==s.pid then
   c:SetName(I.Text(slot==1 and 'PROVINCE_I' or 'PROVINCE_II'));c:SetPopulation(1,true)
   s.entitlements[slot]={kind='city',key=I.CityKey(c)}
  else
   local u=p:InitUnit(I.ID('UNIT_SETTLER'),cap:GetX(),cap:GetY(),UnitAITypes.UNITAI_SETTLE)
   if u then u:JumpToNearestValidPlot();s.entitlements[slot]={kind='settler',unit=u:GetID(),birth=u:GetGameTurnCreated()} end
  end
 end end
 s.startBusy=nil;s.startComplete=s.entitlements[1]~=nil and s.entitlements[2]~=nil
end
