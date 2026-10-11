-- Forced AI control tests gameplay independence; SQL keeps normal AI selection disabled.
local T=GameInfoTypes
local unlocked=0
LuaEvents.CR7ChapterUnlocked.Add(function()unlocked=unlocked+1 end)
for p=0,1 do
    NewCity(p,1,p*6,0,1):SetNumRealBuilding(T.BUILDING_CR7_SPORTING_ACADEMY,1)
    Players[p]:SetHasPolicy(T.POLICY_TRADITION,true)
end
for t=0,59 do
    CurrentTurn=t
    for p=0,1 do
        Players[p].era=t<10 and 0 or t<20 and 1 or t<30 and 3 or t<35 and 4 or t<40 and 5 or t<45 and 6 or 7
        GameEvents.PlayerDoTurn(p)
        for n=1,3 do
            local u=NewUnit(p,t*10+n,'UNIT_INFANTRY',p*6,0)
            GameEvents.CityTrained(p,1,u.id,false,false)
            Promote(u,T.PROMOTION_SHOCK_1)
            Promote(u,T.PROMOTION_SHOCK_2)
            Promote(u,T.PROMOTION_DRILL_1)
            Kill(u,NewUnit(1-p,10000+t*10+n,'UNIT_INFANTRY',(1-p)*6,1),true)
        end
    end
end
for p=0,1 do
    local s=MapModData.CR7.GetUIState(p)
    Equal(s.chapter,7,'forced AI earns chapters from real handler paths')
    assert(s.legacy>=1 and s.ambition>=275)
    Equal(Players[p].freePolicies,1)
    assert(Players[p].cities[1].production>=15 and Players[p].cities[1].culture>=10,'AI academy graduates reward their original city')
    for n=1,7 do assert(Players[p]:HasPolicy(T['POLICY_CR7_CHAPTER_'..n])) end
    assert(Players[p]:HasPolicy(T.POLICY_TRADITION),'ordinary policy remains adopted')
end
Equal(unlocked,0,'AI gameplay never needs a human popup')
local before={Ambition(0),Ambition(1),Players[0].freePolicies,Players[1].freePolicies}
MapModData.CR7=nil;ResetRuntimeEvents();assert(loadstring(RuntimeSource))()
for p=0,1 do
    GameEvents.PlayerDoTurn(p)
    Equal(Ambition(p),before[p+1]);Equal(Players[p].freePolicies,before[p+3])
end
print('PASS CR7 forced-AI simulation: two independent players, 60 turns, automatic chapters/legacy, normal policies, no popups and reload; AI selection remains disabled')
