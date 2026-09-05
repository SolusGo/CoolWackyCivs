-- Rou'ls active abilities and spatial auras. Gameplay never runs from a UI refresh.
local R = MapModData.Rouls
if not R or R.actionsLoaded then return end
R.actionsLoaded = true
local G = GameInfoTypes
local LAND, SEA = G.DOMAIN_LAND, G.DOMAIN_SEA
local busy = false
local positions, excluded = {}, {}
local function key(u) return u:GetOwner() .. ":" .. u:GetID() end
local function alive(u)
    return u and not u:IsDead() and not u:IsDelayedDeath() and u:GetPlot() ~= nil
end
local function distance(a,b) return Map.PlotDistance(a:GetX(),a:GetY(),b:GetX(),b:GetY()) end
local function eachNear(plot, radius, fn)
    local seen = {}
    for dx = -radius, radius do for dy = -radius, radius do
        local p = Map.PlotXYWithRangeCheck(plot:GetX(),plot:GetY(),dx,dy,radius)
        if p and not seen[p:GetPlotIndex()] then
            seen[p:GetPlotIndex()] = true
            for i=0,p:GetNumUnits()-1 do local u=p:GetUnit(i); if alive(u) and not excluded[key(u)] then fn(u) end end
        end
    end end
end
local function team(u) return Players[u:GetOwner()]:GetTeam() end
local function enemy(a,b) return Teams[a]:IsAtWar(b) end
local function multiplayer() return Game.IsNetworkMultiPlayer and Game.IsNetworkMultiPlayer() end
local function activeTurn(id)
    local p=Players[id]
    return p and p:IsAlive() and p:IsTurnActive() and not multiplayer()
end
local function forbiddenWeapon(info)
    return not info or (tonumber(info.NukeDamageLevel) or -1) >= 0
        or info.Special == "SPECIALUNIT_MISSILE" or (tonumber(info.Suicide) or 0) == 1
end
local function hasCargo(u) return u:GetCargo() > 0 or u:IsCargo() end
function R.SwapEligible(id,u)
    if not alive(u) or u:GetOwner()~=id or not R.IsMilitary(u) then return false,"Choose a living Rou'ls military unit." end
    if R.IsLocked(u) then return false,"This consciousness is still settling until your next turn." end
    if u:IsEmbarked() or (u:GetDomainType()~=LAND and u:GetDomainType()~=SEA) then return false,"Only unembarked land or naval units may exchange." end
    if u:IsInCombat() or hasCargo(u) or forbiddenWeapon(GameInfo.Units[u:GetUnitType()]) then return false,"Units in combat, cargo carriers, missiles and nuclear weapons cannot exchange." end
    local p=u:GetPlot(); local owner=p:GetOwner()
    if owner>=0 and enemy(Players[id]:GetTeam(),Players[owner]:GetTeam()) then return false,"A unit is inside enemy territory." end
    for i=0,p:GetNumUnits()-1 do
        local other=p:GetUnit(i)
        if other and enemy(Players[id]:GetTeam(),team(other)) then return false,"A tile contains an enemy unit." end
    end
    return true
end
function R.SwapCost(id,a,b)
    local discounted=false
    for _,u in ipairs({a,b}) do
        if alive(u) then eachNear(u:GetPlot(),2,function(v)
            if v:GetOwner()==id and v:GetUnitType()==G.UNIT_ROULS_MATRIARCH then discounted=true end
        end) end
    end
    return discounted and 1 or 2
end
function R.CanSwap(id,a,b)
    if not R.IsRouls(id) or not activeTurn(id) or busy then return false,"Wait for your active turn." end
    if Game.GetGameTurn() < (R.GetState(id).swapReadyTurn or 0) then return false,"TRANSMIGRATION is cooling down." end
    local ok,why=R.SwapEligible(id,a); if not ok then return false,why end
    ok,why=R.SwapEligible(id,b); if not ok then return false,why end
    if a:GetID()==b:GetID() or a:GetPlot()==b:GetPlot() then return false,"Choose two units on different tiles." end
    if a:GetDomainType()~=b:GetDomainType() then return false,"Both units must have the same domain." end
    local ignored={[key(a)]=true,[key(b)]=true}
    if not R.IsLegalPlot(a,b:GetPlot(),ignored) or not R.IsLegalPlot(b,a:GetPlot(),ignored) then return false,"A destination is blocked or illegal for its new unit." end
    local cost=R.SwapCost(id,a,b)
    if R.GetAnima(id)<cost then return false,"Not enough Anima (cost "..cost..")." end
    return true,nil,cost
end
function R.DoSwap(id,aID,bID)
    local p=Players[id]; if not p then return false,"Player unavailable." end
    local a,b=p:GetUnitByID(aID),p:GetUnitByID(bID)
    local ok,why,cost=R.CanSwap(id,a,b); if not ok then return false,why end
    local ax,ay,bx,by=a:GetX(),a:GetY(),b:GetX(),b:GetY()
    busy=true
    -- SetXY allows a temporary friendly stack. It never removes either original
    -- object, so names, XP, promotions, religion, and script data remain intact.
    local success,err=pcall(function()
        a:SetXY(bx,by,0,1,0)
        b:SetXY(ax,ay,0,1,0)
        assert(alive(a) and alive(b) and a:GetX()==bx and a:GetY()==by and b:GetX()==ax and b:GetY()==ay,"A movement hook changed the swap.")
    end)
    if not success then
        if alive(a) then pcall(function() a:SetXY(ax,ay,0,1,0) end) end
        if alive(b) then pcall(function() b:SetXY(bx,by,0,1,0) end) end
        busy=false; R.RefreshAuras(); print("Rouls swap aborted: "..tostring(err))
        return false,"The exchange was interrupted; no Anima was spent."
    end
    R.ChangeAnima(id,-cost)
    R.GetState(id).swapReadyTurn=Game.GetGameTurn()+8; R.Save(id)
    R.LockUnit(a); R.LockUnit(b)
    busy=false; R.RefreshAuras()
    return true,"Consciousnesses exchanged. Both units must wait until your next turn."
end
local function uniqueClass(info)
    local c=info and GameInfo.UnitClasses[info.Class]
    return not c or (tonumber(c.MaxPlayerInstances) or -1)>=0
        or (tonumber(c.MaxTeamInstances) or -1)>=0 or (tonumber(c.MaxGlobalInstances) or -1)>=0
end
local function simplePlot(id,info,plot,ignore)
    if not plot or plot:IsMountain() or plot:IsImpassable() then return false end
    if info.Domain=="DOMAIN_LAND" and plot:IsWater() then return false end
    if info.Domain=="DOMAIN_SEA" and not plot:IsWater() then
        if not plot:IsCity() or plot:GetOwner()~=id or not plot:GetPlotCity():IsCoastal(1) then return false end
    end
    if plot:IsCity() and plot:GetOwner()~=id then return false end
    local pt=Players[id]:GetTeam(); local owner=plot:GetOwner()
    if owner>=0 and Players[owner]:GetTeam()~=pt and not enemy(pt,Players[owner]:GetTeam())
        and not Teams[Players[owner]:GetTeam()]:IsAllowsOpenBordersToTeam(pt) then return false end
    for i=0,plot:GetNumUnits()-1 do
        local u=plot:GetUnit(i)
        if alive(u) and not (ignore and ignore[key(u)]) then
            if enemy(pt,team(u)) or (R.IsMilitary(u) and GameInfo.Units[u:GetUnitType()].Domain==info.Domain) then return false end
        end
    end
    return true
end
function R.CanMigrate(id,target)
    if not R.IsRouls(id) or not activeTurn(id) or busy then return false,"Wait for your active turn." end
    local p,s=Players[id],R.GetState(id)
    if s.migrationUsed then return false,"The Great Migration has already been used." end
    if p:GetCurrentEra()<G.ERA_MODERN then return false,"Enter the Modern Era first." end
    if R.GetAnima(id)<7 then return false,"Requires 7 Anima and The Choir Eternal's larger reserve." end
    if not alive(target) or not R.IsMilitary(target) or target:GetOwner()==id then return false,"Choose an enemy military unit." end
    if not enemy(p:GetTeam(),team(target)) then return false,"You must already be at war with the target." end
    if target:GetDomainType()~=LAND and target:GetDomainType()~=SEA then return false,"Aircraft cannot be migrated." end
    local info=GameInfo.Units[target:GetUnitType()]
    if uniqueClass(info) or forbiddenWeapon(info) or target:IsEmbarked() or hasCargo(target) or target:IsInCombat() then
        return false,"Special limited units, missiles, embarked units and loaded carriers are ineligible."
    end
    if not target:GetPlot():IsVisible(p:GetTeam()) or target:IsInvisible(p:GetTeam(),false) then return false,"The target must be visible." end
    local near=false
    eachNear(target:GetPlot(),3,function(u) if u:GetOwner()==id and R.IsMilitary(u) then near=true end end)
    if not near then return false,"The target must be within 3 tiles of your military." end
    local typeID=R.EquivalentType(id,G[info.Class]); local replacement=typeID and GameInfo.Units[typeID]
    if not replacement or uniqueClass(replacement) or forbiddenWeapon(replacement)
        or replacement.Domain~=info.Domain or (tonumber(replacement.Combat) or 0)<=0 then return false,"No eligible Rou'ls equivalent exists." end
    if not simplePlot(id,replacement,target:GetPlot(),{[key(target)]=true}) then return false,"The target tile cannot safely contain its Rou'ls equivalent." end
    return true,nil,typeID
end
local function stagingPlots(id,info,targetPlot)
    local result,seen={},{}
    local function add(plot)
        if not plot or plot==targetPlot or seen[plot:GetPlotIndex()] then return end
        seen[plot:GetPlotIndex()]=true
        -- Never reveal unexplored terrain or spawn in hostile territory.
        if plot:GetOwner()~=id or not plot:IsVisible(Players[id]:GetTeam()) then return end
        if simplePlot(id,info,plot) then result[#result+1]=plot end
    end
    for city in Players[id]:Cities() do
        add(city:Plot())
        for dx=-2,2 do for dy=-2,2 do add(Map.PlotXYWithRangeCheck(city:GetX(),city:GetY(),dx,dy,2)) end end
    end
    if #result==0 then for i=0,Map.GetNumPlots()-1 do add(Map.GetPlotByIndex(i)) end end
    table.sort(result,function(a,b)
        local da,db=distance(a,targetPlot),distance(b,targetPlot)
        return da<db or (da==db and a:GetPlotIndex()<b:GetPlotIndex())
    end)
    return result
end
function R.DoMigration(id,targetOwner,targetID)
    local owner=Players[targetOwner]; local target=owner and owner:GetUnitByID(targetID)
    local ok,why,typeID=R.CanMigrate(id,target); if not ok then return false,why end
    local plot=target:GetPlot(); local candidates=stagingPlots(id,GameInfo.Units[typeID],plot)
    if #candidates==0 then return false,"Free a legal staging tile in your territory first." end
    local made,success,err=nil,false,nil
    busy=true
    R.WithSuppressedDeaths(function()
        success,err=pcall(function()
            local stage=candidates[1]
            made=Players[id]:InitUnit(typeID,stage:GetX(),stage:GetY())
            assert(alive(made),"Replacement creation failed.")
            -- Full DLL destination checks include ocean/ice technology and modded
            -- passability. Attack mode permits only the explicitly selected enemy.
            assert(made:CanMoveOrAttackInto(plot,0,1),"The equivalent cannot legally enter the target tile.")
            local xp=math.min(60,math.floor(target:GetExperience()/2))
            local victim=R.Snapshot(target)
            target:Kill(false,-1)
            -- Another mod can veto Kill through CanSaveUnit. Never move onto a
            -- surviving target: SetXY would displace/kill it outside our transaction.
            local survivor=owner:GetUnitByID(targetID)
            assert(not alive(survivor),"Another mod prevented the target's removal.")
            local moved,moveError=pcall(function()
                made:SetXY(plot:GetX(),plot:GetY(),0,1,0)
                assert(alive(made) and made:GetPlot()==plot,"Replacement was displaced.")
                made:SetExperience(xp)
                local hp=made:GetMaxHitPoints()
                made:SetDamage(hp-math.max(1,math.floor(hp*0.75)))
            end)
            if not moved then
                if alive(made) then made:Kill(false,-1); made=nil end
                R.Restore(targetOwner,victim,plot,100*(victim.maxHP-victim.damage)/victim.maxHP)
                error(moveError)
            end
        end)
        if not success and alive(made) then made:Kill(false,-1); made=nil end
    end)
    busy=false
    if not success then R.RefreshAuras(); print("Rouls migration aborted: "..tostring(err)); return false,"The target could not be migrated; no Anima was spent." end
    R.GetState(id).migrationUsed=true; R.Save(id); R.ChangeAnima(id,-7)
    R.LockUnit(made); R.RefreshAuras()
    return true,"The Great Migration is complete. The new vessel will act next turn."
end
local function setPromo(u,id,value) if id and u:IsHasPromotion(id)~=value then u:SetHasPromotion(id,value) end end
local function refreshUnit(u)
    if not alive(u) then return end
    local choir,happy,invasive=0,false,false
    local plot=u:GetPlot(); local isMilitary=R.IsMilitary(u)
    eachNear(plot,2,function(v)
        if v~=u then
            if u:GetUnitType()==G.UNIT_ROULS_HOLLOWHOUND and v:GetOwner()==u:GetOwner()
                and R.IsMilitary(v) and distance(plot,v:GetPlot())==1 then choir=choir+1 end
            if isMilitary and R.IsRouls(v:GetOwner()) and v:GetUnitType()==G.UNIT_ROULS_BUDDY then
                if team(u)==team(v) then happy=true
                elseif enemy(team(u),team(v)) and u:GetDomainType()==SEA and distance(plot,v:GetPlot())==1 then invasive=true end
            end
        end
    end)
    -- Buddy benefits from his own friendly aura as a unit within range 0.
    if isMilitary and R.IsRouls(u:GetOwner()) and u:GetUnitType()==G.UNIT_ROULS_BUDDY then happy=true end
    choir=math.min(5,choir)
    for i=1,5 do setPromo(u,G["PROMOTION_ROULS_CHOIR_"..i],choir==i) end
    setPromo(u,G.PROMOTION_ROULS_BUDDY_AURA,happy)
    setPromo(u,G.PROMOTION_ROULS_BUDDY_INVASION,invasive)
    positions[key(u)]={x=u:GetX(),y=u:GetY()}
end
function R.RefreshAuras()
    if busy then return end
    for id=0,(GameDefines.MAX_PLAYERS or 64)-1 do
        local p=Players[id]
        if p and p:IsAlive() then for u in p:Units() do refreshUnit(u) end end
    end
end
local function refreshNear(x,y)
    local p=Map.GetPlot(x,y); if p then eachNear(p,3,refreshUnit) end
end
local function move(id,uid,x,y)
    if busy then return end
    local k=id..":"..uid; local prev=positions[k]
    if prev then refreshNear(prev.x,prev.y) end
    if x and y then refreshNear(x,y) end
    local p=Players[id]; local u=p and p:GetUnitByID(uid)
    if alive(u) then excluded[k]=nil; refreshUnit(u) end
end
GameEvents.UnitSetXY.Add(move)
GameEvents.UnitPrekill.Add(function(id,uid,_,x,y)
    excluded[id..":"..uid]=true
    if not busy then refreshNear(x,y) end
    positions[id..":"..uid]=nil
end)
local function created(id,uid)
    excluded[id..":"..uid]=nil
    local p=Players[id]; local u=p and p:GetUnitByID(uid)
    if alive(u) then refreshNear(u:GetX(),u:GetY()); refreshUnit(u) end
end
if GameEvents.UnitCreated then GameEvents.UnitCreated.Add(created)
elseif Events.SerialEventUnitCreated then Events.SerialEventUnitCreated.Add(created) end
local function threat(u)
    local value=0
    eachNear(u:GetPlot(),3,function(v)
        if R.IsMilitary(v) and enemy(team(u),team(v)) and v:GetPlot():IsVisible(team(u)) then value=value+1 end
    end)
    return value
end
local function aiActions(id)
    local p=Players[id]; if not R.IsRouls(id) or p:IsHuman() then return end
    if not R.GetState(id).migrationUsed and p:GetCurrentEra()>=G.ERA_MODERN and R.GetAnima(id)>=7 then
        local best,score=nil,-1; local seen={}
        for source in p:Units() do if R.IsMilitary(source) then eachNear(source:GetPlot(),3,function(v)
            if not seen[key(v)] then
                seen[key(v)]=true
                if R.CanMigrate(id,v) then
                    local row=GameInfo.Units[v:GetUnitType()]
                    local s=math.max(row.Combat or 0,row.RangedCombat or 0)*10+v:GetExperience()
                    if s>score or (s==score and key(v)<key(best)) then best,score=v,s end
                end
            end
        end) end end
        if best then R.DoMigration(id,best:GetOwner(),best:GetID()); return end
    end
    if (R.GetState(id).swapReadyTurn or 0)>Game.GetGameTurn() then return end
    local units={}
    for u in p:Units() do if R.SwapEligible(id,u) then units[#units+1]=u end end
    table.sort(units,function(a,b) return a:GetID()<b:GetID() end)
    local bestA,bestB,bestScore=nil,nil,0
    local threats={}; for _,u in ipairs(units) do threats[u:GetID()]=threat(u) end
    for _,front in ipairs(units) do
        if threats[front:GetID()]>0 then for _,reserve in ipairs(units) do
            if threats[reserve:GetID()]==0 and reserve:GetDamage()<reserve:GetMaxHitPoints()*0.25 and R.CanSwap(id,front,reserve) then
                local s=0
                if front:GetDamage()>=front:GetMaxHitPoints()*0.4 then s=front:GetExperience()+front:GetDamage()+20
                elseif reserve:GetExperience()>front:GetExperience()+15 then s=reserve:GetExperience()-front:GetExperience() end
                if s>bestScore then bestA,bestB,bestScore=front,reserve,s end
            end
        end end
    end
    if bestA then R.DoSwap(id,bestA:GetID(),bestB:GetID()) end
end
GameEvents.PlayerDoTurn.Add(function(id)
    R.RefreshAuras()
    local p=Players[id]; if not p or not p:IsAlive() then return end
    local s=R.GetState(id)
    if s.auraHealTurn~=Game.GetGameTurn() then
        s.auraHealTurn=Game.GetGameTurn(); R.Save(id)
        for u in p:Units() do
            if alive(u) and u:IsHasPromotion(G.PROMOTION_ROULS_BUDDY_AURA) then
                local owner=u:GetPlot():GetOwner()
                if owner>=0 and Players[owner]:GetTeam()==p:GetTeam() then u:SetDamage(math.max(0,u:GetDamage()-5)) end
            end
        end
    end
    aiActions(id)
end)
if GameEvents.DeclareWar then GameEvents.DeclareWar.Add(R.RefreshAuras) end
if GameEvents.MakePeace then GameEvents.MakePeace.Add(R.RefreshAuras) end
if GameEvents.BattleFinished then GameEvents.BattleFinished.Add(R.RefreshAuras) end
R.RefreshAuras()
