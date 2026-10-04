"""Focused SQL, packaging, art, and Lua behavior checks for Masaya Hinata."""
from __future__ import annotations

import argparse
import sqlite3
import struct
import sys
from collections import Counter
from pathlib import Path
from xml.etree import ElementTree as ET

REPO = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO / ".tools" / "python"))
sys.path.insert(0, str(REPO / "tools"))

from build_mod import NS, read_project
from validate_mod import apply_current_cp_schema, quote

ROOT = REPO / "MasayaBeyondSky"


def database_checks(path: Path, cp_root: Path) -> None:
    source = sqlite3.connect(path.resolve().as_uri() + "?mode=ro", uri=True)
    database = sqlite3.connect(":memory:")
    source.backup(database)
    source.close()
    database.row_factory = sqlite3.Row
    apply_current_cp_schema(database, cp_root)
    database.execute("CREATE TABLE IF NOT EXISTS Language_en_US (Tag TEXT PRIMARY KEY, Text TEXT)")

    # A cache made while an earlier development copy was enabled is safe to use.
    for table_row in database.execute(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"
    ).fetchall():
        table = table_row[0]
        columns = [row[1] for row in database.execute(f"PRAGMA table_info({quote(table)})")]
        predicate = " OR ".join(
            f"INSTR(CAST({quote(column)} AS TEXT), 'MASAYA_KID') > 0" for column in columns
        )
        if predicate:
            try:
                database.execute(f"DELETE FROM {quote(table)} WHERE {predicate}")
            except sqlite3.OperationalError:
                pass

    for sql in (
        "00_Masaya_Core.sql", "01_Masaya_Inheritance.sql",
        "02_Masaya_UniqueEffects.sql", "10_Masaya_Text.sql",
    ):
        database.executescript((ROOT / "SQL" / sql).read_text(encoding="utf-8-sig"))

    def row(table: str, type_name: str):
        result = database.execute(
            f"SELECT * FROM {quote(table)} WHERE Type=?", (type_name,)
        ).fetchone()
        assert result is not None, f"Missing {type_name}"
        return result

    horseman = row("Units", "UNIT_HORSEMAN")
    prodigy = row("Units", "UNIT_MASAYA_KID_FC_PRODIGY")
    expected_cost = int(((horseman["Cost"] * 1.10 + 2.5) / 5)) * 5
    assert (prodigy["Combat"], prodigy["Moves"], prodigy["Cost"]) == (12, 5, expected_cost)
    for field in ("Class", "PrereqTech", "ObsoleteTech", "Domain", "DefaultUnitAI", "CombatClass"):
        assert prodigy[field] == horseman[field], f"Prodigy lost inherited {field}"
    horse_resources = list(database.execute(
        "SELECT ResourceType,Cost FROM Unit_ResourceQuantityRequirements WHERE UnitType='UNIT_HORSEMAN'"
    ))
    prodigy_resources = list(database.execute(
        "SELECT ResourceType,Cost FROM Unit_ResourceQuantityRequirements WHERE UnitType='UNIT_MASAYA_KID_FC_PRODIGY'"
    ))
    assert prodigy_resources == horse_resources and horse_resources, "Horse requirement was not inherited"

    barracks = row("Buildings", "BUILDING_BARRACKS")
    room = row("Buildings", "BUILDING_MASAYA_KID_GRAV_ROOM")
    for field in ("BuildingClass", "PrereqTech", "Cost", "GoldMaintenance"):
        assert room[field] == barracks[field], f"Practice Room lost inherited {field}"
    base_xp = dict(database.execute(
        "SELECT DomainType,Experience FROM Building_DomainFreeExperiences WHERE BuildingType='BUILDING_BARRACKS'"
    ))
    room_xp = dict(database.execute(
        "SELECT DomainType,Experience FROM Building_DomainFreeExperiences WHERE BuildingType='BUILDING_MASAYA_KID_GRAV_ROOM'"
    ))
    assert room_xp == base_xp and all(value == 15 for value in room_xp.values())
    yields = dict(database.execute(
        "SELECT YieldType,Yield FROM Building_YieldChanges WHERE BuildingType='BUILDING_MASAYA_KID_GRAV_ROOM'"
    ))
    assert yields["YIELD_CULTURE"] == 1 and yields["YIELD_SCIENCE"] == 1

    inherent = row("UnitPromotions", "PROMOTION_MASAYA_KID_PRODIGY_INHERENT")
    assert (inherent["IgnoreTerrainCost"], inherent["CanMoveAfterAttacking"],
            inherent["River"], inherent["CityAttack"]) == (1, 1, 1, 0)
    beyond = row("UnitPromotions", "PROMOTION_MASAYA_KID_BEYOND_SKY")
    assert (beyond["MovesChange"], beyond["IgnoreTerrainCost"], beyond["AttackMod"],
            beyond["ExperiencePercent"], beyond["River"]) == (1, 1, 15, 50, 1)
    assert row("UnitPromotions", "PROMOTION_MASAYA_KID_CANT_STOP_XP")["ExperiencePercent"] == 10
    assert row("UnitPromotions", "PROMOTION_MASAYA_KID_PRODIGY_ZOC")["IgnoreZOC"] == 1
    assert row("UnitPromotions", "PROMOTION_MASAYA_KID_NATURAL_XP_15")["CombatPercent"] == 15
    assert row("UnitPromotions", "PROMOTION_MASAYA_KID_NATURAL_LEVEL_10")["CombatPercent"] == 10
    free_promotions = {result[0] for result in database.execute(
        "SELECT PromotionType FROM Unit_FreePromotions WHERE UnitType='UNIT_MASAYA_KID_FC_PRODIGY'"
    )}
    assert {
        "PROMOTION_MASAYA_KID_PRODIGY_INHERENT",
        "PROMOTION_MASAYA_KID_JUST_ONE_MORE_FLIGHT",
        "PROMOTION_MASAYA_KID_NATURAL_PRODIGY",
    } <= free_promotions
    city_penalties = [tuple(result) for result in database.execute(
        "SELECT ufp.PromotionType,up.CityAttack FROM Unit_FreePromotions ufp "
        "JOIN UnitPromotions up ON up.Type=ufp.PromotionType "
        "WHERE ufp.UnitType='UNIT_MASAYA_KID_FC_PRODIGY' AND up.CityAttack<>0"
    )]
    assert city_penalties == [("PROMOTION_CITY_PENALTY", -33)], (
        f"Prodigy city penalty must be inherited exactly once: {city_penalties}"
    )

    tables = [result[0] for result in database.execute(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"
    )]

    def companion_subset(key: str, base_type: str, unique_type: str, scalar: str,
                         skip: set[str] | None = None) -> None:
        skip = skip or set()
        for table in tables:
            if table == scalar or table in skip:
                continue
            columns = [result[1] for result in database.execute(f"PRAGMA table_info({quote(table)})")]
            if key not in columns:
                continue
            try:
                base_rows = database.execute(
                    f"SELECT * FROM {quote(table)} WHERE {quote(key)}=?", (base_type,)
                ).fetchall()
                unique_rows = database.execute(
                    f"SELECT * FROM {quote(table)} WHERE {quote(key)}=?", (unique_type,)
                ).fetchall()
            except sqlite3.OperationalError:
                continue
            if not base_rows:
                continue
            compared = [column for column in columns if column.lower() != "id"]
            expected = Counter(tuple(unique_type if column == key else item[column]
                                     for column in compared) for item in base_rows)
            actual = Counter(tuple(item[column] for column in compared) for item in unique_rows)
            assert not (expected - actual), f"{unique_type} lost rows from {table}"

    companion_subset("UnitType", "UNIT_HORSEMAN", "UNIT_MASAYA_KID_FC_PRODIGY", "Units",
                     {"Unit_FreePromotions"})
    companion_subset("BuildingType", "BUILDING_BARRACKS", "BUILDING_MASAYA_KID_GRAV_ROOM",
                     "Buildings", {"Building_YieldChanges"})

    assert database.execute(
        "SELECT COUNT(*) FROM Civilization_Start_Along_Ocean "
        "WHERE CivilizationType='CIVILIZATION_MASAYA_KID' AND StartAlongOcean=1"
    ).fetchone()[0] == 1
    assert database.execute(
        "SELECT Value FROM CustomModOptions WHERE Name='EVENTS_UNIT_UPGRADES'"
    ).fetchone()[0] == 1
    translated = {result[0] for result in database.execute("SELECT Tag FROM Language_en_US")}
    unresolved = set()
    for table in ("Civilizations", "Leaders", "Units", "Buildings", "UnitPromotions", "Traits"):
        for item in database.execute(
            f"SELECT * FROM {quote(table)} WHERE INSTR(Type,'MASAYA_KID') > 0"
        ):
            for field in ("Description", "ShortDescription", "Adjective", "Civilopedia",
                          "Strategy", "Help", "DawnOfManQuote"):
                if field in item.keys() and isinstance(item[field], str) \
                        and item[field].startswith("TXT_KEY_") and item[field] not in translated:
                    unresolved.add(item[field])
    assert not unresolved, f"Missing localization: {sorted(unresolved)}"

    atlas_expectations = {
        "MASAYA_KID_ICON_ATLAS": (2, (256,128,80,64,48,45,32,24,16), "MasayaIcon"),
        "MASAYA_KID_ALPHA_ATLAS": (1, (256,128,80,64,48,45,32,24,16), "MasayaAlpha"),
        "MASAYA_KID_OBJECT_ATLAS": (9, (256,128,80,64,45,32,16), "MasayaObjects"),
        "MASAYA_KID_UNIT_FLAG_ATLAS": (1, (32,), "MasayaUnitFlag"),
    }
    for atlas, (columns, sizes, stem) in atlas_expectations.items():
        actual = {int(result["IconSize"]): (result["Filename"], int(result["IconsPerRow"]))
                  for result in database.execute(
                      "SELECT * FROM IconTextureAtlases WHERE Atlas=?", (atlas,))}
        expected = {size: (f"{stem}{size}.dds", columns) for size in sizes}
        assert actual == expected, f"Wrong {atlas}: {actual} != {expected}"
    assert database.execute("PRAGMA integrity_check").fetchone()[0] == "ok"
    database.close()
    print("PASS Masaya SQL: active-rule inheritance, stats, promotions, atlases, and localization")


def package_and_art_checks() -> None:
    _, props, _, files = read_project()
    project = {name: imported for name, imported in files}
    shipped = {
        path.relative_to(REPO).as_posix()
        for path in ROOT.rglob("*")
        if path.is_file() and path.suffix.lower() in {".sql", ".lua", ".xml", ".dds"}
    }
    assert shipped <= set(project), f"Masaya files missing from project: {shipped - set(project)}"
    for name in shipped:
        assert project[name] == (not name.endswith(".sql") and not name.endswith("Panel.xml"))
    actions = [node.text.replace("\\", "/") for node in
               props.findall("m:ModActions/m:Action/m:FileName", NS)]
    assert [name for name in actions if name.startswith("MasayaBeyondSky/")] == [
        "MasayaBeyondSky/SQL/00_Masaya_Core.sql",
        "MasayaBeyondSky/SQL/01_Masaya_Inheritance.sql",
        "MasayaBeyondSky/SQL/02_Masaya_UniqueEffects.sql",
        "MasayaBeyondSky/SQL/10_Masaya_Text.sql",
    ]
    entries = [node.text.replace("\\", "/") for node in
               props.findall("m:ModContent/m:Content/m:FileName", NS)]
    assert [name for name in entries if name.startswith("MasayaBeyondSky/")] == ["MasayaBeyondSky/Lua/MasayaRuntime.lua",
                            "MasayaBeyondSky/UI/MasayaJoyPanel.xml"]

    from PIL import Image
    for path in sorted((ROOT / "Art").glob("*.dds")):
        header = path.read_bytes()[:128]
        assert len(header) == 128 and header[:4] == b"DDS "
        height, width = struct.unpack_from("<II", header, 12)
        expected = b"DXT5" if width % 4 == 0 and height % 4 == 0 else b"\0\0\0\0"
        assert header[84:88] == expected, f"Bad Civ V DDS encoding: {path.name}"
        with Image.open(path) as texture:
            texture.load()
            assert texture.size == (width, height)
    for name in ("MasayaLeader.dds", "MasayaDawn.dds"):
        with Image.open(ROOT / "Art" / name) as image:
            assert image.size == (1600, 900)
    with Image.open(ROOT / "Art" / "MasayaMap.dds") as image:
        assert image.size == (360, 412)
    panel_root = ET.parse(ROOT / "UI/MasayaJoyPanel.xml").getroot()
    ids = {element.attrib["ID"] for element in panel_root.iter() if "ID" in element.attrib}
    assert {"JoyFrame", "JoyIcon", "JoyLabel", "StateLabel", *{f"Fill{i}" for i in range(1,11)}} <= ids
    runtime_source = (ROOT / "Lua/MasayaRuntime.lua").read_text(encoding="utf-8-sig")
    panel_source = (ROOT / "UI/MasayaJoyPanel.lua").read_text(encoding="utf-8-sig")
    assert 'include("MasayaRuntime")' not in panel_source
    assert "GameEvents." not in panel_source, "UI must not own gameplay event handlers"
    assert "M.RuntimeLoaded" not in runtime_source
    assert "__MASAYA_KID_RUNTIME_CONTEXT_LOADED" in runtime_source
    assert "MapModData.MasayaKid = {}" in runtime_source
    print(f"PASS Masaya packaging/art: {len(shipped)} shipped files and {len(list((ROOT/'Art').glob('*.dds')))} DDS textures")


def lua_behavior_checks() -> None:
    from lupa.lua51 import LuaRuntime

    lua = LuaRuntime(unpack_returned_tuples=True)
    source = (ROOT / "Lua/MasayaRuntime.lua").read_text(encoding="utf-8-sig")
    compile_lua = lua.eval("function(s) local f,e=loadstring(s); return f~=nil,e end")
    passed, message = compile_lua(source)
    assert passed, message
    lua.execute(r'''
MapModData={MasayaKid={RuntimeLoaded=true}}; saved={}
Modding={OpenSaveData=function()return {GetValue=function(k)return saved[k] end,
 SetValue=function(k,v)saved[k]=v end}end}
GameInfoTypes={CIVILIZATION_MASAYA_KID=1,UNIT_MASAYA_KID_FC_PRODIGY=10,
 BUILDING_MASAYA_KID_GRAV_ROOM=20,PROMOTION_MASAYA_KID_PRODIGY_INHERENT=30,
 PROMOTION_MASAYA_KID_JUST_ONE_MORE_FLIGHT=31,PROMOTION_MASAYA_KID_NATURAL_PRODIGY=32,
 PROMOTION_MASAYA_KID_CANT_PUT_THEM_DOWN=33,PROMOTION_MASAYA_KID_CANT_PUT_ACTIVE=34,
 PROMOTION_MASAYA_KID_CANT_STOP_XP=35,PROMOTION_MASAYA_KID_CANT_STOP_MOVE=36,
 PROMOTION_MASAYA_KID_BEYOND_SKY=37,PROMOTION_MASAYA_KID_PRODIGY_ZOC=38,
 PROMOTION_MASAYA_KID_NATURAL_XP_15=39,PROMOTION_MASAYA_KID_NATURAL_LEVEL_10=40,
 UNITCOMBAT_RECON=50,UNITCOMBAT_MOUNTED=51,UNITCOMBAT_MOUNTED_ARCHER=52}
DomainTypes={DOMAIN_LAND=0}; GameDefines={MOVE_DENOMINATOR=60,MAX_CIV_PLAYERS=2}
NotificationTypes={NOTIFICATION_GENERIC=0}; Locale={ConvertTextKey=function(k,...)return k end}
local function event()local e={handlers={}};e.Add=function(f)e.handlers[#e.handlers+1]=f end;return e end
GameEvents={}
for _,name in ipairs({'PlayerDoTurn','CityTrained','UnitSetXY','UnitCreated','UnitPromoted',
 'UnitConverted','UnitUpgraded','BattleStarted','BattleJoined','BattleFinished'}) do GameEvents[name]=event() end
LuaEvents={MasayaKidStateChanged=setmetatable({handlers={},Add=function(self,f)self.handlers[#self.handlers+1]=f end},
 {__call=function(self,...)for _,f in ipairs(self.handlers)do f(...)end end})}

local now=10; Game={GetGameTurn=function()return now end}; function SetTurn(value)now=value end
local plots={}; local byIndex={}
local function key(x,y)return x..':'..y end
function NewPlot(x,y,index,revealed)
 local p={x=x,y=y,index=index,revealed={[0]=revealed or false},units={}}
 function p:GetX()return self.x end;function p:GetY()return self.y end
 function p:GetPlotIndex()return self.index end
 function p:IsRevealed(team)return self.revealed[team] or false end
 function p:GetNumUnits()return #self.units end;function p:GetUnit(i)return self.units[i+1] end
 plots[key(x,y)]=p;byIndex[index]=p;return p
end
for x=-2,2 do for y=-2,2 do NewPlot(x,y,(x+2)*5+y+2,true) end end
local hidden=NewPlot(3,0,25,false)
Map={GetNumPlots=function()return 26 end,GetPlotByIndex=function(i)return byIndex[i] end,
 GetPlot=function(x,y)return plots[key(x,y)] end,
 PlotXYWithRangeCheck=function(x,y,dx,dy,r)if math.max(math.abs(dx),math.abs(dy))<=r then return plots[key(x+dx,y+dy)] end end}

GameInfo={Units=setmetatable({
 [10]={ID=10,Combat=12,RangedCombat=0,NukeDamageLevel=-1},
 [11]={ID=11,Combat=8,RangedCombat=0,NukeDamageLevel=-1},
 [12]={ID=12,Combat=20,RangedCombat=0,NukeDamageLevel=-1}},
 {__index=function(t,k)return rawget(t,k)end})}
local nextUnit=0
function NewUnit(owner,kind,combat,x,y,unitCombat)
 nextUnit=nextUnit+1
 local u={owner=owner,id=nextUnit,kind=kind,combat=combat,x=x,y=y,unitCombat=unitCombat or 51,
  xp=0,level=1,moves=300,damage=50,promotions={},script='' }
 function u:GetOwner()return self.owner end;function u:GetID()return self.id end
 function u:GetUnitType()return self.kind end;function u:GetUnitCombatType()return self.unitCombat end
 function u:IsCombatUnit()return true end;function u:GetDomainType()return 0 end
 function u:GetScriptData()return self.script end;function u:SetScriptData(v)self.script=v end
 function u:IsHasPromotion(p)return self.promotions[p]==true end
 function u:SetHasPromotion(p,v)self.promotions[p]=v end
 function u:GetMoves()return self.moves end;function u:VisibilityRange()return 2 end
 function u:GetX()return self.x end;function u:GetY()return self.y end
 function u:GetPlot()return plots[key(self.x,self.y)] end
 function u:GetBaseCombatStrength()return self.combat end;function u:GetBaseRangedCombatStrength()return 0 end
 function u:IsCanAttackRanged()return false end;function u:GetMeleeAttackFromPlot()return self:GetPlot() end
 function u:GetMaxAttackStrength()return self.combat*100 end
 function u:GetMaxDefenseStrength()return self.combat*100 end
 function u:GetExperience()return self.xp end;function u:ChangeExperience(v)self.xp=self.xp+v end
 function u:GetLevel()return self.level end;function u:ChangeDamage(v)self.damage=math.max(0,self.damage+v) end
 plots[key(x,y)].units[#plots[key(x,y)].units+1]=u
 return u
end
function NewCity(owner,id,x,y)
 local c={owner=owner,id=id,x=x,y=y,buildings={[20]=1},garrison=nil}
 function c:GetID()return self.id end;function c:GetX()return self.x end;function c:GetY()return self.y end
 function c:IsHasBuilding(i)return (self.buildings[i] or 0)>0 end
 function c:GetNumRealBuilding(i)return self.buildings[i] or 0 end
 function c:Plot()return plots[key(self.x,self.y)] end
 function c:GetGarrisonedUnit()return self.garrison end
 return c
end
function NewPlayer(id,civ)
 local p={id=id,civ=civ,team=id,unitList={},cityList={},notifications={}}
 function p:IsAlive()return true end;function p:GetCivilizationType()return self.civ end
 function p:GetTeam()return self.team end;function p:IsHuman()return self.id==0 end
 function p:GetUnitByID(id)for _,u in ipairs(self.unitList)do if u.id==id then return u end end end
 function p:GetCityByID(id)for _,c in ipairs(self.cityList)do if c.id==id then return c end end end
 function p:Units()local i=0;return function()i=i+1;return self.unitList[i]end end
 function p:Cities()local i=0;return function()i=i+1;return self.cityList[i]end end
 function p:AddNotification(...)self.notifications[#self.notifications+1]={...} end
 return p
end
Players={[0]=NewPlayer(0,1),[1]=NewPlayer(1,99)}
local prodigy=NewUnit(0,10,12,0,0,51);local scout=NewUnit(0,11,8,1,0,50)
local enemy=NewUnit(1,12,20,0,1,51)
enemy.script='[OTHER:abc]';prodigy.promotions[39]=true;prodigy.promotions[40]=true
Players[0].unitList={prodigy,scout};Players[1].unitList={enemy}
local city=NewCity(0,1,0,0);city.garrison=prodigy;Players[0].cityList={city}
local enemyCity=NewCity(1,2,0,2);Players[1].cityList={enemyCity}
TestProdigy=prodigy;TestScout=scout;TestEnemy=enemy;TestCity=city
TestEnemyCity=enemyCity;TestHidden=hidden
''')
    lua.execute(source)
    lua.execute(source)  # Same-context includes must not duplicate registrations.
    lua.execute(r'''
local M=MapModData.MasayaKid; local p=Players[0]; local prodigy=TestProdigy; local scout=TestScout
local enemy=TestEnemy; local enemyCity=TestEnemyCity; local hidden=TestHidden
assert(not prodigy:IsHasPromotion(39) and not prodigy:IsHasPromotion(40),'load did not scrub Natural bonuses')
assert(enemy.script=='[OTHER:abc]' and not M.HasUnitState(enemy),'foreign unit ScriptData was modified on load')
M.OnUnitCreated(1,enemy:GetID())
assert(enemy.script=='[OTHER:abc]' and not M.HasUnitState(enemy),'foreign creation wrote Masaya ScriptData')
M.OnUnitCreated(0,prodigy:GetID())
for name,event in pairs(GameEvents)do
 local expected=name=='UnitUpgraded' and 0 or 1
 assert(#event.handlers==expected,'wrong handler count for '..name)
end
M.ChangeJoy(0,49,'test');assert(M.GetState(0).joy==49 and not prodigy:IsHasPromotion(35))
M.ChangeJoy(0,1,'test');assert(prodigy:IsHasPromotion(35) and prodigy:IsHasPromotion(36))
assert(scout:IsHasPromotion(35) and scout:IsHasPromotion(36),'threshold bonuses missing')

local trainee=NewUnit(0,11,8,0,0,50);p.unitList[#p.unitList+1]=trainee
M.OnCityTrained(0,1,trainee:GetID())
assert(trainee.xp==5 and trainee:IsHasPromotion(33) and trainee:IsHasPromotion(34),'training effects missing')

-- Participation rewards require actual combat XP; merely receiving battle
-- callbacks against a city must not fake the generic or Practice Room reward.
local noXPJoy=M.GetState(0).joy
M.OnBattleStarted(0,0,0);M.OnBattleJoined(0,trainee:GetID(),0,false);M.OnBattleJoined(1,enemyCity:GetID(),1,true)
M.OnBattleFinished()
assert(M.GetState(0).joy==noXPJoy and M.GetUnitState(trainee).firstCombatJoy==0,
 'city callback without combat XP awarded participation Joy')

local before=M.GetState(0).joy;trainee.level=4;M.OnUnitPromoted(0,trainee:GetID(),999)
assert(M.GetState(0).joy==before+15,'promotion plus first Level 4 reward incorrect')
before=M.GetState(0).joy;M.OnUnitPromoted(0,trainee:GetID(),998)
assert(M.GetState(0).joy==before+5,'Level 4 reward repeated')

M.ChangeJoy(0,100,'test');local state=M.GetUIState(0)
assert(state.beyond and state.turns==6 and prodigy:IsHasPromotion(37),'Beyond did not activate')
local damage=prodigy.damage;M.OnUnitPromoted(0,prodigy:GetID(),997)
assert(prodigy.damage==damage-25,'Beyond promotion heal missing')
SetTurn(16);M.OnPlayerDoTurn(0);assert(M.GetState(0).joy==25 and not M.GetUIState(0).beyond,'Beyond expiry/reset incorrect')

-- Reset the persisted state object for isolated combat behavior checks.
M.GetState(0).joy=0;M.GetState(0).beyondEnd=-1;saved.MASAYA_KID_V1_P0_JOY=0;saved.MASAYA_KID_V1_P0_BEYOND_END=-1
M.RefreshPlayer(0);SetTurn(20);prodigy.xp=0;prodigy.level=1;enemy.xp=20;enemy.level=2
M.OnBattleStarted(0,0,0);M.OnBattleJoined(0,prodigy:GetID(),0,false);M.OnBattleJoined(1,enemy:GetID(),1,false)
assert(prodigy:IsHasPromotion(39) and prodigy:IsHasPromotion(40),'Natural Prodigy temporary bonuses missing')
prodigy.xp=3;M.OnBattleFinished()
assert(M.GetState(0).joy==7,'strong/combat/first-flight Joy incorrect')
assert(prodigy.xp==4 and M.GetUnitState(prodigy).prodigyCombats==1,'extra XP or combat count incorrect')
assert(not prodigy:IsHasPromotion(39) and not prodigy:IsHasPromotion(40),'temporary bonuses stuck')

-- The second combat in one turn does not repeat generic participation Joy.
M.OnBattleStarted(0,0,0);M.OnBattleJoined(0,prodigy:GetID(),0,false);M.OnBattleJoined(1,enemy:GetID(),1,false)
prodigy.xp=prodigy.xp+3;M.OnBattleFinished();assert(M.GetState(0).joy==12,'per-turn combat cap incorrect')

-- Unit-city and city-unit battles still pay normal survived-combat rewards,
-- never apply Natural/strong-opponent logic, and refresh movement-based ZOC.
M.GetState(0).joy=0;saved.MASAYA_KID_V1_P0_JOY=0;SetTurn(21)
local cityProdigy=NewUnit(0,10,12,0,0,51);p.unitList[#p.unitList+1]=cityProdigy
M.OnUnitCreated(0,cityProdigy:GetID());M.OnCityTrained(0,1,cityProdigy:GetID())
cityProdigy.moves=60
M.OnBattleStarted(0,0,0);M.OnBattleJoined(0,cityProdigy:GetID(),0,false);M.OnBattleJoined(1,enemyCity:GetID(),1,true)
assert(not cityProdigy:IsHasPromotion(39) and not cityProdigy:IsHasPromotion(40),
 'Natural Prodigy applied against a city')
cityProdigy.xp=cityProdigy.xp+3;M.OnBattleFinished()
assert(M.GetState(0).joy==6 and cityProdigy.xp==4,
 'first city combat did not pay combat/Cant Put/flight rewards')
assert(not cityProdigy:IsHasPromotion(38),'post-combat ZOC stayed active at one move')

cityProdigy.moves=120
M.OnBattleStarted(0,0,0);M.OnBattleJoined(0,cityProdigy:GetID(),0,false);M.OnBattleJoined(1,enemyCity:GetID(),1,true)
cityProdigy.xp=cityProdigy.xp+3;M.OnBattleFinished()
assert(M.GetState(0).joy==8 and cityProdigy:IsHasPromotion(38),
 'second city combat reward or post-combat ZOC refresh incorrect')

M.OnBattleStarted(0,0,0);M.OnBattleJoined(1,enemyCity:GetID(),0,true);M.OnBattleJoined(0,cityProdigy:GetID(),1,false)
cityProdigy.xp=cityProdigy.xp+3;M.OnBattleFinished()
assert(M.GetState(0).joy==10 and M.GetUnitState(cityProdigy).prodigyCombats==3,
 'city-defender combat or first-three flight cap incorrect')

local doomed=NewUnit(0,10,12,0,0,51);p.unitList[#p.unitList+1]=doomed
M.OnUnitCreated(0,doomed:GetID());local doomedJoy=M.GetState(0).joy
M.OnBattleStarted(0,0,0);M.OnBattleJoined(0,doomed:GetID(),0,false);M.OnBattleJoined(1,enemyCity:GetID(),1,true)
for i,u in ipairs(p.unitList)do if u==doomed then table.remove(p.unitList,i);break end end
M.OnBattleFinished();assert(M.GetState(0).joy==doomedJoy and doomed.xp==0,
 'destroyed unit received survived-combat rewards')

-- UnitConverted is the sole upgrade path and preserves the full state block.
local oldState=M.GetUnitState(trainee);oldState.prodigyCombats=2;oldState.exploreXP=4
oldState.firstCombatJoy=1;M.SetUnitState(trainee,oldState)
local upgraded=NewUnit(0,11,8,0,0,50);upgraded.script='[OTHER:new]';p.unitList[#p.unitList+1]=upgraded
GameEvents.UnitConverted.handlers[1](0,0,trainee:GetID(),upgraded:GetID(),true)
local upgradedState=M.GetUnitState(upgraded)
assert(upgradedState.serial==oldState.serial and upgradedState.prodigyCombats==2
 and upgradedState.exploreXP==4 and upgradedState.firstCombatJoy==1,
 'upgrade did not preserve Masaya state exactly once')
assert(upgraded.script:find('[OTHER:new]',1,true),'upgrade overwrote other ScriptData')

local gifted=NewUnit(1,11,8,0,1,50);gifted.script='[OTHER:keep]';Players[1].unitList[#Players[1].unitList+1]=gifted
M.OnUnitConverted(0,1,trainee:GetID(),gifted:GetID(),false)
assert(gifted.script=='[OTHER:keep]' and not M.HasUnitState(gifted),
 'conversion out retained Masaya state or damaged other ScriptData')

-- A plot not revealed when the cache was built awards Joy and trainee XP once.
local traineeState=M.GetUnitState(trainee);traineeState.createdTurn=20;M.SetUnitState(trainee,traineeState)
hidden.revealed[0]=true;trainee.x=3;trainee.y=0;M.OnUnitSetXY(0,trainee:GetID(),3,0)
assert(M.GetState(0).joy==11 and trainee.xp==6,'exploration reward incorrect')
M.OnUnitSetXY(0,trainee:GetID(),3,0);assert(M.GetState(0).joy==11,'tile paid twice')

-- Practice Room counters pause and pay independently every third garrisoned turn.
M.GetState(0).joy=0;saved.MASAYA_KID_V1_P0_JOY=0
for t=30,32 do SetTurn(t);M.OnPlayerDoTurn(0) end
assert(M.GetState(0).joy==1,'Practice Room three-turn cadence incorrect')
M.PlayerState[0]=nil
assert(M.GetState(0).joy==1 and M.GetUnitState(upgraded).serial==oldState.serial,
 'player or unit state did not survive a save-backed reload')
print('PASS Masaya runtime: context ownership, scoped persistence, city/unit combat, upgrades, thresholds, exploration, training, and garrison cadence')
''')

    # The panel is a read-only consumer and must load safely before the runtime.
    panel = LuaRuntime(unpack_returned_tuples=True)
    panel.execute(r'''
Includes={};function include(name)Includes[#Includes+1]=name end
local function event()local e={handlers={}};e.Add=function(f)e.handlers[#e.handlers+1]=f end;return e end
Events={SerialEventGameDataDirty=event(),SerialEventUnitInfoDirty=event(),
 GameplaySetActivePlayer=event(),ActivePlayerTurnStart=event()}
LuaEvents={};MapModData={};Game={GetActivePlayer=function()return 0 end,
 IsNetworkMultiPlayer=function()return false end};Players={[0]={IsAlive=function()return true end}}
function IconHookup(...)end
local function control()return {SetHide=function(self,v)self.hidden=v end,
 SetText=function(self,v)self.text=v end,SetToolTipString=function(self,v)self.tip=v end}end
Controls={JoyFrame=control(),JoyIcon=control(),JoyLabel=control(),StateLabel=control()}
for i=1,10 do Controls['Fill'..i]=control() end
''')
    panel.execute((ROOT / "UI/MasayaJoyPanel.lua").read_text(encoding="utf-8-sig"))
    panel.execute(r'''
assert(#Includes==1 and Includes[1]=='IconSupport','panel loaded gameplay runtime')
assert(Controls.JoyFrame.hidden==true,'panel was not safe while runtime unavailable')
MapModData.MasayaKid={IsMasaya=function()return true end,
 GetUIState=function()return {joy=50,beyond=false,cantStop=true,turns=0} end}
Events.SerialEventGameDataDirty.handlers[1]()
assert(Controls.JoyFrame.hidden==false and Controls.JoyLabel.text:find('50 / 100',1,true),
 'panel did not consume late runtime state')
print('PASS Masaya UI: independent loading and event-driven shared-state consumption')
''')

    # MapModData may survive unloading, but a new gameplay context must replace
    # its stale runtime cache and reload authoritative state from OpenSaveData.
    lua.execute(r'''
MapModData.MasayaKid.PlayerState[0]={joy=87,beyondEnd=-1}
saved.MASAYA_KID_V1_P0_JOY=20;saved.MASAYA_KID_V1_P0_BEYOND_END=-1
_G.__MASAYA_KID_RUNTIME_CONTEXT_LOADED=nil
''')
    lua.execute(source)
    lua.execute(r'''
assert(MapModData.MasayaKid.GetState(0).joy==20,
 'fresh gameplay context reused stale MapModData PlayerState')
''')

    # Expired persisted Beyond data is canonicalized silently before initialize
    # refreshes units, rather than briefly enabling Can't Stop Flying.
    lua.execute(r'''
MapModData.MasayaKid.PlayerState[0]={joy=87,beyondEnd=-1}
saved.MASAYA_KID_V1_P0_JOY=100;saved.MASAYA_KID_V1_P0_BEYOND_END=80
SetTurn(80);NotificationCount=#Players[0].notifications
_G.__MASAYA_KID_RUNTIME_CONTEXT_LOADED=nil
''')
    lua.execute(source)
    lua.execute(r'''
local M=MapModData.MasayaKid;local state=M.GetState(0)
assert(state.joy==25 and state.beyondEnd==-1,
 'expired Beyond state was not normalized on load')
assert(saved.MASAYA_KID_V1_P0_JOY==25 and saved.MASAYA_KID_V1_P0_BEYOND_END==-1,
 'normalized Beyond state was not persisted')
assert(#Players[0].notifications==NotificationCount,
 'load-time Beyond normalization sent a duplicate notification')
for unit in Players[0]:Units() do
 assert(not unit:IsHasPromotion(35) and not unit:IsHasPromotion(36)
  and not unit:IsHasPromotion(37),'expired Beyond load left a dynamic state promotion')
end
print('PASS Masaya reload: stale MapModData rejected and expired Beyond normalized silently')
''')


def main() -> None:
    user = Path.home() / "Documents/My Games/Sid Meier's Civilization 5"
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--database", type=Path, default=user / "cache_backup/Civ5DebugDatabase.db")
    parser.add_argument("--cp-root", type=Path, default=user / "MODS/(1) Community Patch")
    args = parser.parse_args()
    database_checks(args.database, args.cp_root)
    package_and_art_checks()
    lua_behavior_checks()
    print("Masaya validation passed. Final visuals and engine interactions still need an in-game smoke test.")


if __name__ == "__main__":
    main()
