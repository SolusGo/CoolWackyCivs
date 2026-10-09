local I=MapModData.TheShatteredEmpire;local s=I.State(0);local p=Players[0]
assert(not I.Action(0,'REFORM','FEDERATION'),'Ancient reforms must remain locked')
p.era=1;s.authority=90;assert(I.Action(0,'REFORM','FEDERATION'));assert(s.reform=='FEDERATION' and s.authority==80)
assert(not I.Action(0,'REFORM','MONARCHY'),'Reform cooldown')
local g=I.Provinces(s)[1];g.autonomy=true;I.ApplyEffects(s)
assert(I.City(g,0):IsHasBuilding(GameInfoTypes.BUILDING_IMPERIAL_FEDERATION))
Turn=s.reformNext;assert(I.Action(0,'REFORM','MONARCHY'))
assert(not I.City(g,0):IsHasBuilding(GameInfoTypes.BUILDING_IMPERIAL_FEDERATION))
assert(p.cities[0]:IsHasBuilding(GameInfoTypes.BUILDING_IMPERIAL_MONARCHY))
I.ApplyEffects(s);I.ApplyEffects(s);assert(p.cities[0]:GetNumRealBuilding(GameInfoTypes.BUILDING_IMPERIAL_MONARCHY)==1)
Turn=s.reformNext;s.authority=90;local unit=p.units[0];local record=s.units[0];record.oath=65
assert(I.Action(0,'REFORM','DICTATORSHIP'));assert(record.oath==65 and I.Oath(s,record,unit)==80)
Turn=s.reformNext;assert(I.Action(0,'REFORM','MONARCHY'));assert(record.oath==65 and I.Oath(s,record,unit)==65,'Reforms cannot permanently stack Oaths')
-- Succession candidates, dates and choices survive a fresh Lua context.
s.authority=90;Turn=s.successionNext;I.SuccessionTick(s);assert(s.succession)
local name=s.succession.candidates.BLOOD.name;local pending=s.succession.id;I.Save(0);reload();I=MapModData.TheShatteredEmpire;s=I.State(0)
assert(s.succession.candidates.BLOOD.name==name and s.succession.id==pending)
assert(I.Action(0,'SUCCESSION','BLOOD',pending));assert(I.Reign(s).name==name and #s.dynasty==2 and not s.succession)
assert(not I.Action(0,'SUCCESSION','STEEL',pending),'Succession is resolved exactly once')
I.SuccessionTick(s);assert(not s.succession,'Era must not repeat succession')
-- Restoration takes the full scaled duration, then effects can become dormant and reactivate.
s.authority=82;s.collapseSeen=true;s.collapseResolved=true
for _,province in ipairs(I.Provinces(s)) do province.loyalty=90 end
I.RestorationTick(s);local start=s.restorationSince;Turn=start+I.Scale(20)-1;I.RestorationTick(s);assert(not s.restored)
Turn=Turn+1;I.RestorationTick(s);I.ApplyEffects(s);assert(s.restored and s.restorationActive)
for c in p:Cities() do assert(c:GetNumRealBuilding(GameInfoTypes.BUILDING_IMPERIAL_RESTORATION)==1) end
s.authority=30;I.RestorationTick(s);I.ApplyEffects(s);assert(not s.restorationActive)
for c in p:Cities() do assert(c:GetNumRealBuilding(GameInfoTypes.BUILDING_IMPERIAL_RESTORATION)==0) end
s.authority=85;I.RestorationTick(s);I.ApplyEffects(s);assert(s.restorationActive)
for n=1,400 do I.History(s,'TEST','Record '..n) end;assert(#s.history==300)
I.Save(0);reload();I=MapModData.TheShatteredEmpire;s=I.State(0);assert(s.restored and #s.history==300)
-- AI shares human costs and crisis rules, while resolving mandatory decisions autonomously.
local ai=I.State(1);Players[1].era=1;ai.authority=90;I.AITick(ai);assert(ai.reform=='MONARCHY')
local province=I.Provinces(ai)[1];province.loyalty=30;province.ambition=95;province.actionNext=0
local old=province.id;I.AITick(ai);assert(ai.governors[province.key].id~=old and ai.authority<90)
Turn=ai.successionNext;I.SuccessionTick(ai);I.AITick(ai);assert(not ai.succession and #ai.dynasty==2)
