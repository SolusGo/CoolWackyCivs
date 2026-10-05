local K=MapModData.TheKingdoms
local s=K.State(0);local p=Players[0]
local u=createGuard(10);assert(K.Appoint(0,10,s.pending[10].candidates[1]))
local g=K.GuardOf(s,u);local cid=g.character
local function combat(ap,au,ad,af,am,dp,du,dd,df,dm)
 -- Include the complete CP v151 payload, including ignored interceptor/plot arguments.
 GameEvents.CombatEnded.Fire(ap,au,ad,af,am,dp,du,dd,df,dm,-1,-1,0,0,0)
end
local function check(battles,kills)
 assert(g.battles==battles and g.kills==kills,'CombatEnded statistics or argument ordering are incorrect')
 assert(s.characters[cid].stats.battles==battles and s.characters[cid].stats.kills==kills)
end

-- Inflicted damage is not final damage; each side has its own maximum HP.
combat(0,10,180,10,100,2,21,5,50,200);check(1,0)
Players[2].units[21]=newUnit(2,21);Players[2].units[21]:Kill(false,0)
local prestige=s.houses[g.house].prestige
combat(0,10,80,20,100,2,21,12,150,150);check(2,1)
assert(s.houses[g.house].prestige==prestige+1,'a Guard kill still grants its House Prestige')
-- A dead attacker is credited to a defending Guard despite postcombat unit lookup failure.
Players[2].units[22]=newUnit(2,22);Players[2].units[22]:Kill(false,0)
combat(2,22,10,125,125,0,10,125,70,150);check(3,2)

-- City combat participates in battles without inventing a unit kill for unit ID -1.
combat(0,10,200,20,100,2,-1,20,250,200);check(4,2)
combat(2,-1,70,125,100,0,10,0,70,100);check(5,2)
combat(-1,22,70,125,100,0,10,0,70,100);check(6,2)
combat(998,22,70,125,100,0,10,0,70,100);check(7,2)
combat(0,10,10,10,100,2,23,0,0,0);check(8,2)
combat(0,10,10,10,100,2,23,0,nil,100);check(9,2)

-- Invalid/absent IDs on the Guard side never reach native unit lookup or saved identity matching.
combat(-1,10,0,0,100,2,23,0,0,100)
combat(998,10,0,0,100,2,23,0,0,100)
combat(0,-1,0,0,100,2,23,0,0,100)
combat(0,nil,0,0,100,2,23,0,0,100)
combat(2,23,0,0,100,0,-1,0,0,100)
combat(2,23,0,0,100,0,nil,0,0,100)
combat(0,999,0,0,100,2,23,0,0,100);check(9,2)

-- UnitPrekill may precede CombatEnded: final statistics still attach to the dead identity.
u:Kill(false,2);assert(not g.alive and g.died==Turn and not p.units[10])
combat(0,10,30,100,100,2,23,100,30,100);check(10,2)
-- Recycled IDs must not assign a new unit's battle to an old Guard with a different birth turn.
Turn=Turn+1;p.units[10]=newUnit(0,10);g.died=Turn
combat(0,10,100,10,100,2,23,0,100,100);check(10,2)
g.died=Turn-1;p.units[10]=nil
combat(0,10,100,10,100,2,23,0,100,100);check(10,2)

-- The same saved-record fallback works for a killed defender after a fresh-context load.
local defender=createGuard(20);assert(K.Appoint(0,20,s.pending[20].candidates[1]))
local dead=K.GuardOf(s,defender);local deadID=dead.character
defender:Kill(false,2);K.Save(0);reload();K=MapModData.TheKingdoms;s=K.State(0);dead=s.guards[deadID]
assert(not dead.alive and dead.died==Turn and not p.units[20])
combat(2,29,100,30,100,0,20,30,100,100)
assert(dead.battles==1 and dead.kills==0 and s.characters[deadID].stats.battles==1)
local foreign=newUnit(2,20);Players[2].units[20]=foreign
combat(2,20,0,0,100,2,29,0,100,100)
assert(dead.battles==1,'foreign players cannot match a saved Guard identity')
