local L=MapModData.TheLastCity
L.Caravans={
 {key='ASH',skill='ENGINEERS',population=2,cost=8,risk='INFILTRATION'},
 {key='OBSERVATORY',skill='SCIENTISTS',population=1,cost=6,risk='BRILLIANT'},
 {key='MERCY',skill='PHYSICIANS',population=2,cost=8,risk='MEDICAL'},
 {key='BROKEN_BANNER',skill='VETERANS',population=2,cost=10,risk='COMMANDER'},
 {key='SEED',skill='FARMERS',population=2,cost=8,risk='SUPPLIES'},
 {key='ARCHIVE',skill='SCHOLARS',population=1,cost=6,risk='LEADERSHIP'},
 {key='FEVER',skill='PHYSICIANS',population=3,cost=12,risk='DISEASE'},
 {key='SMUGGLERS',skill='ENGINEERS',population=1,cost=5,risk='SMUGGLING'},
 {key='HUNGRY',skill='FARMERS',population=3,cost=10,risk='THEFT'},
 {key='EXILES',skill='SCHOLARS',population=2,cost=8,risk='UNREST'},
 {key='CROWDED',skill='SCIENTISTS',population=3,cost=12,risk='OVERCROWDING'},
 {key='SILENT',skill='VETERANS',population=1,cost=6,risk='INFILTRATION'}}
function L.NewRefugee(s)
 -- A saved shuffled bag covers every narrative before repeating, including
 -- long Marathon games, without changing population/cost distributions.
 if not s.caravanBag or #s.caravanBag==0 then
  s.caravanBag={};for i=1,#L.Caravans do s.caravanBag[i]=i end
 end
 local index=L.Rand(s,#s.caravanBag);local template=L.Caravans[table.remove(s.caravanBag,index)]
 s.refugee={id=s.nextEvent,key=template.key,skill=template.skill,population=template.population,
  cost=L.Scale(template.cost),risk=template.risk,arrived=L.Now(),expiry=L.Now()+L.Scale(L.Config.RefugeeExpiry),
  status='GATES',survivors=L.Range(s,18,65),riskRoll=L.Rand(s,100)}
 s.nextEvent=s.nextEvent+1;L.History(s,'CARAVAN',L.Text('CARAVAN_'..template.key))
 L.Notify(s,'REFUGEES_WAITING',L.Text('CARAVAN_'..template.key))
end
function L.RefugeeCheck(s,id,choice)
 local r=s.refugee
 if not r or id~=r.id or L.Now()>r.expiry then return false,L.Text('EVENT_EXPIRED') end
 if r.status=='QUARANTINE' then return false,L.Text('QUARANTINE_WAIT',math.max(0,r.due-L.Now())) end
 if choice=='ACCEPT' then
  if s.provisions<r.cost-(r.paid or 0) then return false,L.Text('SUPPLIES_REQUIRED',r.cost-(r.paid or 0)) end
 elseif choice=='QUARANTINE' then
  if r.quarantined then return false,L.Text('ALREADY_QUARANTINED') end
  if s.provisions<math.ceil(r.cost/2) then return false,L.Text('SUPPLIES_REQUIRED',math.ceil(r.cost/2)) end
  local c=L.City(s)
  if c:GetPopulation()+r.population>L.Stats(s).housing+4 or not (L.Has(c,'DISTRICT') or L.Has(c,'BARRACKS')) then return false,L.Text('QUARANTINE_HOUSING') end
 elseif choice~='REFUSE' then return false,L.Text('UNAVAILABLE') end
 return true,L.Text('REFUGEE_'..choice,r.population,L.Text(r.skill),choice=='QUARANTINE' and math.ceil(r.cost/2) or r.cost-(r.paid or 0))
end
local function complication(s,r)
 local c=L.City(s);local pressure=math.min(15,math.max(0,c:GetPopulation()-L.Stats(s).housing)*3)
 local chance=math.max(4,25+pressure+math.min(8,s.refused)-L.Medical(s)*3)
 local positive=r.risk=='LEADERSHIP' or r.risk=='MEDICAL' or r.risk=='BRILLIANT' or r.risk=='COMMANDER' or r.risk=='SUPPLIES'
 if positive then chance=25
 elseif r.quarantined then chance=math.max(2,math.floor(chance/3)) end
 if r.riskRoll>chance then return end
 local risk=r.risk
 if risk=='DISEASE' then
  L.Provisions(s,-L.Scale(math.max(2,10-L.Medical(s))));L.Morale(s,-math.max(2,8-L.Medical(s)));s.medicalCases=s.medicalCases+1
  if L.Medical(s)<2 and c:GetPopulation()>1 then c:ChangePopulation(-1,true) end
 elseif risk=='SMUGGLING' then L.Provisions(s,L.Scale(8));L.Morale(s,-3)
 elseif risk=='INFILTRATION' then L.Provisions(s,-L.Scale(6));L.Morale(s,-6);s.infiltratedUntil=L.Now()+L.Scale(8)
 elseif risk=='OVERCROWDING' then L.Morale(s,-5)
 elseif risk=='UNREST' then L.Morale(s,-math.min(10,4+s.refused))
 elseif risk=='THEFT' then L.Provisions(s,-L.Scale(10))
 elseif risk=='LEADERSHIP' then L.Morale(s,10)
 elseif risk=='MEDICAL' then s.experts.PHYSICIANS=math.min(50,s.experts.PHYSICIANS+1);L.Morale(s,4)
 elseif risk=='BRILLIANT' then s.experts.SCIENTISTS=math.min(50,s.experts.SCIENTISTS+1)
 elseif risk=='COMMANDER' then s.experts.VETERANS=math.min(50,s.experts.VETERANS+1);L.Morale(s,6)
 elseif risk=='SUPPLIES' then L.Provisions(s,L.Scale(20)) end
 L.History(s,'COMPLICATION',L.Text('RISK_'..risk));L.Notify(s,'COMPLICATION',L.Text('RISK_'..risk))
end
function L.ResolveRefugee(s,id,choice)
 local ok,reason=L.RefugeeCheck(s,id,choice);if not ok then return false,reason end
 local r=s.refugee
 if choice=='QUARANTINE' then
  r.paid=math.ceil(r.cost/2);L.Provisions(s,-r.paid);r.status='QUARANTINE';r.quarantined=true
  r.due=L.Now()+L.Scale(L.Config.QuarantineTurns);r.expiry=r.due+L.Scale(L.Config.RefugeeExpiry)
  L.History(s,'QUARANTINED',L.Text('CARAVAN_'..r.key));return true,L.Text('QUARANTINED')
 end
 -- Consume the event before native callbacks can see it, preventing a repeated
 -- click/reentrant population callback from granting the same reward twice.
 s.refugee=nil
 if choice=='ACCEPT' then
  L.Provisions(s,-(r.cost-(r.paid or 0)));L.City(s):ChangePopulation(r.population,true)
  s.experts[r.skill]=math.min(50,s.experts[r.skill]+1)
  s.survivors[r.key]=(s.survivors[r.key] or 0)+1;s.accepted=s.accepted+1;L.Morale(s,3)
  L.History(s,'ACCEPTED',L.Text('CARAVAN_'..r.key));complication(s,r)
 else
  s.refused=s.refused+1;L.Morale(s,-10);L.History(s,'REFUSED',L.Text('CARAVAN_'..r.key))
 end
 s.nextRefugee=L.Now()+L.Scale(L.Range(s,L.Config.RefugeeMin,L.Config.RefugeeMax))
 return true,L.Text(choice=='ACCEPT' and 'ACCEPTED' or 'REFUSED')
end
function L.RefugeeTurn(s)
 if s.refugee then local r=s.refugee
  if r.status=='QUARANTINE' and L.Now()>=r.due then r.status='CLEARED';L.Notify(s,'QUARANTINE_CLEARED') end
  if L.Now()>r.expiry then
   s.refugee=nil;s.refused=s.refused+1;L.Morale(s,-5);L.History(s,'CARAVAN_LEFT',L.Text('CARAVAN_'..r.key))
   s.nextRefugee=L.Now()+L.Scale(L.Range(s,L.Config.RefugeeMin,L.Config.RefugeeMax))
  end
 elseif s.nextRefugee and L.Now()>=s.nextRefugee then L.NewRefugee(s) end
end
