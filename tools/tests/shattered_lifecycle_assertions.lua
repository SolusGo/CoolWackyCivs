local I=MapModData.TheShatteredEmpire;local s=I.State(0);local p=Players[0]
assert(s.authority==82 and p:GetNumCities()==3 and p.cities[0].pop==2)
assert(#I.Provinces(s)==2 and s.startComplete)
local a,b=s.entitlements[1],s.entitlements[2];assert(a.kind=='city' and b.kind=='city' and a.key~=b.key)
local first=I.Provinces(s)[1];local name=first.name;local id=first.id
reload();I=MapModData.TheShatteredEmpire;s=I.State(0)
assert(p:GetNumCities()==3 and I.Provinces(s)[1].name==name and I.Provinces(s)[1].id==id)
I.Initialize(0);assert(p:GetNumCities()==3)
local g=I.Provinces(s)[1];local c=I.City(g,0)
c.b[GameInfoTypes.BUILDING_IMPERIAL_PALACE]=1;c.connected=true
local troop=p:InitUnit(GameInfoTypes.UNIT_IMPERIAL_LEGION,c.x,c.y,1)
local change,why=I.LoyaltyDelta(s,g);assert(change>=5 and change<=8 and #why>=3)
g.loyalty=75;g.ambition=95;g.prestige=100;I.LoyaltyTick(s);assert(not g.faction,'A powerful loyal Governor must stay useful')
local funds=p.gold;assert(I.Action(0,'BRIBE',g.key,g.id));assert(p.gold<funds)
local after=p.gold;assert(not I.Action(0,'BRIBE',g.key,g.id));assert(p.gold==after,'Duplicate click must not charge twice')
g.actionNext=0;local oldID=g.id;assert(I.Action(0,'REPLACE',g.key,oldID));g=s.governors[g.key]
assert(g.id~=oldID and not I.Action(0,'BRIBE',g.key,oldID),'Stale Governor buttons must fail')
assert(c.resistance==1)
for _=1,8 do I.NewDemand(s,g);assert(g.demand and g.demand.deadline>I.Now());I.FinishDemand(s,g,true) end
g.demand={kind='FARMS',target=2,created=I.Now(),deadline=I.Now()+I.Scale(20),cost=20}
local farm1=Map.GetPlot(g.x+1,g.y);farm1.owner=0;farm1.improvement=GameInfoTypes.IMPROVEMENT_FARM
local farm2=Map.GetPlot(g.x,g.y+1);farm2.owner=0;farm2.improvement=GameInfoTypes.IMPROVEMENT_FARM
assert(I.DemandComplete(s,g));I.FinishDemand(s,g,true)
g.demand={kind='FUNDS',created=I.Now(),deadline=I.Now()-1,cost=20};local before=g.loyalty;I.DemandTick(s);assert(not g.demand and g.loyalty<before)
I.UnitTick(s,false);local r=s.units[troop:GetID()];r.oath=22;local identity=r.id
local up=upgrade(troop:GetID(),700);assert(s.units[700].oath==22 and s.units[700].id==identity and not s.units[troop:GetID()])
assert(up:IsHasPromotion(GameInfoTypes.PROMOTION_IMPERIAL_DISCIPLINE))
I.Authority(s,-1000);assert(s.authority==0);I.Authority(s,1000);assert(s.authority==100)
I.UnitTick(s,false);assert(up:IsHasPromotion(GameInfoTypes.PROMOTION_IMPERIAL_DISCIPLINE_ACTIVE))
s.authority=59;I.UnitTick(s,false);assert(not up:IsHasPromotion(GameInfoTypes.PROMOTION_IMPERIAL_DISCIPLINE_ACTIVE))
local count=0;for _ in pairs(s.units) do count=count+1 end;up:Kill(false,-1);assert(not s.units[700])
local same=I.Encode(s);I.Turn(0);local once=I.Encode(s);I.Turn(0);assert(I.Encode(s)==once,'Duplicate PlayerDoTurn must be inert')
-- Turn/birth identity prevents recycled IDs from inheriting a previous soldier's oath.
Turn=Turn+1;local reused=newUnit(0,700);p.units[700]=reused;I.Track(s,reused);assert(s.units[700].id~=identity)
-- Capital loss and repeated conquest rewards.
local foreign=Players[2].cities[0];local x,y=foreign.x,foreign.y
Players[2].cities[0]=nil;foreign.owner=0;foreign.id=80;p.cities[80]=foreign
s.authority=50;GameEvents.CityCaptureComplete.Fire(2,false,x,y,0,1,true);assert(s.authority==54)
GameEvents.CityCaptureComplete.Fire(2,false,x,y,0,1,true);assert(s.authority==54)
GameEvents.CityCaptureComplete.Fire(0,true,x,y,2,1,true);assert(s.authority==34)
-- Destroyed cities stop supplying effects and Governors; no orphaned active province.
p.cities[c.id]=nil;I.Reconcile(s);assert(not s.governors[g.key].active)
-- Damage to the current bank recovers the previous complete snapshot.
I.Save(0);I.Save(0);local active=Saved.SHATTERED_V1_P0_active;Saved['SHATTERED_V1_P0_'..active..'_1']='damaged'
reload();I=MapModData.TheShatteredEmpire;s=I.State(0);assert(s.authority==34 and s.startComplete)
local ok=pcall(I.Decode,'m1000000:');assert(not ok,'Malformed snapshot must fail without executing code')
