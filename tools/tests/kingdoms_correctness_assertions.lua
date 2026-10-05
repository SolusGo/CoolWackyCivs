local K=MapModData.TheKingdoms
local s=K.State(0);local p=Players[0];local city=p.cities[0];local kingdom=s.kingdoms[K.CityKey(city)]
local h=s.houses[kingdom.houses[1]];local other=s.houses[kingdom.houses[2]]

-- Symmetric hostility costs two points per unique pair, including the Realm aggregate.
h.relations[other.id]=0;other.relations[h.id]=0;K.RefreshRealm(s)
local stable,realm=kingdom.stability,s.realm
K.Relation(s,h.id,other.id,-45);K.RefreshRealm(s)
assert(h.relations[other.id]==-45 and other.relations[h.id]==-45)
assert(kingdom.stability==stable-2 and s.realm==realm-2,'one hostile pair must count once')
h.relations[other.id]=0;other.relations[h.id]=0

-- Retain the documented NEW-Farms baseline: existing Farms do not fulfill a new demand.
local farm=GameInfoTypes.IMPROVEMENT_FARM
Map.GetPlot(1,0).improvement=farm;Map.GetPlot(0,1).improvement=farm
local demand=assert(K.MakeDemand(s,h,'FARMS'))
assert(demand.baseline==2 and demand.target==2 and K.DemandProgress(s,h,demand)==0)
assert(K.DemandText(s,demand):find('new Farms') and K.DemandText(s,demand):find('need not be worked'))
local x,y=Map.GetPlot(-1,0),Map.GetPlot(0,-1)
x.improvement=farm;assert(K.DemandProgress(s,h,demand)==1)
x.pillaged=true;assert(K.DemandProgress(s,h,demand)==0)
x.pillaged=false;y.improvement=farm
assert(K.DemandProgress(s,h,demand)==2,'unworked Farms count; there is no citizen-work check')

-- Appoint a Guard in the first faction and stage a genuine disputed succession.
local u=createGuard(10);local pending=assert(s.pending[10])
local cid=pending.candidates[1];assert(K.Appoint(0,10,cid))
local g=s.guards[cid];h=s.houses[g.house]
other=s.houses[kingdom.houses[1]==h.id and kingdom.houses[2] or kingdom.houses[1]]
s.previousHouse=s.characters[s.ruler].house;s.ruler=nil
K.BeginCivilWar(s,{{house=h.id},{house=other.id}})
assert(s.war and s.war.supported==nil,'new wars start Neutral')
assert(K.FactionFor(s,g.house).id==1)
h.loyalty=-50;g.oathNext=0;s.rng=1
local notices=p.notices;K.GuardTick(s)
assert(not g.oathPending and p.notices==notices,'Neutral is not opposition even with low loyalty and favorable RNG')
assert(not K.CanOath(0,cid,'KEEP'))
s.war.supported=999;g.oathPending=true;K.GuardTick(s)
assert(not g.oathPending,'an invalid faction is not a royal commitment');s.war.supported=nil

-- Nil survives both serialization and a fresh context; the war continues without default backing.
assert(K.Decode(K.Encode(s.war)).supported==nil)
local warNumber=s.war.number;K.Save(0);reload();K=MapModData.TheKingdoms;s=K.State(0);g=s.guards[cid];h=s.houses[g.house]
assert(s.war.number==warNumber and s.war.supported==nil and not g.oathPending)
K.CivilWarTick(s);assert(s.war and s.war.supported==nil)

-- Support faction 2 normally; loyalty and RNG still gate its rival Guard's oath.
local rivalLoyalty=h.loyalty;local backedLoyalty=s.houses[s.war.factions[2].house].loyalty
assert(K.Support(0,2,'FUND') and s.war.supported==2)
assert(h.loyalty==rivalLoyalty-4 and s.houses[s.war.factions[2].house].loyalty==backedLoyalty+4)
h.loyalty=30;g.oathNext=0;s.rng=1;K.GuardTick(s);assert(not g.oathPending,'loyal Guards do not face an oath')
h.loyalty=-50;g.oathNext=0;s.rng=2147483646;K.GuardTick(s);assert(not g.oathPending,'the original random gate remains')
g.oathNext=0;s.rng=1;K.GuardTick(s)
assert(g.oathPending and K.CanOath(0,cid,'KEEP'),'committed backing still permits rival Guard oaths')
assert(not K.Support(0,nil,'NEUTRAL') and s.war.supported==2,'Neutral respects the existing action cooldown')

-- Neutral clears support without costs, House effects, faction strength or membership changes.
Turn=s.war.actionNext
local political={}
for id,house in pairs(s.houses) do political[id]=K.Encode({loyalty=house.loyalty,influence=house.influence,prestige=house.prestige,claimBonus=house.claimBonus,relations=house.relations}) end
local coalitions={};for id,f in ipairs(s.war.factions) do coalitions[id]=K.Encode({strength=f.strength,members=f.members}) end
local gold=p.gold;local supplies=s.suppliesUntil;local estates=kingdom.estatesUntil
assert(K.Support(0,nil,'NEUTRAL') and s.war.supported==nil)
assert(p.gold==gold and s.suppliesUntil==supplies and s.kingdoms[kingdom.id].estatesUntil==estates)
for id,house in pairs(s.houses) do assert(political[id]==K.Encode({loyalty=house.loyalty,influence=house.influence,prestige=house.prestige,claimBonus=house.claimBonus,relations=house.relations}),'Neutral must not change House politics') end
for id,f in ipairs(s.war.factions) do assert(coalitions[id]==K.Encode({strength=f.strength,members=f.members})) end
assert(not g.oathPending and not K.CanOath(0,cid,'KEEP'),'withdrawn backing clears obsolete oath prompts')
assert(s.history[#s.history].key=='WAR_NEUTRAL','the Chronicle must not imply faction allegiance')
assert(not K.Support(0,2,'FUND'),'Neutral also starts the normal cooldown')
K.Save(0);reload();K=MapModData.TheKingdoms;s=K.State(0);g=s.guards[cid];h=s.houses[g.house]
assert(s.war and s.war.supported==nil and not g.oathPending)
K.CivilWarTick(s);assert(s.war and s.war.supported==nil)

-- Old saves with explicit faction backing keep it; aligned Guards are not rivals.
Turn=s.war.actionNext;assert(K.Support(0,2,'FUND'))
g.oathNext=Turn+K.Scale(100);K.Save(0);reload();K=MapModData.TheKingdoms;s=K.State(0);g=s.guards[cid]
assert(s.war and s.war.supported==2,'loading an existing commitment must not reset it')
Turn=s.war.actionNext;assert(K.Support(0,1,'FUND'))
s.houses[g.house].loyalty=-50;g.oathNext=0;s.rng=1;notices=p.notices;K.GuardTick(s)
assert(not g.oathPending and p.notices==notices,'Guards in the backed faction do not oppose the Crown')
