-- CP v151 / 5.4.6. Gameplay context; the optional UI never mutates this state.
MapModData.CR7 = MapModData.CR7 or {}
local M = MapModData.CR7
if M.Initialized then return end
M.Initialized = true
local save = Modding.OpenSaveData()
local I = GameInfoTypes
local thresholds = {20,45,80,120,165,215,275}
local eras = {0,1,3,4,5,6,7}
local speed = GameInfo.GameSpeeds[Game.GetGameSpeedType()]
local pace = speed.TrainPercent / 100
local function turn() return Game.GetGameTurn() end
local function key(p,k) return 'CR7|v1|'..p..'|'..k end
local function get(p,k,default)
    local value = save.GetValue(key(p,k))
    if value == nil then return default end
    if type(default)=='boolean' then return value==true or value==1 end
    return value
end
local function put(p,k,value)
    if type(value)=='boolean' then value=value and 1 or 0 end
    save.SetValue(key(p,k),value)
end
local function once(p,k)
    if get(p,k,false) then return false end
    put(p,k,true); return true
end
local function isCR7(p)
    return Players[p] and Players[p]:IsAlive()
        and Players[p]:GetCivilizationType() == I.CIVILIZATION_RELENTLESS_SEVEN
end
local present=false
for p=0,GameDefines.MAX_MAJOR_CIVS-1 do if isCR7(p) then present=true;break end end
if not present then return end
local function chapter(p,n) return get(p,'Chapter'..n,false) end
local function promotion(name) return I['PROMOTION_CR7_'..name] end
local function setPromo(u,name,yes)
    yes=not not yes
    local id = promotion(name)
    if u and u:IsHasPromotion(id) ~= yes then u:SetHasPromotion(id,yes) end
end
local function military(u)
    local row = u and GameInfo.Units[u:GetUnitType()]
    return row and ((row.Combat or 0)>0 or (row.RangedCombat or 0)>0) or false
end
local function heal(u,n)
    if u and not u:IsDead() then u:SetDamage(math.max(0,u:GetDamage()-n)) end
end
-- CP's Lua wrapper reads these optional flags as luaL_optint, not booleans.
local function xp(u,n) u:ChangeExperience(n,-1,0,0,0) end
local function units(p,fn)
    for u in Players[p]:Units() do if military(u) and not u:IsDead() then fn(u) end end
end
local function scaled(n,column)
    return math.max(1,math.floor(n*(speed[column] or speed.TrainPercent)/100+0.5))
end
local function amount(n,oneTime) return math.floor(n*100*(oneTime and pace or 1)+0.5) end
local function need(n) return amount(thresholds[n],true) end
local function ga(p,n) Players[p]:ChangeGoldenAgeTurns(scaled(n,'GoldenAgePercent')) end
local function changed(p) LuaEvents.CR7Changed(p) end
local function cityKey(c) return c:GetX()..','..c:GetY()..','..c:GetGameTurnFounded() end
local function slot(p,id) return 'UnitSlot'..id end
local function lineage(u)
    local p,id = u:GetOwner(),u:GetID()
    local token = get(p,slot(p,id),nil)
    if token == nil then
        token = get(-1,'NextUnit',0)+1; put(-1,'NextUnit',token)
        put(p,slot(p,id),token)
    end
    return token
end
local function uk(u,k) return 'Lineage'..lineage(u)..'|'..k end
local function ug(u,k,d) return get(-1,uk(u,k),d) end
local function us(u,k,v) put(-1,uk(u,k),v) end
local function setBuilding(c,name,count)
    local id = I['BUILDING_CR7_'..name]
    if c:GetNumRealBuilding(id)~=count then c:SetNumRealBuilding(id,count) end
end
local dyingGenerals={}
local function nearGeneral(p,u)
    for general in Players[p]:Units() do
        local row = GameInfo.Units[general:GetUnitType()]
        if row.Class == 'UNITCLASS_GREAT_GENERAL' and not general:IsDead()
            and not dyingGenerals[p..'|'..general:GetID()]
            and Map.PlotDistance(u:GetX(),u:GetY(),general:GetX(),general:GetY())<=2 then return true end
    end
    return false
end
local function refreshUnit(p,u)
    if not military(u) then return end
    local own = isCR7(p)
    local veteran = u:GetLevel()>=4
    setPromo(u,'HABIT',own)
    setPromo(u,'EXPLOSIVE',own and chapter(p,3) and veteran)
    local plot=u:GetPlot()
    setPromo(u,'EXPLOSIVE_OPEN',own and chapter(p,3) and veteran and plot and plot:IsOpenGround())
    setPromo(u,'MADRID',own and chapter(p,4) and veteran)
    setPromo(u,'CAPTAIN',own and chapter(p,5) and nearGeneral(p,u))
    if not own then setPromo(u,'EXPLOSIVE_MOVE',false) end
end
local function unitHistory(u)
    if not u then return false end
    if u:IsHasPromotion(promotion('FIRST_IN')) or u:IsHasPromotion(promotion('FINISHER'))
        or u:IsHasPromotion(promotion('FINISHER_VETERAN')) then return true end
    for n=1,4 do if u:IsHasPromotion(promotion('REINVENTION_'..n)) then return true end end
    return false
end
local function refreshCities(p)
    local player=Players[p]
    local capital=player:GetCapitalCity()
    local overseas,selected={},{}
    for c in player:Cities() do
        local eligible=chapter(p,6) and capital and c:Plot():GetArea()~=capital:Plot():GetArea()
        if eligible then
            local ck='OverseasOrder|'..cityKey(c)
            if not get(p,ck,nil) then
                local order=get(p,'NextOverseas',0)+1
                put(p,'NextOverseas',order); put(p,ck,order)
            end
            overseas[#overseas+1]={city=c,order=get(p,ck,0)}
        end
        setBuilding(c,'ACADEMY_PRODUCTION',chapter(p,2)
            and c:IsHasBuilding(I.BUILDING_CR7_SPORTING_ACADEMY) and 1 or 0)
        setBuilding(c,'GOLDEN_PRODUCTION',chapter(p,7) and player:IsGoldenAge() and 1 or 0)
    end
    table.sort(overseas,function(a,b)
        if a.order==b.order then return cityKey(a.city)<cityKey(b.city) end
        return a.order<b.order
    end)
    local flight=Teams[player:GetTeam()]:IsHasTech(I.TECH_FLIGHT)
    for i=1,math.min(3,#overseas) do
        selected[cityKey(overseas[i].city)]=true
    end
    for c in player:Cities() do
        local eligible=selected[cityKey(c)]
        setBuilding(c,'OVERSEAS',eligible and 1 or 0)
        setBuilding(c,'OVERSEAS_FLIGHT',eligible and flight and 1 or 0)
    end
    if chapter(p,1) and capital and not get(p,'FreeAcademy',false) then
        local row=GameInfo.Buildings[I.BUILDING_CR7_SPORTING_ACADEMY]
        if capital:IsHasBuilding(row.ID) then put(p,'FreeAcademy',true)
        elseif Teams[player:GetTeam()]:IsHasTech(I[row.PrereqTech])
            and capital:CanConstruct(row.ID,0,0,0) then
            put(p,'FreeAcademy',true);capital:SetNumRealBuilding(row.ID,1)
        end
    end
end
local function refresh(p)
    if not isCR7(p) then return end
    refreshCities(p); units(p,function(u) refreshUnit(p,u) end)
end
local addAmbition,checkChapters,checkUnit,checkGP
local checking={}
checkChapters=function(p)
    if checking[p] or not isCR7(p) then return end
    checking[p]=true
    local player=Players[p]
    local effectsChanged=false
    for n=1,7 do
        if not chapter(p,n) and (n==1 or chapter(p,n-1))
            and get(p,'Ambition',0)>=need(n) and player:GetCurrentEra()>=eras[n] then
            -- Persist the entitlement before effects and re-entrant Golden Age hooks.
            put(p,'Chapter'..n,true)
            effectsChanged=true
            player:SetHasPolicy(I['POLICY_CR7_CHAPTER_'..n],true)
            if n==7 then
                put(p,'LegacyBase',get(p,'Ambition',0))
                ga(p,6)
                player:SetNumFreePolicies(player:GetNumFreePolicies()+1)
                units(p,function(u) xp(u,8);heal(u,u:GetMaxHitPoints()) end)
                for c in player:Cities() do
                    c:ChangeWeLoveTheKingDayCounter(scaled(2,'GoldenAgePercent'))
                end
            end
            if player:IsHuman() then LuaEvents.CR7ChapterUnlocked(p,n) end
        end
    end
    if chapter(p,7) then
        local count=get(p,'LegacyCount',0)
        local base=get(p,'LegacyBase',get(p,'Ambition',0))
        local step=amount(60,true)
        while get(p,'Ambition',0)-base >= (count+1)*step do
            count=count+1;put(p,'LegacyCount',count);put(p,'LegacyMilestone'..count,true)
            effectsChanged=true
            if count<=5 then player:SetHasPolicy(I['POLICY_CR7_LEGACY_'..count],true) end
            ga(p,1);player:ChangeJONSCulture(scaled(15*player:GetCurrentEra(),'CulturePercent'))
        end
    end
    checking[p]=nil
    if effectsChanged then refresh(p) end
    changed(p)
end
addAmbition=function(p,n,source,oneTime,limited)
    if not isCR7(p) then return end
    if limited then
        local prefix='Limit|'..source
        if get(p,prefix..'Turn',-1)~=turn() then
            put(p,prefix..'Turn',turn());put(p,prefix..'Count',0)
        end
        local used=get(p,prefix..'Count',0)
        if used>=3 then return end
        n=math.min(n,3-used);put(p,prefix..'Count',used+n)
    end
    put(p,'Ambition',get(p,'Ambition',0)+amount(n,oneTime))
    checkChapters(p)
end
checkUnit=function(p,u)
    if not military(u) then return end
    local era=Players[p]:GetCurrentEra()
    if u:GetLevel()>=6 and ug(u,'Developed',false) and not ug(u,'Level6Resolved',false) then
        us(u,'Level6Resolved',true)
        if once(p,'Level6Era'..era) then addAmbition(p,3,'Level6',true) end
    end
    if u:GetLevel()>=4 and ug(u,'TrainingOwner',-1)==p and not ug(u,'TrainingResolved',false) then
        us(u,'TrainingResolved',true)
        local plot=Map.GetPlot(ug(u,'TrainingX',-1),ug(u,'TrainingY',-1))
        local c=plot and plot:GetPlotCity()
        if c and c:GetOwner()==p and cityKey(c)==ug(u,'TrainingCity','')
            and once(p,'AcademyReward|'..cityKey(c)..'|'..era) then
            c:ChangeProduction(scaled(15,'ConstructPercent'))
            local culture=scaled(10,'CulturePercent')
            c:ChangeJONSCultureStored(culture);Players[p]:ChangeJONSCulture(culture)
            addAmbition(p,1,'Academy',true)
        end
    end
    refreshUnit(p,u)
end
local function onPromoted(p,id,promo)
    if not isCR7(p) then return end
    local u=Players[p]:GetUnitByID(id)
    local row=GameInfo.UnitPromotions[promo]
    if not military(u) or not row or row.CannotBeChosen==true or row.CannotBeChosen==1 then return end
    if not once(-1,uk(u,'Earned|'..u:GetLevel()..'|'..promo..'|'..turn())) then return end
    us(u,'Developed',true)
    -- UnitPromoted is emitted by earned promotions, not SetHasPromotion.
    if chapter(p,2) and ug(u,'PromotionHealTurn',-1)~=turn() then
        us(u,'PromotionHealTurn',turn());heal(u,10)
    end
    addAmbition(p,1,'Promotion',false,true);checkUnit(p,u)
end
local function onTrained(p,cityID,id,gold,faith)
    if not isCR7(p) then return end
    local player=Players[p];local u=player:GetUnitByID(id);local c=player:GetCityByID(cityID)
    if not u or not c or not once(-1,uk(u,'CityTrained')) then return end
    refreshUnit(p,u)
    if u:GetUnitType()==I.UNIT_CR7_COMPLETE_FORWARD then us(u,'Forward',true) end
    if military(u) and gold and chapter(p,3) then
        player:ChangeGold(math.floor(c:GetUnitPurchaseCost(u:GetUnitType())*0.05+0.5))
    end
    if gold or faith then return end
    if military(u) then
        us(u,'Developed',true)
        if chapter(p,2) then xp(u,5) end
        if chapter(p,1) and c:IsCapital() and once(p,'CapitalTrainedEra'..player:GetCurrentEra()) then xp(u,5) end
        if c:IsHasBuilding(I.BUILDING_CR7_SPORTING_ACADEMY) then
            us(u,'TrainingOwner',p);us(u,'TrainingX',c:GetX());us(u,'TrainingY',c:GetY())
            us(u,'TrainingCity',cityKey(c))
            setPromo(u,'ACADEMY_TRAINING',true);setPromo(u,'FIRST_IN',true)
        end
        checkUnit(p,u)
    elseif chapter(p,1) and c:IsCapital() and GameInfo.Units[u:GetUnitType()].Class=='UNITCLASS_WORKER' then
        setPromo(u,'WORKER_SIGHT',true)
    end
end
local function onConverted(oldP,newP,oldID,newID,isUpgrade)
    local old=Players[oldP] and Players[oldP]:GetUnitByID(oldID)
    local u=Players[newP] and Players[newP]:GetUnitByID(newID)
    if not old or not u then return end
    local history=unitHistory(old)
    if not isCR7(oldP) and not isCR7(newP) and not history then return end
    local token=lineage(old);put(newP,slot(newP,newID),token)
    local upgrade=get(oldP,'PendingUpgrade|'..newID,-1)==oldID
    put(oldP,'PendingUpgrade|'..newID,nil)
    if isUpgrade and upgrade and oldP==newP and military(old) and military(u)
        and old:GetUnitType()~=u:GetUnitType() then
        if isCR7(newP) then
            local level=0
            for n=1,4 do if old:IsHasPromotion(promotion('REINVENTION_'..n)) then level=n end end
            level=math.min(chapter(newP,6) and 4 or 3,level+1)
            for n=1,4 do setPromo(u,'REINVENTION_'..n,n==level) end
            if chapter(newP,6) then
                u:SetExperienceTimes100(math.max(u:GetExperienceTimes100(),old:GetExperienceTimes100()),-1)
                if old:GetMaxHitPoints()-old:GetDamage()<old:GetMaxHitPoints()*0.35 then heal(u,15) end
            end
        end
        if old:GetUnitType()==I.UNIT_CR7_COMPLETE_FORWARD and ug(old,'Forward',false) then
            setPromo(u,'FINISHER',false);setPromo(u,'FORWARD_MOBILITY',false)
            setPromo(u,'FINISHER_VETERAN',true)
        elseif u:GetUnitType()==I.UNIT_CR7_COMPLETE_FORWARD then us(u,'Forward',true) end
    end
    refreshUnit(newP,u)
    if isCR7(newP) then checkUnit(newP,u) end
end
local battles={}
local activeBattle
local function onBattleStarted(kind,x,y)
    battles[#battles+1]={kind=kind,x=x,y=y,units={},parent=activeBattle}
end
local function onBattleJoined(p,id,role,isCity,sourceBattle)
    local b=sourceBattle or battles[#battles];if not b then return end
    b.units[role]={p=p,id=id,city=isCity}
    local a,d=b.units[0],b.units[1]
    if not a or not d then return end
    for _,pair in ipairs({{a,d},{d,a}}) do
        local own,enemy=pair[1],pair[2]
        local u=not own.city and Players[own.p]:GetUnitByID(own.id)
        if u and isCR7(own.p) then
            us(u,'WarParticipant|'..Players[enemy.p]:GetTeam(),turn())
            setPromo(u,'MADRID_GG',chapter(own.p,4) and u:GetLevel()>=4
                and not enemy.city and enemy.p<GameDefines.MAX_MAJOR_CIVS)
        end
    end
end
local function onCombatResult(ap,au,ad,af,ah,dp,du,dd,df,dh,ip,iu,damage,x,y)
    local b
    for n=#battles,1,-1 do
        if battles[n].x==x and battles[n].y==y then b=battles[n];break end
    end
    if not b then return end
    activeBattle=b
    -- CP emits BattleJoined mainly for cities/bystanders. CombatResult is the
    -- authoritative pre-resolution source for normal attacker/defender IDs.
    if ap>=0 and au>=0 then onBattleJoined(ap,au,0,false,b) end
    if dp>=0 and du>=0 then onBattleJoined(dp,du,1,false,b)
    else
        local plot=Map.GetPlot(x,y);local c=plot and plot:GetPlotCity()
        if c then onBattleJoined(c:GetOwner(),c:GetID(),1,true,b) end
    end
end
local function onPrekill(p,id,typ,x,y,delay,killerP)
    if isCR7(p) and (GameInfo.Units[typ].Class=='UNITCLASS_GREAT_GENERAL'
        or GameInfo.Units[typ].Class=='UNITCLASS_GREAT_ADMIRAL') then checkGP(p) end
    if isCR7(p) and GameInfo.Units[typ].Class=='UNITCLASS_GREAT_GENERAL' then
        dyingGenerals[p..'|'..id]=true
        units(p,function(u) refreshUnit(p,u) end)
    end
    if not Players[killerP] or killerP==p then return end
    local b=activeBattle;if not b then return end
    local victim=Players[p]:GetUnitByID(id)
    if not military(victim) then return end
    local a,d=b.units[0],b.units[1];local killer
    if a and d and not a.city and not d.city then
        if a.p==p and a.id==id and d.p==killerP then killer=Players[killerP]:GetUnitByID(d.id)
        elseif d.p==p and d.id==id and a.p==killerP then killer=Players[killerP]:GetUnitByID(a.id) end
    end
    if not military(killer) or killer:IsDead() then return end
    if not isCR7(killerP) and not unitHistory(killer) then return end
    if not once(-1,uk(victim,'KillRewarded')) then return end
    local kr,vr=GameInfo.Units[killer:GetUnitType()],GameInfo.Units[typ]
    if math.max(vr.Combat or 0,vr.RangedCombat or 0)>=math.max(kr.Combat or 0,kr.RangedCombat or 0) then
        addAmbition(killerP,1,'Victory',false,true)
    end
    local reinvention=0
    for n=1,4 do if killer:IsHasPromotion(promotion('REINVENTION_'..n)) then reinvention=n end end
    local finish=killer:IsHasPromotion(promotion('FINISHER'))
    heal(killer,reinvention*3+(finish and 8 or killer:IsHasPromotion(promotion('FINISHER_VETERAN')) and 5 or 0))
    if finish and ug(killer,'FinisherMoveTurn',-1)~=turn() then
        us(killer,'FinisherMoveTurn',turn())
        -- Defer until DLL attack movement costs have been paid.
        b.move={p=killerP,id=killer:GetID()}
    end
end
local function onBattleFinished()
    local b=activeBattle
    if b then
        for n=#battles,1,-1 do if battles[n]==b then table.remove(battles,n);break end end
    else b=table.remove(battles) end
    if not b then return end
    activeBattle=nil
    if b.parent then
        for _,pending in ipairs(battles) do if pending==b.parent then activeBattle=pending;break end end
    end
    if b.move then
        local u=Players[b.move.p]:GetUnitByID(b.move.id)
        if u and not u:IsDead() then u:ChangeMoves(GameDefines.MOVE_DENOMINATOR or 60) end
    end
    for _,v in pairs(b.units) do
        local u=not v.city and Players[v.p]:GetUnitByID(v.id)
        if u and isCR7(v.p) then setPromo(u,'MADRID_GG',false);checkUnit(v.p,u) end
    end
end
local function onCapture(oldP,isCapital,x,y,newP,population,conquest)
    local c=Map.GetPlot(x,y):GetPlotCity()
    if c then
        for _,name in ipairs({'ACADEMY_PRODUCTION','OVERSEAS','OVERSEAS_FLIGHT','GOLDEN_PRODUCTION'}) do setBuilding(c,name,0) end
    end
    if isCR7(oldP) then refresh(oldP) end
    if not isCR7(newP) then return end
    local p=Players[newP];local b=activeBattle;local u
    local genuine=conquest and b and b.kind==0 and b.x==x and b.y==y
        and b.units[0] and b.units[0].p==newP and not b.units[0].city
        and b.units[1] and b.units[1].city and b.units[1].p==oldP and not b.captured
    if genuine then
        u=p:GetUnitByID(b.units[0].id)
        b.captured=true
    end
    -- CP fires the capture hook while the attacker can still stand outside the city.
    if genuine and c and chapter(newP,4) and military(u) and u:GetLevel()>=4
        and turn()>=get(newP,'CaptureNext',-1) then
        put(newP,'CaptureNext',turn()+scaled(25,'TrainPercent'))
        p:ChangeJONSCulture(scaled(3*c:GetPopulation(),'CulturePercent'))
        p:ChangeGoldenAgeProgressMeter(scaled(3*c:GetPopulation(),'GoldenAgePercent'));heal(u,15)
    end
    if genuine and c and c:IsOriginalCapital() and c:GetOriginalOwner()~=newP then
        local identity=cityKey(c)
        if once(newP,'CapitalAmbition|'..identity) then addAmbition(newP,6,'Capital',true) end
        if chapter(newP,4) and once(newP,'DecisiveNight|'..identity) then
            ga(newP,2)
            local enemyTeam=Players[oldP]:GetTeam()
            local warStart=get(newP,'WarStart|'..enemyTeam,-1)
            units(newP,function(v)
                if ug(v,'WarParticipant|'..enemyTeam,-2)>=warStart then xp(v,3) end
            end)
        end
    end
    refresh(newP)
end
local function onConstructed(p,cityID,building,gold,faith)
    if not isCR7(p) then return end
    local c=Players[p]:GetCityByID(cityID);local row=GameInfo.Buildings[building]
    local class=row and GameInfo.BuildingClasses[row.BuildingClass]
    if c and class and not gold and not faith and once(p,'Completion|'..cityKey(c)..'|'..building..'|'..turn()) then
        if class.MaxGlobalInstances==1 then addAmbition(p,4,'WorldWonder',true)
        elseif class.MaxPlayerInstances==1 then addAmbition(p,2,'NationalWonder',true) end
    end
    refreshCities(p)
end
local function onGoldenAge(p,start,duration)
    if not isCR7(p) then return end
    if start then addAmbition(p,3,'GoldenAge',true) end
    refreshCities(p);changed(p)
end
local function onWar(origin,againstTeam,aggressor)
    local originP=Players[origin];if not originP then return end
    -- againstTeam is the defending team; origin is the initiating player.
    for p=0,GameDefines.MAX_MAJOR_CIVS-1 do
        if isCR7(p) then
            local player=Players[p]
            if player:GetTeam()==originP:GetTeam() or player:GetTeam()==againstTeam then
                local enemy=player:GetTeam()==againstTeam and originP:GetTeam() or againstTeam
                put(p,'WarStart|'..enemy,turn())
                if aggressor and player:GetTeam()==againstTeam and chapter(p,5)
                    and turn()>=get(p,'WarResponseNext',-1) then
                    put(p,'WarResponseNext',turn()+scaled(30,'TrainPercent'))
                    player:ChangeGoldenAgeProgressMeter(scaled(50,'GoldenAgePercent'))
                    units(p,function(u) if u:GetPlot():GetOwner()==p then heal(u,5) end end)
                end
            end
        end
    end
end
local function onCreated(p,id,typ,x,y)
    local u=Players[p] and Players[p]:GetUnitByID(id);if not u then return end
    -- Unit IDs can be reused. A fresh creation gets a fresh lineage before conversion transfers it.
    put(p,slot(p,id),nil);lineage(u)
    dyingGenerals[p..'|'..id]=nil
    if not isCR7(p) then return end
    refreshUnit(p,u)
    local row=GameInfo.Units[typ]
    if row.Class=='UNITCLASS_GREAT_GENERAL' or row.Class=='UNITCLASS_GREAT_ADMIRAL' then
        checkGP(p)
        local general=row.Class=='UNITCLASS_GREAT_GENERAL'
        us(u,'PendingGP',true);us(u,'GPGeneral',general)
        us(u,'GPThreshold',general and Players[p]:GetGreatGeneralsThresholdModifier()
            or Players[p]:GetGreatAdmiralsThresholdModifier())
    end
end
checkGP=function(p)
    for u in Players[p]:Units() do
        if ug(u,'PendingGP',false) then
            local current=ug(u,'GPGeneral',false) and Players[p]:GetGreatGeneralsThresholdModifier()
                or Players[p]:GetGreatAdmiralsThresholdModifier()
            -- Real CP births increment the appropriate threshold after UnitCreated;
            -- bare InitUnit, upgrades and ownership transfers do not.
            if current>ug(u,'GPThreshold',current) then
                us(u,'PendingGP',false)
                if once(-1,uk(u,'GPReward')) then addAmbition(p,3,'GreatPerson',true) end
            end
            us(u,'PendingGP',false)
        end
    end
end
local function checkPopulation(p,c)
    if not isCR7(p) or not c then return end
    for _,n in ipairs({12,24,36}) do
        if c:GetPopulation()>=n and once(p,'Population'..n) then addAmbition(p,2,'Population',true) end
    end
end
local function onTurn(p)
    if not isCR7(p) then return end
    -- No combat resolution spans a player-turn boundary. Discard any abandoned
    -- preview/aborted frames and repair their temporary General-point flags.
    battles={};activeBattle=nil
    local first=once(p,'TurnApplied'..turn())
    local beginningHP={}
    if first then units(p,function(u) beginningHP[u:GetID()]=u:GetMaxHitPoints()-u:GetDamage() end) end
    checkGP(p);checkChapters(p)
    local player=Players[p]
    for c in player:Cities() do checkPopulation(p,c) end
    units(p,function(u)
        setPromo(u,'MADRID_GG',false)
        refreshUnit(p,u);checkUnit(p,u)
        if first then
            -- PlayerDoTurn precedes doTurnUnits/resetMoves in CP. Change max
            -- movement once here; the DLL supplies it without mid-turn toggling.
            setPromo(u,'EXPLOSIVE_MOVE',chapter(p,3) and u:GetLevel()>=4
                and (beginningHP[u:GetID()] or 0)>90)
            if u:IsHasPromotion(promotion('CAPTAIN')) then heal(u,3) end
            if chapter(p,7) and player:IsGoldenAge() and u:GetLevel()>=4 then heal(u,3) end
        end
    end)
    refreshCities(p);changed(p)
end
local function onMoved(p,id,x,y)
    if not isCR7(p) then return end
    local u=Players[p]:GetUnitByID(id);if not u then return end
    if GameInfo.Units[u:GetUnitType()].Class=='UNITCLASS_GREAT_GENERAL' then
        units(p,function(v) refreshUnit(p,v) end)
    else refreshUnit(p,u) end
end
M.GetUIState=function(p)
    if not isCR7(p) then return nil end
    local result={ambition=get(p,'Ambition',0)/100,chapter=0,thresholds={},unlocked={},eras=eras,
        legacy=get(p,'LegacyCount',0),legacyProgress=0,legacyStep=amount(60,true)/100}
    for n=1,7 do
        result.thresholds[n]=need(n)/100;result.unlocked[n]=chapter(p,n)
        if result.unlocked[n] then result.chapter=n end
    end
    if chapter(p,7) then result.legacyProgress=(get(p,'Ambition',0)-get(p,'LegacyBase',0)
        -result.legacy*amount(60,true))/100 end
    return result
end
-- Public gameplay handlers make the same production paths available to the regression harness.
M.AddAmbition=addAmbition;M.CheckChapters=checkChapters;M.OnTurn=onTurn
M.OnTrained=onTrained;M.OnPromoted=onPromoted;M.OnConverted=onConverted
M.OnBattleStarted=onBattleStarted;M.OnBattleJoined=onBattleJoined
M.OnCombatResult=onCombatResult
M.OnPrekill=onPrekill;M.OnBattleFinished=onBattleFinished;M.OnCapture=onCapture
M.OnConstructed=onConstructed;M.OnGoldenAge=onGoldenAge;M.OnWar=onWar;M.OnCreated=onCreated
local function onUpgraded(p,oldID,newID,goody)
    -- Keep the identity and reduced Finisher behavior when a trained unit changes owners.
    local old=Players[p] and Players[p]:GetUnitByID(oldID)
    if isCR7(p) or unitHistory(old) then put(p,'PendingUpgrade|'..newID,oldID) end
end
M.OnUpgraded=onUpgraded
GameEvents.PlayerDoTurn.Add(onTurn)
GameEvents.CityTrained.Add(onTrained)
GameEvents.UnitPromoted.Add(onPromoted)
GameEvents.UnitConverted.Add(onConverted)
GameEvents.UnitUpgraded.Add(onUpgraded)
GameEvents.UnitCreated.Add(onCreated)
GameEvents.UnitPrekill.Add(onPrekill)
GameEvents.BattleStarted.Add(onBattleStarted)
GameEvents.BattleJoined.Add(onBattleJoined)
GameEvents.CombatResult.Add(onCombatResult)
GameEvents.BattleFinished.Add(onBattleFinished)
GameEvents.CityCaptureComplete.Add(onCapture)
GameEvents.CityConstructed.Add(onConstructed)
GameEvents.PlayerGoldenAge.Add(onGoldenAge)
GameEvents.DeclareWar.Add(onWar)
GameEvents.UnitSetXY.Add(onMoved)
GameEvents.PlayerCityFounded.Add(function(p) if isCR7(p) then refreshCities(p) end end)
GameEvents.SetPopulation.Add(function(x,y,oldPopulation,newPopulation)
    local plot=Map.GetPlot(x,y);local c=plot and plot:GetPlotCity()
    if c then checkPopulation(c:GetOwner(),c) end
end)
GameEvents.TeamTechResearched.Add(function(team)
    for p=0,GameDefines.MAX_MAJOR_CIVS-1 do
        if isCR7(p) and Players[p]:GetTeam()==team then checkChapters(p) end
    end
end)
-- Loading repairs permanent representations, never reapplies one-time rewards.
for p=0,GameDefines.MAX_MAJOR_CIVS-1 do
    if isCR7(p) then
        for n=1,7 do
            if chapter(p,n) then Players[p]:SetHasPolicy(I['POLICY_CR7_CHAPTER_'..n],true) end
        end
        for n=1,math.min(5,get(p,'LegacyCount',0)) do Players[p]:SetHasPolicy(I['POLICY_CR7_LEGACY_'..n],true) end
        units(p,function(u) lineage(u);setPromo(u,'MADRID_GG',false) end)
        refresh(p)
    end
end
