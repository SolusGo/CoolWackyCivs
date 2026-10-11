-- Gameplay owns the journey. The optional panel reads snapshots and requests actions.
include('ParadisePersistence')
MapModData.Paradise = MapModData.Paradise or {}
local M = MapModData.Paradise
if M.Initialized then return end
M.Initialized = true
local P,I = ParadisePersistence,GameInfoTypes
local CIV,HERO = I.CIVILIZATION_BOY_TOUCHED_PARADISE,I.UNIT_PARADISE_EL_DIEZ
local POTRERO,DANCE = I.BUILDING_PARADISE_POTRERO,I.BUILDING_PARADISE_LAST_DANCE
local RENAISSANCE,INDUSTRIAL,MODERN = I.ERA_RENAISSANCE,I.ERA_INDUSTRIAL,I.ERA_MODERN
local states,removing,casting = {},false,false
local refresh,transition,settleBirths,recoverChallenge
local function truth(v) return v==true or v==1 end
local function turn() return Game.GetGameTurn() end
local function isParadise(p)
    local player=Players[p]
    return player and player:GetCivilizationType()==CIV and player:IsHuman()
end
local function alive(p) return isParadise(p) and Players[p]:IsAlive() end
local function scaled(n,column)
    local speed=GameInfo.GameSpeeds[Game.GetGameSpeedType()]
    return math.max(1,math.floor(n*(tonumber(speed[column or 'TrainPercent']) or 100)/100+0.5))
end
local function cityKey(c) return c:GetX()..','..c:GetY()..','..c:GetGameTurnFounded() end
local function unitKey(p,u) return p..','..u:GetID()..','..u:GetGameTurnCreated()..','..u:GetUnitType() end
local function state(p)
    if not states[p] then
        states[p]=P.Read(p) or {dreams=0,lifetime=0,pressure=0,clock=0,lastTurn=-1,
            claims={},memories={},memoryIDs={},pending={},cities={},alliances={},
            distinctAllies={},wonderEras={},potreroCities={},gp=0,goldenStarts=0,
            greatWorks=0,act=1,heroSpawned=false,heroID=-1,recoveryDue=-1,
            crisis=false,recovered=false,fulfilled=false,finalShown=false,
            story='',golden=Players[p]:IsGoldenAge()}
    end
    return states[p]
end
local function persist(p) P.Write(p,state(p)) end
local function changed(p)
    persist(p)
    LuaEvents.ParadiseChanged(p)
end
local function notice(p,message,city)
    Players[p]:AddNotification(NotificationTypes.NOTIFICATION_GENERIC,message,
        'The Journey',city and city:GetX() or -1,city and city:GetY() or -1)
end
local function claim(p,key)
    local s=state(p)
    if s.claims[key] then return false end
    s.claims[key]=true
    return true
end
local function memory(p,id,title,category,description,city)
    local s=state(p)
    if s.memoryIDs[id] then return end
    s.memoryIDs[id]=true
    s.memories[#s.memories+1]={id=id,title=title,category=category,description=description,
        turn=turn(),era=Players[p]:GetCurrentEra(),city=city or ''}
end
local function pressure(p,delta)
    local s=state(p)
    if s.fulfilled or not s.crisis and s.act==1 then return end
    s.pressure=math.max(0,math.min(100,s.pressure+delta))
end
local function dreams(p,n,source,city)
    local s=state(p)
    s.dreams=s.dreams+n;s.lifetime=s.lifetime+n
    if n>0 then memory(p,'firstDream','The First Dream','dream',
        'A beautiful possibility has become something you can carry into tomorrow.',city and city:GetName()) end
    notice(p,'+'..n..' Dreams: '..source..'. Balance '..s.dreams..'; lifetime '..s.lifetime..'.',city)
end
local function eraClaim(p,kind)
    return claim(p,kind..'Era|'..Players[p]:GetCurrentEra())
end
local function ownedCity(p,x,y,founded)
    local plot=Map.GetPlot(x,y);local c=plot and plot:GetPlotCity()
    if c and c:GetOwner()==p and (not founded or c:GetGameTurnFounded()==founded) then return c end
end
local function host(p)
    local s=state(p);local u=Players[p]:GetUnitByID(s.heroID)
    if not u or u:GetUnitType()~=HERO or u:IsDead() or u:IsDelayedDeath() or s.recoveryDue>=0 then return nil end
    local c=u:GetPlot() and u:GetPlot():GetPlotCity()
    return c and c:GetOwner()==p and c or nil
end
local function setBuilding(c,name,n)
    local id=I['BUILDING_PARADISE_'..name]
    if c:GetNumRealBuilding(id)~=n then c:SetNumRealBuilding(id,n) end
end
local DUMMIES={'PRESENCE','CAPITAL','PRESSURE_5','PRESSURE_10','HOPE','MEMORIAL','FULFILLED'}
local function clearCity(c)
    for _,name in ipairs(DUMMIES) do setBuilding(c,name,0) end
end
local function objectiveList(p)
    local s=state(p);local count=0
    local rows={
        {title='Generate four Great People',done=s.gp>=4,progress=s.gp..' / 4'},
        {title='Begin two Golden Ages',done=s.goldenStarts>=2,progress=s.goldenStarts..' / 2'},
        {title='Build World Wonders in two eras',done=false},
        {title='Ally with two distinct City-States',done=false},
        {title='Complete the national recovery',done=s.recovered,progress=s.recovered and 'Complete' or 'Awaiting recovery'},
        {title='Develop two Potrero cities and two Great Works',done=false}}
    local eras,allies,cities=0,0,0
    for _ in pairs(s.wonderEras) do eras=eras+1 end
    for _ in pairs(s.distinctAllies) do allies=allies+1 end
    for _ in pairs(s.potreroCities) do cities=cities+1 end
    rows[3].done=eras>=2;rows[3].progress=eras..' / 2 eras'
    rows[4].done=allies>=2;rows[4].progress=allies..' / 2 allies'
    rows[6].done=cities>=2 and s.greatWorks>=2
    rows[6].progress=cities..' / 2 cities; '..s.greatWorks..' / 2 works'
    for _,row in ipairs(rows) do if row.done then count=count+1 end end
    return rows,count
end
local function eligible(p)
    if not alive(p) then return false end
    local s=state(p);local _,count=objectiveList(p)
    return not s.fulfilled and Players[p]:GetCurrentEra()>=MODERN and s.lifetime>=40 and count>=3
end
refresh=function(p)
    if not isParadise(p) then return end
    local s=state(p);local h=alive(p) and host(p);local cap=Players[p]:GetCapitalCity()
    local tier=not s.fulfilled and s.act>=2 and (s.pressure>=75 and 10 or s.pressure>=50 and 5 or 0) or 0
    s.greatWorks=math.max(s.greatWorks,Players[p]:GetNumGreatWorks())
    for c in Players[p]:Cities() do
        local isHost=h and cityKey(h)==cityKey(c)
        setBuilding(c,'PRESENCE',isHost and 1 or 0)
        setBuilding(c,'CAPITAL',cap and cityKey(cap)==cityKey(c) and 1 or 0)
        setBuilding(c,'PRESSURE_5',tier==5 and 1 or 0)
        setBuilding(c,'PRESSURE_10',tier==10 and 1 or 0)
        local r=s.cities[cityKey(c)]
        setBuilding(c,'HOPE',r and r.hopeUntil and r.hopeUntil>s.clock and 1 or 0)
        setBuilding(c,'MEMORIAL',s.fulfilled and cap and cityKey(cap)==cityKey(c) and 1 or 0)
        setBuilding(c,'FULFILLED',s.fulfilled and cap and cityKey(cap)==cityKey(c) and 1 or 0)
    end
end
local function challenge(p)
    local s=state(p)
    s.challenge={startTurn=turn(),startClock=s.clock,deadline=s.clock+scaled(25),practice=0,
        serial=(s.challengeSerial or 0)+1}
    s.challengeSerial=s.challenge.serial
    s.story='DENIED';persist(p)
    LuaEvents.ParadiseStory(p,'DENIED')
end
transition=function(p)
    local s=state(p);local era=Players[p]:GetCurrentEra()
    if era>=RENAISSANCE and claim(p,'Renaissance') then
        s.act=2;pressure(p,25-s.pressure)
        memory(p,'burden','The Burden of Expectation','pressure',
            'The gift has never faded. But now a nation asks it to carry something heavier than applause.')
        s.story='BURDEN';persist(p);LuaEvents.ParadiseStory(p,'BURDEN')
    end
    if era>=INDUSTRIAL and not s.crisis then
        s.crisis=true;pressure(p,40)
        memory(p,'denied','A Dream Denied','heartbreak',
            'The nation had almost dared to call the dream inevitable. Its uncertain ending leaves room for one more beginning.')
        challenge(p)
    end
    if era>=MODERN and claim(p,'Modern') then
        s.act=3
        memory(p,'lastDance','The Last Dance','journey',
            'The years have changed the world around you. There is still time to finish what the child began.')
        notice(p,'Act III: The Last Dance. Pressure stops growing with time; recovery remains available.')
    end
end
recoverChallenge=function(p,eventTurn,eventClock,serial,city)
    local s=state(p);local q=s.challenge
    if not q or s.recovered or eventTurn<q.startTurn or eventClock<q.startClock
        or s.clock>q.deadline or serial and serial~=q.serial then return false end
    s.recovered=true;s.challenge=nil;s.comebackDue=nil
    pressure(p,-30);dreams(p,5,'We Rise Again',city)
    memory(p,'recovery','We Rise Again','recovery',
        'You did not erase the disappointment. You answered it with patient work, and found a new way forward.',city and city:GetName())
    s.story='RECOVERY';persist(p);LuaEvents.ParadiseStory(p,'RECOVERY')
    return true
end
local function achievement(p,kind,city,birth)
    local s=state(p)
    transition(p)
    if kind=='gp' then
        s.gp=s.gp+1;dreams(p,2,'A Great Person is born',city)
        if eraClaim(p,'PressureGP') then pressure(p,-8) end
    elseif kind=='wonder' then
        s.wonderEras[tostring(Players[p]:GetCurrentEra())]=true
        dreams(p,4,'A World Wonder is completed',city)
        if eraClaim(p,'PressureWonder') then pressure(p,-10) end
    elseif kind=='golden' then
        s.goldenStarts=s.goldenStarts+1
        if eraClaim(p,'Golden') then dreams(p,3,'The first Golden Age of this era',city);pressure(p,-12) end
    elseif kind=='alliance' then
        if eraClaim(p,'Alliance') then dreams(p,2,'A new City-State alliance',city);pressure(p,-10) end
    elseif kind=='potrero' then
        if eraClaim(p,'Potrero') then dreams(p,1,'The first El Potrero of this era',city) end
    end
    memory(p,kind..'|'..Players[p]:GetCurrentEra(),
        ({gp='A Gift Shared',wonder='Something Beautiful Built',golden='Days of Sunlight',
            alliance='A Friend Beyond Borders',potrero='Where It All Began'})[kind],kind,
        ({gp='Another extraordinary mind makes the nation greater.',wonder='Patience and imagination have left their mark on the world.',
            golden='For a little while, possibility feels close enough to touch.',alliance='An unfamiliar flag has become the sign of a friend.',
            potrero='A humble ground gives the next generation a place to dream.'})[kind],city and city:GetName())
    if kind~='potrero' then
        recoverChallenge(p,birth and birth.turn or turn(),birth and birth.clock or s.clock,
            birth and birth.challenge or nil,city)
    end
    refresh(p);changed(p)
end
local function heroLost(p,u,killer)
    if removing or not isParadise(p) then return end
    local s=state(p)
    if not u or u:GetUnitType()~=HERO or not claim(p,'HeroLost|'..unitKey(p,u)) then return end
    if s.heroID~=u:GetID() then return end
    s.heroID=-1;s.recoveryDue=s.clock+scaled(5)
    -- Voluntary deletion has no Dream/Memory reward and no pressure penalty.
    if killer and killer>=0 and killer~=p and s.act>=2 and eraClaim(p,'HeroIncident') then
        pressure(p,8)
        memory(p,'heroIncident|'..Players[p]:GetCurrentEra(),'An Empty Place','heartbreak',
            'For a moment the familiar figure is missing. The nation keeps his place, and waits for his return.')
    end
    refresh(p);changed(p)
end
local function removeUnit(u)
    -- A native init()/convert() caller can still hold this unit pointer.
    removing=true;u:Kill(true,-1);removing=false
end
local function ensureHero(p)
    if not alive(p) then return end
    local s=state(p);local keeper
    for u in Players[p]:Units() do
        if u:GetUnitType()==HERO and not u:IsDead() and not u:IsDelayedDeath() then
            if s.recoveryDue>=0 or keeper then removeUnit(u)
            else keeper=u;u:SetNoMaintenance(true) end
        end
    end
    if keeper then s.heroID=keeper:GetID();return end
    local c=Players[p]:GetCapitalCity()
    if c and not s.originalCapital then s.originalCapital=cityKey(c) end
    if not c then for candidate in Players[p]:Cities() do c=candidate;break end end
    if not c then return end
    if s.heroSpawned and s.recoveryDue<0 then
        -- Repair a missing/dead unit after reload without rewarding its existence.
        s.heroID=-1;s.recoveryDue=s.clock+scaled(5)
    end
    if not s.heroSpawned or s.recoveryDue>=0 and s.clock>=s.recoveryDue then
        -- An occupied civilian slot is a lawful reason to wait, never to duplicate.
        local function freeSlot(candidate)
            local plot=candidate:Plot()
            for i=0,plot:GetNumUnits()-1 do
                local u=plot:GetUnit(i)
                if u and not u:IsDead() and not u:IsDelayedDeath() and not u:IsCombatUnit() and u:GetUnitType()~=HERO then return false end
            end
            return true
        end
        if not freeSlot(c) then
            c=nil
            for candidate in Players[p]:Cities() do
                if freeSlot(candidate) then c=candidate;break end
            end
        end
        if not c then return end
        local u=Players[p]:InitUnit(HERO,c:GetX(),c:GetY(),UnitAITypes.UNITAI_WORKER)
        if u then
            s.heroID=u:GetID();s.heroSpawned=true;s.recoveryDue=-1
            u:SetNoMaintenance(true);u:SetName('El Diez')
            memory(p,'opening','He Was Beautiful','journey',
                'A child learns that a ball can turn an ordinary street into a world of possibility.',c:GetName())
        end
    end
end
local function gpSnapshot(p,u)
    local row=GameInfo.Units[u:GetUnitType()]
    if not row or row.Special~='SPECIALUNIT_PEOPLE' or u:GetUnitType()==HERO then return nil end
    local class=row.Class;local player=Players[p]
    if class=='UNITCLASS_GREAT_GENERAL' then return 'general',player:GetGreatGeneralsCreated(true) end
    if class=='UNITCLASS_GREAT_ADMIRAL' then
        -- setNavalCombatExperience creates the Admiral before spending its meter.
        -- Free/scripted Admirals do not have this earned-meter proof.
        return 'admiral',player:GetGreatAdmiralsThresholdModifier(),nil,
            player:GetNavalCombatExperience()>=player:GreatAdmiralThreshold()
    end
    if truth(row.FoundReligion) then return 'prophet',player:GetMinimumFaithNextGreatProphet() end
    local c=player:GetCapitalCity();local classID=I[class]
    if c and classID then return 'specialist',c:GetSpecialistUpgradeThreshold(classID),classID end
end
local function birthValue(p,r)
    local player=Players[p]
    if r.kind=='general' then return player:GetGreatGeneralsCreated(true) end
    if r.kind=='admiral' then return player:GetGreatAdmiralsThresholdModifier() end
    if r.kind=='prophet' then return player:GetMinimumFaithNextGreatProphet() end
    local c=player:GetCapitalCity()
    return c and c:GetSpecialistUpgradeThreshold(r.class) or r.before
end
settleBirths=function(p)
    local s=state(p);local pending=s.pending;s.pending={}
    for _,key in ipairs((function()local keys={};for k in pairs(pending) do keys[#keys+1]=k end;table.sort(keys);return keys end)()) do
        local r=pending[key];local now=birthValue(p,r)
        local step=(GameDefines.GREAT_GENERALS_THRESHOLD_INCREASE or 50)+(GameDefines.GREAT_GENERALS_THRESHOLD_INCREASE_TEAM or 50)
        local genuine=not r.excluded and now>r.before
        if r.kind=='admiral' then genuine=genuine and r.navalReady and now-r.before>=step end
        if genuine and claim(p,'Birth|'..key) then
            local city=ownedCity(p,r.x,r.y)
            achievement(p,'gp',city,r)
        end
    end
end
local function onCreated(p,id,typ,x,y)
    if not isParadise(p) then
        -- No foreign unit can retain this unique hero after a conversion.
        if typ==HERO then
            local u=Players[p] and Players[p]:GetUnitByID(id)
            if u then removeUnit(u) end
        end
        return
    end
    if removing then return end
    settleBirths(p)
    local u=Players[p]:GetUnitByID(id)
    if not u then return end
    local kind,value,class,navalReady=gpSnapshot(p,u)
    if kind and claim(p,'Created|'..unitKey(p,u)) then
        local s=state(p)
        s.pending[unitKey(p,u)]={id=id,kind=kind,before=value,class=class or -1,
            x=x or u:GetX(),y=y or u:GetY(),turn=turn(),clock=s.clock,
            challenge=s.challenge and s.challenge.serial or -1,navalReady=navalReady or false}
        persist(p)
    end
end
local function onTrained(p,cityID,id,gold,faith)
    if not isParadise(p) then return end
    local u=Players[p]:GetUnitByID(id);local r=u and state(p).pending[unitKey(p,u)]
    if r then r.excluded=true;persist(p) end -- Production/purchases are not natural GP births.
end
local function onConverted(oldP,newP,oldID,newID,isUpgrade)
    local u=Players[newP] and Players[newP]:GetUnitByID(newID)
    if isParadise(newP) and u then
        local r=state(newP).pending[unitKey(newP,u)]
        if r then r.excluded=true;persist(newP) end
    end
    if isParadise(oldP) then
        local old=Players[oldP]:GetUnitByID(oldID)
        if old and old:GetUnitType()==HERO then heroLost(oldP,old,newP) end
    end
    if u and u:GetUnitType()==HERO then removeUnit(u) end
end
local function onPrekill(p,id,typ,x,y,delay,killer)
    if not isParadise(p) or removing then return end
    settleBirths(p)
    if typ==HERO then heroLost(p,Players[p]:GetUnitByID(id),killer) end
end
local function onCaptured(byP,byUnit,p,id,willKill,reason)
    if isParadise(p) then heroLost(p,Players[p]:GetUnitByID(id),byP) end
end
local function onGolden(p,start,duration)
    if not alive(p) then return end
    local s=state(p)
    if not truth(start) then s.golden=false;changed(p);return end
    if s.golden or s.finalGrant then return end
    s.golden=true
    achievement(p,'golden',Players[p]:GetCapitalCity())
end
local function onAlliance(minor,p,isAlly,oldFriend,newFriend)
    if not alive(p) then return end
    local s=state(p);local key=tostring(minor)
    if truth(isAlly) then
        if not s.alliances[key] then s.alliances[key]={since=s.clock} end
        if not s.distinctAllies[key] then
            s.distinctAllies[key]=true
            achievement(p,'alliance',nil)
        end
    else
        local previous=s.alliances[key];s.alliances[key]=nil
        if previous and s.clock-previous.since>=scaled(10) and s.act>=2
            and claim(p,'AllianceLoss|'..key) and eraClaim(p,'AllianceLoss') then
            pressure(p,12)
            memory(p,'allianceLoss|'..Players[p]:GetCurrentEra(),'A Friend Grows Distant','heartbreak',
                'A long friendship falters. Its loss asks for care, not an endless cycle of winning and losing.')
        end
    end
    refresh(p);changed(p) -- Persist alliance duration records even on a known ally's return.
end
local function finale(p,c)
    local s=state(p)
    if s.fulfilled then return end
    -- Commit the once-only state before synchronous GA/city/UI callbacks.
    s.fulfilled=true;s.pressure=0;s.challenge=nil;s.comebackDue=nil;s.finalGrant=true;s.story='FINAL'
    memory(p,'peak','The Final Peak','fulfillment',
        'The trophy completes a dream. It does not create the beauty that brought you here.',c:GetName())
    memory(p,'epilogue','The Dream Is Complete. The Beauty Remains.','epilogue',
        'There is nothing left to prove about the gift. There are still beautiful things to make.')
    persist(p);refresh(p)
    Players[p]:ChangeGoldenAgeTurns(scaled(15,'GoldenAgePercent'))
    s.golden=Players[p]:IsGoldenAge();s.finalGrant=false
    for city in Players[p]:Cities() do
        city:ChangeWeLoveTheKingDayCounter(scaled(3,'GoldenAgePercent'))
        notice(p,'The dream is complete. Your city celebrates with three scaled turns of We Love the King Day.',city)
    end
    changed(p);LuaEvents.ParadiseStory(p,'FINAL')
end
local function onConstructed(p,cityID,buildingID,gold,faith)
    if not alive(p) then return end
    local c=Players[p]:GetCityByID(cityID);local row=GameInfo.Buildings[buildingID]
    if not c or not row or truth(gold) or truth(faith) or (tonumber(row.Cost) or -1)<0 then return end
    local s=state(p);local r=s.cities[cityKey(c)]
    local order,item=c:GetOrderFromQueue(0)
    -- produce() increments this counter and retains the queue head through the hook.
    -- FreeStartEra/CreateBuilding/SetNumRealBuilding do not satisfy both proofs.
    if order~=OrderTypes.ORDER_CONSTRUCT or item~=buildingID or not r
        or c:GetNumThingsProduced()<=r.produced then return end
    local stamp=cityKey(c)..'|'..buildingID..'|'..c:GetNumThingsProduced()
    if not claim(p,'Constructed|'..stamp) then return end
    r.produced=c:GetNumThingsProduced()
    if buildingID==DANCE then
        if eligible(p) then finale(p,c) end
    elseif buildingID==POTRERO and claim(p,'PotreroBuilt|'..cityKey(c)) then
        s.potreroCities[cityKey(c)]=true;achievement(p,'potrero',c)
    else
        local class=GameInfo.BuildingClasses[row.BuildingClass]
        if class and (tonumber(class.MaxGlobalInstances) or -1)>0 and claim(p,'Wonder|'..row.BuildingClass) then
            achievement(p,'wonder',c)
        end
    end
    changed(p)
end
local function heartbreakCity(p,c,isCapital)
    local s=state(p)
    if s.act<2 or s.fulfilled or not claim(p,'CityLost|'..cityKey(c)) then return end
    local kind=isCapital and 'CapitalLoss' or 'CityLoss'
    if not eraClaim(p,kind) then return end
    pressure(p,isCapital and 25 or 15)
    memory(p,kind..'|'..Players[p]:GetCurrentEra(),isCapital and 'A Nation Falls Silent' or 'A City Beyond Reach',
        'heartbreak',isCapital and 'The first home has fallen. Even now, the gift and the dream belong to you.'
            or 'A familiar city is lost. The journey holds the sorrow without making it a source of rewards.',c:GetName())
end
local function onCapture(oldP,isCapital,x,y,newP,population,conquest)
    if not isParadise(oldP) and not isParadise(newP) then return end
    local plot=Map.GetPlot(x,y);local c=plot and plot:GetPlotCity()
    if not c then return end
    clearCity(c)
    if isParadise(oldP) then
        if truth(conquest) then heartbreakCity(oldP,c,truth(isCapital) or state(oldP).originalCapital==cityKey(c)) end
        state(oldP).cities[cityKey(c)]=nil
        refresh(oldP);changed(oldP)
    end
    if isParadise(newP) then
        state(newP).cities[cityKey(c)]={produced=c:GetNumThingsProduced()}
        refresh(newP);changed(newP)
    end
end
local function onFounded(p,x,y)
    if not alive(p) then return end
    local c=ownedCity(p,x,y)
    if c then state(p).cities[cityKey(c)]={produced=c:GetNumThingsProduced()} end
    ensureHero(p);transition(p);refresh(p);changed(p)
end
local function onMove(p,id,x,y)
    if not alive(p) then return end
    if id==state(p).heroID then refresh(p);changed(p) end
end
local function onTurn(p)
    if not alive(p) then return end
    local s=state(p)
    settleBirths(p);transition(p)
    if s.lastTurn~=turn() then
        s.lastTurn=turn();s.clock=s.clock+1
        ensureHero(p)
        if s.act==2 and not s.fulfilled then
            s.pressureTicks=(s.pressureTicks or 0)+1
            if s.pressureTicks>=scaled(3) then s.pressureTicks=0;pressure(p,1) end
        end
        local h=host(p) -- Presence Culture/GAP/GP generation all use native CP yields.
        if s.challenge then
            local q=s.challenge
            if s.clock>q.deadline then
                s.challenge=nil;s.comebackDue=s.clock+scaled(8)
                pressure(p,15)
                memory(p,'challengeFailure','The Long Way Home','heartbreak',
                    'The first chance has passed. Eight turns from now a new road will open; redemption is still possible.')
                notice(p,'Recovery deadline missed: +15 Pressure. Another opportunity opens after eight scaled owner turns.')
            elseif h and h:IsHasBuilding(POTRERO) then
                q.practice=q.practice+1
                if q.practice>=scaled(8) then recoverChallenge(p,turn(),s.clock,q.serial,h) end
            end
        elseif s.comebackDue and s.clock>=s.comebackDue and not s.recovered and not s.fulfilled then
            challenge(p)
            notice(p,'A new comeback opportunity: achieve a Great Person, Golden Age, World Wonder or new alliance, or inspire an El Potrero city for eight scaled owner turns.')
        end
    end
    for c in Players[p]:Cities() do
        local key=cityKey(c)
        s.cities[key]=s.cities[key] or {}
        s.cities[key].produced=c:GetNumThingsProduced()
        if s.cities[key].hopeUntil and s.cities[key].hopeUntil<=s.clock then s.cities[key].hopeUntil=nil end
    end
    refresh(p);changed(p)
end
local function candidates(p)
    local result={};local team=Teams[Players[p]:GetTeam()]
    for id=GameDefines.MAX_MAJOR_CIVS,GameDefines.MAX_CIV_PLAYERS-1 do
        local minor=Players[id]
        if minor and minor:IsMinorCiv() and minor:IsAlive() and team:IsHasMet(minor:GetTeam())
            and not team:IsAtWar(minor:GetTeam()) and not minor:IsMinorPermanentWar(Players[p]:GetTeam()) then
            local friendship=minor:GetMinorCivFriendshipWithMajor(p)
            if friendship>=0 then result[#result+1]={id=id,friendship=friendship} end
        end
    end
    table.sort(result,function(a,b)if a.friendship==b.friendship then return a.id<b.id end;return a.friendship<b.friendship end)
    return result
end
local function burst(c,era)
    local cap=250+100*era
    return math.max(10,math.min(cap,math.floor(c:GetYieldRateTimes100(I.YIELD_SCIENCE)*1.5/100))),
        math.max(10,math.min(cap,math.floor(c:GetYieldRateTimes100(I.YIELD_CULTURE)*1.5/100)))
end
function M.CanUseMagic(p,kind)
    if not alive(p) or Game.GetActivePlayer()~=p then return false,'Only the active human player can act.' end
    if not Players[p]:IsTurnActive() then return false,'Wait for your turn.' end
    if kind~='PASS' and kind~='HOPE' and kind~='BEAUTY' then return false,'Unknown Moment of Magic.' end
    if casting then return false,'A Moment of Magic is resolving.' end
    local s=state(p);local c=host(p)
    if not c then return false,'El Diez must stand in an owned city.' end
    if s.claims['MagicEra|'..Players[p]:GetCurrentEra()] then return false,'A Moment of Magic has already been used this era.' end
    if s.dreams<6 then return false,'Requires 6 Dreams.' end
    if kind=='PASS' and Players[p]:GetCurrentResearch()<0 then return false,'Choose a technology to research first.' end
    return true,'Ready in '..c:GetName()
end
function M.UseMagic(p,kind)
    local ok,reason=M.CanUseMagic(p,kind)
    if not ok then return false,reason end
    local s=state(p);local player=Players[p];local c=host(p);local era=player:GetCurrentEra()
    local science,culture=burst(c,era);local minors=kind=='BEAUTY' and candidates(p) or {}
    local tech=player:GetCurrentResearch()
    -- All native targets/requirements are checked above; reserve before reentrant native hooks.
    casting=true;s.dreams=s.dreams-6;s.claims['MagicEra|'..era]=true;persist(p)
    if kind=='PASS' then
        player:ChangeJONSCulture(culture)
        c:ChangeJONSCultureStored(culture)
        Teams[player:GetTeam()]:GetTeamTechs():ChangeResearchProgress(tech,science,p)
    elseif kind=='HOPE' then
        local key=cityKey(c);s.cities[key]=s.cities[key] or {produced=c:GetNumThingsProduced()}
        s.cities[key].hopeUntil=s.clock+scaled(8)
    else
        player:ChangeGoldenAgeProgressMeter(scaled(20+10*era,'GoldenAgePercent'))
        for index=1,math.min(2,#minors) do Players[minors[index].id]:ChangeMinorCivFriendshipWithMajor(p,10) end
    end
    casting=false
    memory(p,'magic|'..era,'A Moment of Genius','magic',
        ({PASS='He sees the open space before anyone else, and the whole city discovers a new possibility.',
            HOPE='In a difficult hour, one bright idea gives the city the strength to keep going.',
            BEAUTY='The beauty of the game travels farther than any border.'})[kind],c:GetName())
    notice(p,'-6 Dreams: '..({PASS='A Pass Nobody Saw',HOPE='When All Hope Was Lost',BEAUTY='The Beautiful Game'})[kind]
        ..'. Balance '..s.dreams..'; lifetime '..s.lifetime..'.',c)
    refresh(p);changed(p)
    return true,'A Moment of Magic.'
end
function M.GetUIState(p)
    if not isParadise(p) then return nil end
    local s=P.Copy(state(p));local c=alive(p) and host(p)
    s.era=Players[p]:GetCurrentEra();s.location=c and c:GetName() or 'Travelling'
    s.recoveryRemaining=s.recoveryDue>=0 and math.max(0,s.recoveryDue-s.clock) or -1
    s.objectives,s.objectiveCount=objectiveList(p);s.eligible=eligible(p)
    s.magic={};for _,kind in ipairs({'PASS','HOPE','BEAUTY'}) do
        local ok,reason=M.CanUseMagic(p,kind);s.magic[kind]={enabled=ok,reason=reason}
    end
    s.science,s.culture=10,10
    if c then s.science,s.culture=burst(c,s.era) end
    s.hopeTurns=scaled(8);s.beautyPoints=scaled(20+10*s.era,'GoldenAgePercent')
    s.finalTurns=scaled(15,'GoldenAgePercent');s.practiceTurns=scaled(8)
    return s
end
function M.AcknowledgeStory(p,kind)
    if not isParadise(p) or Game.GetActivePlayer()~=p then return end
    local s=state(p)
    if s.story==kind then s.story='' end
    if kind=='FINAL' and s.fulfilled then s.finalShown=true end
    changed(p)
end
local function canConstruct(p,cityID,id)
    if id~=DANCE then return true end
    return eligible(p) and Players[p]:GetCityByID(cityID)~=nil
end
local function canTrain(p,id) return id~=HERO end
local function canGift(p,minor,id)
    local u=Players[p] and Players[p]:GetUnitByID(id)
    return not u or u:GetUnitType()~=HERO
end
M.OnTurn=onTurn;M.OnCreated=onCreated;M.OnConstructed=onConstructed
M.OnGolden=onGolden;M.OnAlliance=onAlliance;M.OnPrekill=onPrekill
M.OnCapture=onCapture;M.CanConstruct=canConstruct;M.Scaled=scaled
GameEvents.PlayerDoTurn.Add(onTurn)
GameEvents.PlayerCityFounded.Add(onFounded)
GameEvents.UnitCreated.Add(onCreated)
GameEvents.CityTrained.Add(onTrained)
GameEvents.UnitPrekill.Add(onPrekill)
GameEvents.UnitCaptured.Add(onCaptured)
GameEvents.UnitConverted.Add(onConverted)
GameEvents.UnitSetXY.Add(onMove)
GameEvents.CityConstructed.Add(onConstructed)
GameEvents.CityCaptureComplete.Add(onCapture)
GameEvents.PlayerGoldenAge.Add(onGolden)
GameEvents.MinorAlliesChanged.Add(onAlliance)
GameEvents.CityCanConstruct.Add(canConstruct)
GameEvents.PlayerCanTrain.Add(canTrain)
GameEvents.PlayerCanGiftUnit.Add(canGift)
GameEvents.TeamTechResearched.Add(function(team,tech,change)
    for p=0,GameDefines.MAX_MAJOR_CIVS-1 do
        if alive(p) and Players[p]:GetTeam()==team then transition(p);refresh(p);changed(p) end
    end
end)
GameEvents.GreatWorkCreated.Add(function(p)
    if alive(p) then refresh(p);changed(p) end
end)
-- CapitalChanged is CP EVENTS_CITY_CAPITAL. Refresh only the affected civ.
GameEvents.CapitalChanged.Add(function(p,cityID,oldCityID)
    if alive(p) then refresh(p);changed(p) end
end)
for p=0,GameDefines.MAX_MAJOR_CIVS-1 do
    if isParadise(p) then
        local s=state(p)
        for c in Players[p]:Cities() do
            local key=cityKey(c)
            s.cities[key]=s.cities[key] or {produced=c:GetNumThingsProduced()}
        end
        -- Reconcile gameplay only; existence is never a source of Dreams.
        if alive(p) then ensureHero(p);transition(p);refresh(p);persist(p) end
    end
end
