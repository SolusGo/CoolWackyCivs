"""Focused deterministic checks for The Eternal Number Ten runtime."""
from __future__ import annotations

import re
import sys
from pathlib import Path
from xml.etree import ElementTree as ET

REPO = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO / ".tools" / "python"))


def static_checks() -> None:
    core = (REPO / "EternalNumberTen/SQL/00_Messi_Core.sql").read_text(encoding="utf-8-sig")
    runtime = (REPO / "EternalNumberTen/Lua/MessiRuntime.lua").read_text(encoding="utf-8-sig")
    panel = (REPO / "EternalNumberTen/UI/MessiLegacyPanel.lua").read_text(encoding="utf-8-sig")
    option_block = re.search(r"UPDATE\s+CustomModOptions.*?Name\s+IN\s*\((.*?)\);", core, re.I | re.S)
    assert option_block, "Missing Messi CustomModOptions update"
    options = set(re.findall(r"'([^']+)'", option_block.group(1)))
    expected_options = {
        "EVENTS_BATTLES", "EVENTS_CITY", "EVENTS_GOLDEN_AGE", "EVENTS_MINORS",
        "EVENTS_UNIT_CONVERTS", "EVENTS_UNIT_CREATED", "EVENTS_UNIT_PREKILL",
        "EVENTS_UNIT_UPGRADES",
    }
    assert options == expected_options, f"Wrong Messi CP event options: {options ^ expected_options}"
    assert "GameEvents.MinorAlliesChanged" in runtime, "Missing MinorAlliesChanged registration"
    assert "GameEvents.SetAlly" not in runtime, "Obsolete SetAlly registration remains"
    assert re.search(
        r"local function onUnitConverted\(oldPlayerID, newPlayerID, oldUnitID, newUnitID, isUpgrade\)",
        runtime,
    ), "UnitConverted handler does not use the documented five-argument signature"
    assert re.search(
        r"local function onCityCaptureComplete\(oldPlayerID, isCapital, x, y, newPlayerID, population, conquest\)",
        runtime,
    ), "CityCaptureComplete handler does not use the standard seven-argument signature"
    assert "state.legacy - state.epilogueBaseLegacy" in runtime, "Epilogue is not based on post-Chapter-VI Legacy"
    assert "include('MessiRuntime')" not in panel and 'include("MessiRuntime")' not in panel, (
        "Legacy panel still owns gameplay runtime initialization"
    )

    root = ET.parse(REPO / "CoolWackyCivs.civ5proj").getroot()
    namespace = root.tag.split("}")[0].strip("{")
    ns = {"m": namespace}
    entries = [
        node.text.replace("\\", "/")
        for node in root.findall(".//m:ModContent/m:Content/m:FileName", ns)
    ]
    runtime_entry = "EternalNumberTen/Lua/MessiRuntime.lua"
    panel_entry = "EternalNumberTen/UI/MessiLegacyPanel.xml"
    assert entries.count(runtime_entry) == 1 and entries.count(panel_entry) == 1, (
        "Runtime and Legacy panel must each have one independent InGameUIAddin entry"
    )
    assert entries.index(runtime_entry) < entries.index(panel_entry), "Runtime must initialize before the optional panel"
    print("PASS Eternal Number Ten static: CP options/signatures and independent runtime/UI add-ins")


def panel_without_runtime_check(LuaRuntime) -> None:
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute(r'''
MapModData={}
Players={[0]={}}
Game={GetActivePlayer=function()return 0 end}
Locale={ConvertTextKey=function(key,...)return key end}
GameInfo={Eras={}}
Mouse={eLClick=1}; KeyEvents={KeyDown=1}; Keys={VK_ESCAPE=27}
IconHookup=function()end
include=function(name)assert(name=='IconSupport','panel included gameplay runtime')end
local function control()
 local c={hidden=false}
 function c:RegisterCallback(...)end
 function c:SetHide(value)self.hidden=value end
 function c:SetText(value)self.text=value end
 return c
end
Controls=setmetatable({}, {__index=function(table,key)local value=control();rawset(table,key,value);return value end})
local function event()
 local value={}
 value.Add=function(handler)value.handler=handler end
 return value
end
LuaEvents={MessiLegacyChanged=event()}
Events={SerialEventGameDataDirty=event(),GameplaySetActivePlayer=event(),
 ActivePlayerTurnStart=event(),ActivePlayerTurnEnd=event()}
ContextPtr={}
function ContextPtr:SetInputHandler(handler)self.input=handler end
function ContextPtr:SetUpdate(handler)self.update=handler end
''')
    panel = (REPO / "EternalNumberTen/UI/MessiLegacyPanel.lua").read_text(encoding="utf-8-sig")
    lua.execute(panel)
    assert lua.eval("Controls.LauncherFrame.hidden") is True
    assert lua.eval("Controls.MainPanel.hidden") is True
    lua.execute(r'''
MapModData.MessiLegacy={GetUIState=function()return nil end}
Events.SerialEventGameDataDirty.handler()
ContextPtr.update(1)
assert(Controls.LauncherFrame.hidden and Controls.MainPanel.hidden)
''')
    print("PASS Eternal Number Ten panel: safe load before runtime initialization")


def main() -> None:
    from lupa.lua51 import LuaRuntime

    static_checks()
    panel_without_runtime_check(LuaRuntime)

    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute(r'''
MapModData={}
local saved={}
function SetSavedValue(k,v)saved[k]=v end
function GetSavedValue(k)return saved[k] end
Modding={OpenSaveData=function() return {
 GetValue=function(k)return saved[k] end,
 SetValue=function(k,v)saved[k]=v end,
} end}
GameInfoTypes={
 CIVILIZATION_ETERNAL_NUMBER_TEN=1, UNIT_MESSI_NUMBER_TEN=10,
 BUILDING_MESSI_LA_MASIA=20, IMPROVEMENT_MESSI_FOOTBALL_ACADEMY=30,
 BUILDING_MESSI_CAPITAL_SPECIALIST_SCIENCE=21, BUILDING_MESSI_LA_MASIA_SPECIALIST_FOOD=22,
 BUILDING_MESSI_LA_MASIA_PRODUCTION=23, BUILDING_MESSI_WORLD_WONDER_CULTURE=24,
 BUILDING_MESSI_RESILIENCE_PRODUCTION=25, BUILDING_MESSI_ALLIED_CITY_STATE=26,
 BUILDING_MESSI_ACADEMY_GOLD=27, PROMOTION_MESSI_ONE_TWO=40,
 PROMOTION_MESSI_ONE_TWO_CHAPTER_3=41, PROMOTION_MESSI_VISION=42,
 PROMOTION_MESSI_CAPITAL_VISION=43, PROMOTION_MESSI_RESILIENCE=44,
 TECH_THEOLOGY=50, UNITCLASS_SCOUT=60,
 ERA_CLASSICAL=1,ERA_RENAISSANCE=3,ERA_INDUSTRIAL=4,ERA_MODERN=5,ERA_ATOMIC=6,
}
for i=1,6 do
 GameInfoTypes['POLICY_MESSI_CHAPTER_'..i]=100+i
 GameInfoTypes['POLICY_MESSI_EPILOGUE_'..i]=110+i
end
GameDefines={MAX_MAJOR_CIVS=2,MAX_CIV_PLAYERS=4,NUM_CITY_PLOTS=7}
DirectionTypes={NUM_DIRECTION_TYPES=6}; DomainTypes={DOMAIN_LAND=0}
NotificationTypes={NOTIFICATION_GENERIC=0}; MinorCivQuestTypes={NUM_MINOR_CIV_QUEST_TYPES=4}
Locale={ConvertTextKey=function(k,...)return k end}

local function event()
 local e={handlers={}}
 e.Add=function(f)e.handlers[#e.handlers+1]=f end
 return e
end
GameEvents={}
for _,name in ipairs({'PlayerDoTurn','PlayerCityFounded','CityTrained','CityConstructed','CityCaptureComplete',
 'UnitCreated','UnitPrekill','UnitConverted','UnitUpgraded','TeamTechResearched','PlayerGoldenAge','MinorAlliesChanged',
 'BattleStarted','BattleJoined','BattleFinished'}) do GameEvents[name]=event() end
LuaEvents={}
LuaEvents.MessiLegacyChanged=setmetatable({handlers={},Add=function(self,f)self.handlers[#self.handlers+1]=f end},
 {__call=function(self,...)for _,f in ipairs(self.handlers)do f(...)end end})

local function info(rows)
 local byID={}
 for _,row in ipairs(rows) do byID[row.ID]=row; if row.Type then byID[row.Type]=row end end
 return setmetatable(byID,{__call=function()local i=0;return function()i=i+1;return rows[i]end end})
end
GameInfo={}
GameInfo.Specialists=info({{ID=1,Type='SPECIALIST_SCIENTIST'},{ID=2,Type='SPECIALIST_CITIZEN'}})
GameInfo.BuildingClasses=info({{ID=1,Type='BUILDINGCLASS_LIBRARY',MaxGlobalInstances=-1},
 {ID=2,Type='BUILDINGCLASS_WONDER',MaxGlobalInstances=1},{ID=3,Type='BUILDINGCLASS_GARDEN',MaxGlobalInstances=-1}})
GameInfo.Buildings=info({{ID=70,Type='BUILDING_LIBRARY',BuildingClass='BUILDINGCLASS_LIBRARY',SpecialistCount=2},
 {ID=71,Type='BUILDING_WONDER',BuildingClass='BUILDINGCLASS_WONDER',SpecialistCount=0},
 {ID=20,Type='BUILDING_MESSI_LA_MASIA',BuildingClass='BUILDINGCLASS_GARDEN',SpecialistCount=0}})
GameInfo.Units=info({{ID=10,Type='UNIT_MESSI_NUMBER_TEN',Class='UNITCLASS_GREAT_GENERAL',Special='SPECIALUNIT_PEOPLE',Combat=0,RangedCombat=0},
 {ID=80,Type='UNIT_INFANTRY',Class='UNITCLASS_INFANTRY',Combat=20,RangedCombat=0},
 {ID=81,Type='UNIT_SCIENTIST',Class='UNITCLASS_GREAT_SCIENTIST',Special='SPECIALUNIT_PEOPLE',Combat=0,RangedCombat=0}})
GameInfo.Eras=info({{ID=6,Type='ERA_ATOMIC',Description='Atomic Era'}})

local turn=100
Game={GetGameTurn=function()return turn end}
function SetTurn(value)turn=value end
local plots={}; local offsets={{1,0},{1,1},{0,1},{-1,0},{-1,-1},{0,-1}}
local function pkey(x,y)return x..':'..y end
function NewPlot(x,y)
 local p={x=x,y=y,units={},improvement=-1,working=nil,city=nil}
 function p:GetX()return self.x end; function p:GetY()return self.y end
 function p:GetNumUnits()return #self.units end; function p:GetUnit(i)return self.units[i+1] end
 function p:GetImprovementType()return self.improvement end; function p:GetWorkingCity()return self.working end
 function p:GetPlotIndex()return self.x*100+self.y end; function p:GetPlotCity()return self.city end
 plots[pkey(x,y)]=p; return p
end
Map={GetPlot=function(x,y)return plots[pkey(x,y)] end,
 PlotDirection=function(x,y,d)local o=offsets[d+1];return plots[pkey(x+o[1],y+o[2])] end}
for x=-2,2 do for y=-2,2 do NewPlot(x,y) end end

function NewCity(owner,id,x,y)
 local c={owner=owner,id=id,x=x,y=y,buildings={[20]=1,[70]=1,[71]=1},specialists={[1]=3},food=0,wltkd=0}
 function c:GetID()return self.id end; function c:GetX()return self.x end; function c:GetY()return self.y end
 function c:IsCapital()return self.id==1 end
 function c:GetNumRealBuilding(i)return self.buildings[i] or 0 end
 function c:IsHasBuilding(i)return (self.buildings[i] or 0)>0 end
 function c:SetNumRealBuilding(i,n)self.buildings[i]=n end
 function c:GetSpecialistCount(i)return self.specialists[i] or 0 end
 function c:GetCityIndexPlot(i)return ({plots[pkey(x,y)],plots[pkey(x+1,y)],plots[pkey(x,y+1)],plots[pkey(x-1,y)],plots[pkey(x,y-1)]})[i+1] end
 function c:ChangeFood(n)self.food=self.food+n end
 function c:ChangeWeLoveTheKingDayCounter(n)self.wltkd=self.wltkd+n end
 plots[pkey(x,y)].city=c; plots[pkey(x,y)].working=c
 return c
end
local nextUnit=0
function NewUnit(owner,kind,x,y,military)
 nextUnit=nextUnit+1
 local u={owner=owner,id=nextUnit,kind=kind,x=x,y=y,military=military,promotions={},promotionChanges=0,damage=20,xp=0}
 function u:GetOwner()return self.owner end; function u:GetID()return self.id end
 function u:GetUnitType()return self.kind end; function u:GetPlot()return plots[pkey(self.x,self.y)] end
 function u:IsCombatUnit()return self.military end; function u:GetDomainType()return 0 end
 function u:IsHasPromotion(p)return self.promotions[p]==true end
 function u:SetHasPromotion(p,v)self.promotions[p]=v;self.promotionChanges=self.promotionChanges+1 end
 function u:ChangeDamage(n)self.damage=math.max(0,self.damage+n) end; function u:GetDamage()return self.damage end
 function u:ChangeExperience(n)self.xp=self.xp+n end
 plots[pkey(x,y)].units[#plots[pkey(x,y)].units+1]=u
 return u
end
function NewPlayer(id,civ,minor)
 local p={id=id,civ=civ,minor=minor or false,alive=true,era=6,team=id,cityList={},unitList={},policies={},culture=0,gap=0,golden=false,goldenTurns=0,freePolicies=0,ally=-1,notifications={}}
 function p:GetID()return self.id end; function p:IsAlive()return self.alive end
 function p:IsMinorCiv()return self.minor end; function p:GetCivilizationType()return self.civ end
 function p:GetCurrentEra()return self.era end; function p:GetTeam()return self.team end
 function p:GetCapitalCity()return self.cityList[1] end
 function p:GetCityByID(id)for _,c in ipairs(self.cityList)do if c.id==id then return c end end end
 function p:GetUnitByID(id)for _,u in ipairs(self.unitList)do if u.id==id then return u end end end
 function p:Cities()local i=0;return function()i=i+1;return self.cityList[i]end end
 function p:Units()local i=0;return function()i=i+1;return self.unitList[i]end end
 function p:HasPolicy(i)return self.policies[i]==true end; function p:SetHasPolicy(i,v)self.policies[i]=v end
 function p:IsGoldenAge()return self.golden end; function p:GetGoldenAgeTurns()return self.goldenTurns end
 function p:ChangeGoldenAgeTurns(n)self.goldenTurns=self.goldenTurns+n;self.golden=self.goldenTurns>0 end
 function p:ChangeNumFreePolicies(n)self.freePolicies=self.freePolicies+n end
 function p:ChangeJONSCulture(n)self.culture=self.culture+n end
 function p:ChangeGoldenAgeProgressMeter(n)self.gap=self.gap+n end
 function p:IsHuman()return self.id==0 end
 function p:AddNotification(...)self.notifications[#self.notifications+1]={...} end
 function p:GetAlly()return self.ally end
 function p:GetMinorCivNumDisplayedQuestsForPlayer()return 0 end
 function p:GetMinorCivFriendshipWithMajor()return 0 end
 return p
end
Players={}
Players[0]=NewPlayer(0,1,false); Players[1]=NewPlayer(1,99,false)
Players[2]=NewPlayer(2,98,true); Players[3]=NewPlayer(3,97,true)
Players[0].era=5
Teams={}
for i=0,3 do Teams[i]={tech=true,IsHasTech=function(self,t)return self.tech end} end
local city=NewCity(0,1,0,0); Players[0].cityList={city}
local killer=NewUnit(0,80,0,0,true); local support1=NewUnit(0,80,1,0,true); local support2=NewUnit(0,80,0,1,true); local general=NewUnit(0,10,-1,0,false)
Players[0].unitList={killer,support1,support2,general}
local victim=NewUnit(1,80,1,1,true); Players[1].unitList={victim}
''')
    source = (REPO / "EternalNumberTen/Lua/MessiRuntime.lua").read_text(encoding="utf-8-sig")
    lua.execute(source)
    lua.execute(source)
    lua.execute(r'''
local M=MapModData.MessiLegacy
local p=Players[0]; local city=p.cityList[1]; local killer=p.unitList[1]
for name,event in pairs(GameEvents) do
 assert(#event.handlers==1,'handler missing or duplicated: '..name)
end
assert(GameEvents.SetAlly==nil,'obsolete SetAlly mock or handler remains')
local captureRefreshes=0
LuaEvents.MessiLegacyChanged:Add(function(playerID)if playerID==0 then captureRefreshes=captureRefreshes+1 end end)
local capture=GameEvents.CityCaptureComplete.handlers[1]
local beforeCapture=captureRefreshes
capture(0,false,0,0,1,5,true)
assert(captureRefreshes==beforeCapture+1,'Messi old owner was not refreshed after non-capital capture')
beforeCapture=captureRefreshes
capture(0,true,0,0,1,5,true)
assert(captureRefreshes==beforeCapture+1,'capital flag was mistaken for the old owner')
beforeCapture=captureRefreshes
capture(1,false,0,0,0,5,true)
assert(captureRefreshes==beforeCapture+1,'Messi new owner was not refreshed after capture')
beforeCapture=captureRefreshes
capture(1,false,0,0,3,5,true)
assert(captureRefreshes==beforeCapture,'capture without a Messi owner caused a Messi refresh')

M.ChangeMessiLegacy(0,350,'test')
local state=M.GetState(0)
for i=1,5 do assert(state.unlocked[i] and p.policies[100+i],'chapter '..i..' not unlocked') end
assert(not state.unlocked[6] and state.epilogue==0 and state.tourism==0,'Chapter VI or Epilogue ignored its Era gate')
assert(state.epilogueBaseLegacy==nil and GetSavedValue('Messi|0|EpilogueBaseLegacy')==nil,'Epilogue baseline was created before Chapter VI')
p.era=6; M.CheckChapters(0)
assert(state.unlocked[6] and p.policies[106],'Chapter VI did not unlock in Atomic Era')
assert(state.epilogueBaseLegacy==350 and GetSavedValue('Messi|0|EpilogueBaseLegacy')==350,'Chapter VI baseline is incorrect')
assert(state.epilogue==0 and state.tourism==0,'banked pre-Chapter-VI Legacy granted retroactive Epilogue rewards')
assert(p.goldenTurns==6 and p.freePolicies==1 and city.wltkd==3,'Chapter VI one-time rewards incorrect')
for i=1,3 do assert(p.unitList[i].xp==8,'military XP missing') end
assert(p.unitList[4].damage==0,'Number Ten was not fully healed')
assert(city.buildings[22]==1 and city.buildings[21]==3 and city.buildings[24]==1,'specialist or wonder dummies incorrect')

M.ChangeMessiLegacy(0,54,'test')
assert(state.epilogue==0 and state.tourism==0,'Epilogue triggered before 55 post-unlock Legacy')
M.ChangeMessiLegacy(0,1,'test')
assert(state.epilogue==1 and state.tourism==1,'first post-unlock Epilogue reward is incorrect')
M.ChangeMessiLegacy(0,55,'test')
assert(state.epilogue==2 and state.tourism==2,'second post-unlock Epilogue reward is incorrect')
local cultureAtTwo, goldenAtTwo=p.culture,p.goldenTurns
M.ChangeMessiLegacy(0,55*5,'test')
assert(state.epilogue==7 and state.tourism==6,'Epilogue count or Tourism cap is incorrect')
assert(p.culture==cultureAtTwo+(5*15*7) and p.goldenTurns==goldenAtTwo+10,'post-cap Epilogue rewards did not continue')
for i=1,6 do assert(p.policies[110+i],'Epilogue Tourism policy missing') end

assert((city.buildings[27] or 0)==0,'Academy Gold should start at zero')
Map.GetPlot(1,0).improvement=30; Map.GetPlot(1,0).working=city
M.RefreshPlayer(0,false)
assert(city.buildings[27]==1,'one worked Football Academy should grant one Academy Gold')
Map.GetPlot(0,1).improvement=30; Map.GetPlot(0,1).working=city
M.RefreshPlayer(0,false)
assert(city.buildings[27]==2,'Academy Gold must count Academies, not adjacent tiles')

state.golden=p.golden
M.OnPlayerDoTurn(0)
assert(killer:IsHasPromotion(40) and killer:IsHasPromotion(41),'Passing Triangles missing')
assert(killer:IsHasPromotion(42),'Vision Beyond the Defence missing')

local beforeAlliance=state.legacy
Players[2].ally=0
M.OnMinorAlliesChanged(2,0,true,0,60)
assert(state.legacy==beforeAlliance+3,'first alliance did not grant three Legacy')
M.OnMinorAlliesChanged(2,0,true,60,61)
assert(state.legacy==beforeAlliance+3,'duplicate alliance event granted Legacy twice')
M.OnPlayerDoTurn(0)
assert(state.legacy==beforeAlliance+3,'alliance fallback duplicated the event reward')
Players[2].ally=-1
M.OnMinorAlliesChanged(2,0,false,60,0)
assert(state.resilienceEnd==104 and state.resilienceNext==122,'alliance loss did not activate Resilience')
M.OnPlayerDoTurn(0)
assert(state.resilienceEnd==104 and state.resilienceNext==122,'alliance fallback duplicated Resilience activation')
Players[2].ally=0
M.OnMinorAlliesChanged(2,0,true,0,60)
assert(state.legacy==beforeAlliance+3,'same-era alliance regain granted Legacy twice')

local converted=NewUnit(0,80,-1,-1,true); p.unitList[#p.unitList+1]=converted
GameEvents.UnitConverted.handlers[1](1,0,999,converted:GetID(),false)
assert(converted:IsHasPromotion(44),'converted unit did not receive active Resilience')
local conversionChanges=converted.promotionChanges
GameEvents.UnitUpgraded.handlers[1](0,999,converted:GetID(),false)
assert(converted.promotionChanges==conversionChanges,'conversion and upgrade refreshes were not idempotent')
local departed=NewUnit(1,80,-1,-1,true); Players[1].unitList[#Players[1].unitList+1]=departed
for _,promotion in ipairs({40,41,42,44}) do departed:SetHasPromotion(promotion,true) end
GameEvents.UnitConverted.handlers[1](0,1,999,departed:GetID(),false)
for _,promotion in ipairs({40,41,42,44}) do assert(not departed:IsHasPromotion(promotion),'departing unit kept Messi promotion '..promotion) end

local beforeLegacy=state.legacy
local beforeCulture, beforeGap=p.culture,p.gap
M.OnBattleStarted(0,1,1); M.OnBattleJoined(0,killer:GetID(),0,false); M.OnBattleJoined(1,Players[1].unitList[1]:GetID(),1,false)
M.OnUnitPrekill(1,Players[1].unitList[1]:GetID(),80,1,1,false,0)
M.OnBattleFinished()
assert(state.legacy==beforeLegacy+1 and p.culture==beforeCulture+3 and p.gap==beforeGap+3,'Assist reward incorrect')
assert(killer.damage==15,'Vision Assist healing incorrect')

assert(not M.ActivateResilience(0,'repeat'),'Resilience ignored cooldown')
M.RefreshPlayer(0,false)
assert(city.buildings[25]==1 and killer:IsHasPromotion(44),'Resilience effects missing')

local gp=NewUnit(0,81,0,0,false); p.unitList[#p.unitList+1]=gp
local beforeGP=state.legacy; M.OnUnitCreated(0,gp:GetID())
assert(state.legacy==beforeGP+3 and city.wltkd==4 and city.buildings[23]==1,'La Masia Great Person trigger incorrect')

Players[1].civ=1
SetSavedValue('Messi|1|Legacy',570)
SetSavedValue('Messi|1|EpilogueCount',4)
SetSavedValue('Messi|1|EpilogueTourism',4)
for i=1,6 do SetSavedValue('Messi|1|Chapter'..i,1) end
local migrated=M.GetState(1)
assert(migrated.epilogueBaseLegacy==350 and GetSavedValue('Messi|1|EpilogueBaseLegacy')==350,'old-save Epilogue baseline migration is incorrect')
local oldCulture,oldGolden=Players[1].culture,Players[1].goldenTurns
M.CheckChapters(1)
assert(migrated.epilogue==4 and Players[1].culture==oldCulture and Players[1].goldenTurns==oldGolden,'old save replayed Epilogue rewards during migration')
M.ChangeMessiLegacy(1,54,'test')
assert(migrated.epilogue==4,'migrated Epilogue triggered before another 55 Legacy')
M.ChangeMessiLegacy(1,1,'test')
assert(migrated.epilogue==5 and Players[1].culture==oldCulture+105 and Players[1].goldenTurns==oldGolden+2,'migrated Epilogue cadence is incorrect')

SetTurn(104); M.OnPlayerDoTurn(0)
assert(city.buildings[25]==0 and not killer:IsHasPromotion(44),'Resilience did not expire')
print('PASS Eternal Number Ten runtime: capture, Epilogue baseline/migration, chapters, Academies, alliances, conversions, formation, Assists, Resilience, La Masia')
''')


if __name__ == "__main__":
    main()
