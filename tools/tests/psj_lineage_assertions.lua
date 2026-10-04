-- Use only production event callbacks, preserving units/save values on reload.
local function reload()
    __PSJ_RUNTIME_LOADED=nil
    resetEvents()
    assert(loadstring(PSJRuntimeSource))()
end
local function data(u)
    local values={}
    local raw=u.script:match('%[PSJ1:([^%]]*)%]')
    if raw then for v in raw:gmatch('[^,]+') do values[#values+1]=tonumber(v) end end
    return values
end
local function stripped(u)
    assert(not u.script:find('%[PSJ1:'),'transferred Survivor regained identity')
    assert(not u:IsHasPromotion(400) and not u:IsHasPromotion(401),'transferred Survivor regained promotions')
    assert(u.script=='[OTHER:keep]','transfer modified unrelated ScriptData')
end
newCity(P,0,0);newCity(AI,20,0)
GameEvents.PlayerCityFounded.Fire(2,0,0);GameEvents.PlayerCityFounded.Fire(1,20,0)
local old=newUnit(P,101,200)
GameEvents.UnitCreated.Fire(2,101,200,0,0)
assert(data(old)[3]==1 and old:IsHasPromotion(400),'native Ancient Survivor did not initialize')
old:SetHasPromotion(401,true) -- Ensure even an existing veteran is stripped.
local transferred=newUnit(AI,102,200)
-- Native creation is before conversion; the copied old lineage must be erased.
GameEvents.UnitCreated.Fire(1,102,200,0,0)
transferred:SetHasPromotion(401,true) -- Native conversion copies veteran before the hook.
GameEvents.UnitConverted.Fire(2,1,101,102,false)
P.units={};stripped(transferred)
local native=newUnit(P,103,200)
GameEvents.UnitCreated.Fire(2,103,200,0,0)
local serial=data(native)[1]
local bootstrap=newUnit(P,104,200) -- Valid starting unit missing its creation event.
reload()
stripped(transferred)
assert(data(native)[1]==serial and data(native)[3]==1 and native:IsHasPromotion(400),'native lineage lost on reload')
assert(data(bootstrap)[1] and data(bootstrap)[3]==1 and bootstrap:IsHasPromotion(400),'valid native load-time bootstrap failed')
-- All identify callers must respect the stripped promotion, not just initialize.
GameEvents.UnitCreated.Fire(1,102,200,0,0)
GameEvents.UnitSetXY.Fire(1,102,0,0)
GameEvents.GoodyHutReceivedBonus.Fire(1,102,1,0,0)
T=1;GameEvents.PlayerDoTurn.Fire(1)
stripped(transferred)
AI.era=5;GameEvents.TeamSetEra.Fire(1,5,false)
stripped(transferred)
local descendant=newUnit(AI,105,201)
descendant.promotions={};descendant.script=transferred.script
GameEvents.UnitCreated.Fire(1,105,201,0,0)
GameEvents.UnitUpgraded.Fire(1,102,105,false)
GameEvents.UnitConverted.Fire(1,1,102,105,true)
AI.units={descendant};stripped(descendant)
reload();T=2;GameEvents.PlayerDoTurn.Fire(1);stripped(descendant)
-- An old buggy save may already contain an orphan marker without Learning.
-- Neither snapshot nor conversion may turn it back into a valid lineage.
local orphan=newUnit(AI,109,200)
orphan.promotions={};orphan.script='[OTHER:keep][PSJ1:9999,1,1,0,-1,0,1]'
local orphanUpgrade=newUnit(AI,110,201);orphanUpgrade.promotions={}
GameEvents.UnitUpgraded.Fire(1,109,110,false)
GameEvents.UnitConverted.Fire(1,1,109,110,true)
stripped(orphanUpgrade)
AI.units={descendant,orphanUpgrade}
print('PASS PSJ transfer reload: real Survivor stays stripped through callers, Modern and later upgrade; native reload remains valid')

local field=plot(1,0,-1);native.x=1
local function visit(area,u)
    field.area=area;u=u or native;u.x=1
    GameEvents.UnitSetXY.Fire(2,u.id,1,0)
end
visit(1);assert(native.xp==0)
visit(2);assert(native.xp==10)
visit(1);visit(2);assert(native.xp==10,'landmass revisit granted XP')
visit(3);assert(native.xp==20)
visit(4);assert(native.xp==30)
visit(5);visit(6);visit(2);visit(3);visit(4)
assert(native.xp==30 and data(native)[8]==3,'first-three foreign landmass cap failed')
-- Exercise real Returning Home state before an ordinary same-owner upgrade.
local away=plot(10,0,-1);away.area=6;native.x=10
for t=3,12 do T=t;GameEvents.PlayerDoTurn.Fire(2) end
native.x=0;T=13;GameEvents.PlayerDoTurn.Fire(2)
assert(data(native)[6]==1,'fixture did not complete Returning Home')
local before=data(native)
local upgrade=newUnit(P,106,201);upgrade.xp=native.xp
GameEvents.UnitCreated.Fire(2,106,201,0,0)
GameEvents.UnitUpgraded.Fire(2,103,106,false)
GameEvents.UnitConverted.Fire(2,2,103,106,true)
P.units={bootstrap,upgrade}
local after=data(upgrade)
for _,i in ipairs({1,2,3,4,5,6,7,8}) do assert(after[i]==before[i],'same-owner upgrade lost history field '..i) end
assert(upgrade:IsHasPromotion(400),'same-owner upgrade lost Learning')
local xp=upgrade.xp
visit(2,upgrade);visit(3,upgrade);visit(4,upgrade);visit(5,upgrade);visit(6,upgrade)
assert(upgrade.xp==xp and data(upgrade)[8]==3,'upgrade reset landmass cap')
reload()
assert(data(upgrade)[1]==serial and data(upgrade)[3]==1 and data(upgrade)[6]==1 and data(upgrade)[8]==3,'reload lost upgraded state')
visit(5,upgrade);visit(6,upgrade);visit(2,upgrade)
assert(upgrade.xp==xp,'reload reset landmass cap')
P.era=5;GameEvents.TeamSetEra.Fire(2,5,false)
assert(upgrade:IsHasPromotion(401),'legitimate Ancient upgrade lost Modern veteran qualification')
print('PASS PSJ capped landmass XP: A/B/C +10 each, D/E/revisits +0; return/Ancient/count persist through upgrade and reload')

-- Existing seven-field records retain their saved per-area visits. Migration
-- shares the normal initialization map pass, without awarding retroactive XP.
local legacyFull=newUnit(P,107,200)
legacyFull.script='[OTHER:keep][PSJ1:9000,2,1,7,99,1,1]'
local legacyPartial=newUnit(P,108,200)
legacyPartial.script='[OTHER:keep][PSJ1:9001,2,1,0,-1,0,1]'
for _,area in ipairs({2,3,4,5}) do Saved['PSJ_V1_U9000_AREA_'..area]=1 end
for _,area in ipairs({2,3}) do Saved['PSJ_V1_U9001_AREA_'..area]=1 end
local scan={}
for area=1,6 do local p=plot(30+area,0,-1);p.area=area;scan[#scan+1]=p end
local water=plot(40,0,-1);water.area=7;water.water=true;scan[#scan+1]=water
Map.GetNumPlots=function() return #scan end
Map.GetPlotByIndex=function(i) return scan[i+1] end
reload()
assert(data(legacyFull)[1]==9000 and data(legacyFull)[3]==1 and data(legacyFull)[4]==7 and data(legacyFull)[6]==1
    and data(legacyFull)[8]==3 and legacyFull.xp==0,'legacy saturated history migration failed')
assert(data(legacyPartial)[8]==2,'legacy partial count was not recovered')
visit(5,legacyFull);visit(6,legacyFull);assert(legacyFull.xp==0,'legacy lineage exceeded lifetime cap')
visit(2,legacyPartial);visit(3,legacyPartial);assert(legacyPartial.xp==0,'legacy revisits awarded XP')
visit(4,legacyPartial);assert(legacyPartial.xp==10 and data(legacyPartial)[8]==3)
visit(5,legacyPartial);visit(6,legacyPartial);assert(legacyPartial.xp==10)
assert(legacyFull.script:find('%[OTHER:keep%]') and legacyPartial.script:find('%[OTHER:keep%]'),'migration lost unrelated ScriptData')
reload();visit(6,legacyPartial);assert(legacyPartial.xp==10 and data(legacyPartial)[8]==3,'legacy cap lost on second reload')
print('PASS PSJ legacy seven-field migration: old visits count toward lifetime cap; other state preserved; no duplicate XP')
