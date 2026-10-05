local K=MapModData.TheKingdoms
local s=K.State(0);local p=Players[0];local city=p.cities[0];local key=K.CityKey(city);local kingdom=s.kingdoms[key]
assert(#kingdom.houses==2 and s.ruler and #s.history>=4)
assert(K.State(1).ruler and Players[1].notices==0,'AI must initialize without human notifications')
local h=s.houses[kingdom.houses[1]];local originalTrait=h.traits[1]
local sample={n=12,b=true,f=false,s='n;m|a\0b:!',nested={[7]='seven',name='a\n\"b'}}
local decoded=K.Decode(K.Encode(sample));assert(decoded.n==12 and decoded.b and not decoded.f and decoded.nested[7]=='seven' and decoded.s==sample.s)
local history=#s.history;K.Save(0);reload();K=MapModData.TheKingdoms;s=K.State(0);kingdom=s.kingdoms[key];h=s.houses[h.id]
assert(#s.history==history and h.traits[1]==originalTrait and #kingdom.houses==2)
-- Population jumps queue one formation at a time, across repeated turns/reloads.
city.pop=19;Turn=K.Scale(10);K.Turn(0);s=K.State(0);kingdom=s.kingdoms[key]
assert(#kingdom.houses==3)
K.Turn(0);assert(#kingdom.houses==3,'same-turn callbacks must be idempotent')
for i=1,K.Scale(70) do nextTurn() end
assert(#kingdom.houses>=7 and #kingdom.houses<=8)
local parent=s.houses[kingdom.houses[1]];local child=K.NewHouse(s,kingdom,parent)
assert(child.parent==parent.id and child.founder and parent.children[#parent.children]==child.id)
assert(child.name~=parent.name and child.relations[parent.id]==-45 and child.traits[1]~=child.traits[2])
local names={};for _,house in pairs(s.houses) do assert(not names[house.name]);names[house.name]=true end
local fake={houses={},nextHouse=999,rng=713};for i,name in ipairs(K.HouseNames) do fake.houses[i]={name=name} end
assert(K.HouseName(fake):find('999'),'exhausted name pools must terminate')
local total=0;for _,house in ipairs(K.ActiveHouses(s,key)) do total=total+K.Influence(s,house) end;assert(math.abs(total-100)<0.001)
-- Valid demands observe actual improvement changes. Invalid targets cancel without punishment.
h=s.houses[kingdom.houses[1]];local demand=assert(K.MakeDemand(s,h,'FARMS'));h.demand=demand
local x=Map.GetPlot(1,0);local y=Map.GetPlot(0,1);x.improvement=GameInfoTypes.IMPROVEMENT_FARM;y.improvement=GameInfoTypes.IMPROVEMENT_FARM
K.DemandTick(s);assert(not h.demand and h.stats.completed>=1 and #h.completed>=1)
h.demand=assert(K.MakeDemand(s,h,'LIBRARY'));city.blockConstruction=true;local loyalty=h.loyalty;K.DemandTick(s);assert(not h.demand and h.loyalty==loyalty);city.blockConstruction=false
h.demand={kind='GOLD',target=999999,expires=Turn-1,issued=Turn,baseline=0};K.DemandTick(s);assert(not h.demand and h.loyalty<loyalty)
h.demand=assert(K.MakeDemand(s,h,'GROW'));local before=h.loyalty;assert(K.Refuse(0,h.id));assert(h.loyalty<=before-22 or h.loyalty==-100)
local gold=p.gold;h.actionNext=0;assert(K.Appease(0,h.id,'GIFT'));assert(p.gold<gold and not K.Appease(0,h.id,'GIFT'))
h.actionNext=0;assert(K.Appease(0,h.id,'ESTATES'));assert(kingdom.estatesUntil>Turn and city:GetNumBuilding(GameInfoTypes.BUILDING_KINGDOMS_ESTATES)==1)
h.actionNext=0;local claim=h.claimBonus;assert(K.Appease(0,h.id,'CHARTER'));assert(h.claimBonus==claim+8)
for _,house in ipairs(K.ActiveHouses(s,key)) do house.loyalty=0 end
city.b[GameInfoTypes.BUILDING_KINGDOMS_WALL]=0;K.RefreshRealm(s);local stability=kingdom.stability
city.b[GameInfoTypes.BUILDING_KINGDOMS_WALL]=1;K.RefreshRealm(s);assert(kingdom.stability==stability+5)
-- Peaceful death/succession then disputed succession with real penalties and player consequences.
if s.war then K.EndCivilWar(s,s.war.factions[1]) end
local ruler=s.characters[s.ruler];ruler.reignEnd=Turn;s.realm=80;K.RulerTick(s)
assert(not ruler.alive and s.ruler~=ruler.id and not s.war)
local claims=K.Claims(s);local sum=0;for _,c in ipairs(claims) do sum=sum+c.percent end;assert(math.abs(sum-100)<0.001)
ruler=s.characters[s.ruler];ruler.reignEnd=Turn;s.realm=30;K.RulerTick(s)
assert(s.war and not s.ruler and #s.war.factions>=2 and s.war.supported==nil);K.RefreshRealm(s)
assert(city:GetNumBuilding(GameInfoTypes.BUILDING_KINGDOMS_CIVILWAR)==1)
assert(p.units[0]:IsHasPromotion(GameInfoTypes.PROMOTION_KINGDOMS_CIVILWAR))
local other=s.war.factions[2];local opposite=s.houses[other.members[1]].loyalty
assert(K.Support(0,1,'FUND') and s.war.supported==1);assert(s.houses[other.members[1]].loyalty<=opposite)
assert(not K.Support(0,1,'FUND'),'support cooldown')
local pendingWar=s.war.number;K.Save(0);reload();K=MapModData.TheKingdoms;s=K.State(0);kingdom=s.kingdoms[key];h=s.houses[h.id]
assert(s.war.number==pendingWar and city:GetNumBuilding(GameInfoTypes.BUILDING_KINGDOMS_CIVILWAR)==1)
for i=1,K.Scale(25) do nextTurn() end
assert(not s.war and s.ruler)
assert(city:GetNumBuilding(GameInfoTypes.BUILDING_KINGDOMS_CIVILWAR)==0 and city:GetNumBuilding(GameInfoTypes.BUILDING_KINGDOMS_RIOT)==0)
assert(not p.units[0]:IsHasPromotion(GameInfoTypes.PROMOTION_KINGDOMS_CIVILWAR))
assert(#s.warHistory>=1 and s.warHistory[#s.warHistory].winner)
-- Seven living identities, three-house candidate choices, queued completion cap, upgrades, saves, deaths.
for uid=10,16 do
 local u=createGuard(uid);local entry=assert(s.pending[uid]);assert(#entry.candidates==3)
 local used={};for _,cid in ipairs(entry.candidates) do local c=s.characters[cid];assert(not used[c.house]);used[c.house]=true end
 if uid==10 then K.Save(0);reload();K=MapModData.TheKingdoms;s=K.State(0);entry=assert(s.pending[uid]) end
 assert(K.Appoint(0,uid,entry.candidates[1]));assert(u.name and u.script:find('KINGDOMS_GUARD'))
end
assert(K.GuardCount(s)==7 and not GameEvents.PlayerCanTrain.Fire(0,GameInfoTypes.UNIT_KINGDOMS_GUARD))
local refundGold=p.gold;createGuard(17);assert(not p.units[17] and K.GuardCount(s)==7 and p.gold>refundGold)
local guard=K.GuardOf(s,p.units[10]);local cid=guard.character;local affiliation=guard.house
local upgraded=upgradeGuard(10,30);assert(guard.unit==30 and guard.alive and K.GuardCount(s)==7)
assert(upgraded:IsHasPromotion(GameInfoTypes['PROMOTION_KINGDOMS_'..guard.trait:upper()]))
K.Save(0);reload();K=MapModData.TheKingdoms;s=K.State(0);guard=s.guards[cid]
assert(guard.alive and guard.house==affiliation and guard.unit==30 and K.GuardCount(s)==7)
local fallback=K.GuardOf(s,p.units[12]);local upgradedWithoutHook=upgradeGuard(12,31,false)
K.GuardTick(s);assert(fallback.alive and fallback.unit==31 and upgradedWithoutHook.script:find('KINGDOMS_GUARD') and K.GuardCount(s)==7)
-- Oath decisions preserve player ownership even on failure; voluntary return frees a slot.
K.BeginCivilWar(s);s.war.supported=K.FactionFor(s,guard.house).id==1 and 2 or 1
guard.oathPending=true;assert(K.Oath(0,cid,'OATH'));assert(p.units[30] and guard.alive and not guard.oathPending)
guard.oathPending=true;s.rng=2147483646;p.units[30].damage=90
assert(K.Oath(0,cid,'OATH'));assert(p.units[30].damage==90 and p.units[30].moves==0 and guard.alive,'failed oaths must neither heal nor kill wounded Guards')
guard.oathPending=true;p.gold=1000;assert(K.Oath(0,cid,'KEEP'));assert(guard.alive)
guard.oathPending=true;assert(K.Oath(0,cid,'RETURN'));assert(not p.units[30] and K.GuardCount(s)==6)
assert(GameEvents.PlayerCanTrain.Fire(0,GameInfoTypes.UNIT_KINGDOMS_GUARD))
local dead=K.GuardOf(s,p.units[11]);p.units[11]:Kill(false,2);assert(not dead.alive and K.GuardCount(s)==5)
createGuard(40);local pending=s.pending[40];upgradeGuard(40,41,false);K.GuardTick(s)
assert(not s.pending[40] and s.pending[41]==pending and K.GuardCount(s)==6)
K.Save(0);reload();K=MapModData.TheKingdoms;s=K.State(0);assert(s.pending[41] and K.Appoint(0,41,s.pending[41].candidates[1]))
-- AI appointments happen without candidate UI and no human notifications.
local aiGuard=createGuard(50,1);local ai=K.State(1);assert(not ai.pending[50] and K.GuardOf(ai,aiGuard) and Players[1].notices==0)
K.EndCivilWar(s,s.war.factions[1]);K.RefreshRealm(s)
-- Capital capture disables Houses, strips dummies, retains lineage, and restoration reverses the temporary shock.
local storedHouse=s.houses[kingdom.houses[1]];local savedPrestige=storedHouse.prestige
p.cities[0]=nil;Players[2].cities[10]=city;city.owner=2;city.id=10
GameEvents.CityCaptureComplete.Fire(0,true,city.x,city.y,2,city.pop,true)
assert(not s.kingdoms[key].active and s.capitalLost and s.houses[storedHouse.id]==storedHouse)
for _,typ in ipairs(K.Dummies) do assert(city:GetNumBuilding(GameInfoTypes[typ])==0,'foreign city retains dummy '..typ) end
K.Save(0);reload();K=MapModData.TheKingdoms;s=K.State(0);assert(not s.kingdoms[key].active and s.capitalLost)
Players[2].cities[10]=nil;p.cities[0]=city;city.owner=0;city.id=0
GameEvents.CityCaptureComplete.Fire(2,true,city.x,city.y,0,city.pop,true)
assert(s.kingdoms[key].active and not s.capitalLost and s.houses[storedHouse.id].traits[1]==storedHouse.traits[1])
local old=s.kingdoms[key];p.cities[0]=nil;K.ReconcileKingdoms(s);assert(old.razed and not old.active)
Turn=Turn+1;local replacement=newCity(0,0,city.x,city.y);p.cities[0]=replacement;K.ReconcileKingdoms(s)
assert(K.CityKey(replacement)~=key and not old.active and #s.kingdoms[K.CityKey(replacement)].houses==2)
-- Versioned snapshots recover the previous valid bank rather than executing damaged data.
K.Save(0);local prefix='KINGDOMS_V1_P0_';local active=Saved[prefix..'active'];Saved[prefix..active..'_1']='corrupt'
reload();K=MapModData.TheKingdoms;assert(K.State(0).version==1 and K.State(0).nextHouse>2)
