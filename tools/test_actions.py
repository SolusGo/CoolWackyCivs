"""Execute active-ability transactions in a small Lua 5.1 Civ API mock."""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / ".tools" / "python"))
from lupa.lua51 import LuaRuntime

lua = LuaRuntime(unpack_returned_tuples=True)
lua.execute(r'''
function iterator(items)
  local i=0; return function() i=i+1; return items[i] end
end
function event() local e={}; e.Add=function(cb) e.cb=cb end; return e end
GameEvents={UnitSetXY=event(),UnitPrekill=event(),UnitCreated=event(),PlayerDoTurn=event(),
 DeclareWar=event(),MakePeace=event(),BattleFinished=event()}
Events={}
GameDefines={MAX_PLAYERS=2}
Game={turn=40, GetGameTurn=function() return Game.turn end,
 IsNetworkMultiPlayer=function() return false end, Rand=function() return 99 end}
GameInfoTypes={DOMAIN_LAND=1,DOMAIN_SEA=2,ERA_MODERN=5,UNIT_ROULS_MATRIARCH=3,
 UNIT_ROULS_HOLLOWHOUND=4,UNIT_ROULS_BUDDY=5,UNITCLASS_INFANTRY=10,
 PROMOTION_ROULS_CHOIR_1=101,PROMOTION_ROULS_CHOIR_2=102,PROMOTION_ROULS_CHOIR_3=103,
 PROMOTION_ROULS_CHOIR_4=104,PROMOTION_ROULS_CHOIR_5=105,
 PROMOTION_ROULS_BUDDY_AURA=106,PROMOTION_ROULS_BUDDY_INVASION=107}
GameInfo={Units={},UnitClasses={}}
GameInfo.UnitClasses.UNITCLASS_INFANTRY={MaxPlayerInstances=-1,MaxTeamInstances=-1,MaxGlobalInstances=-1}
GameInfo.Units[1]={Domain='DOMAIN_LAND',Class='UNITCLASS_INFANTRY',Combat=20,RangedCombat=0,NukeDamageLevel=-1,Suicide=0}
GameInfo.Units[2]={Domain='DOMAIN_LAND',Class='UNITCLASS_INFANTRY',Combat=25,RangedCombat=0,NukeDamageLevel=-1,Suicide=0}
GameInfo.Units[3]={Domain='DOMAIN_LAND',Class='UNITCLASS_GENERAL',Combat=0,RangedCombat=0,NukeDamageLevel=-1,Suicide=0}
GameInfo.Units[4]=GameInfo.Units[1]; GameInfo.Units[5]={Domain='DOMAIN_SEA',Class='UNITCLASS_BUDDY',Combat=45,RangedCombat=0,NukeDamageLevel=-1,Suicide=0}

local plots={}
function plot(x,y,owner,water)
  local p={x=x,y=y,owner=owner,water=water or false,units={},visible=true}
  function p:GetX() return self.x end; function p:GetY() return self.y end
  function p:GetOwner() return self.owner end; function p:IsWater() return self.water end
  function p:IsMountain() return false end; function p:IsImpassable() return false end
  function p:IsCity() return self.city~=nil end; function p:GetPlotCity() return self.city end
  function p:GetNumUnits() return #self.units end; function p:GetUnit(i) return self.units[i+1] end
  function p:GetPlotIndex() return self.x*100+self.y end; function p:IsVisible() return self.visible end
  plots[x..','..y]=p; return p
end
Map={PlotDistance=function(x1,y1,x2,y2) return math.max(math.abs(x1-x2),math.abs(y1-y2)) end,
 PlotXYWithRangeCheck=function(x,y,dx,dy,r) if math.max(math.abs(dx),math.abs(dy))<=r then return plots[(x+dx)..','..(y+dy)] end end,
 GetNumPlots=function() return 0 end,GetPlotByIndex=function() return nil end}
Teams={[0]={war=true},[1]={war=true}}
Teams[0].IsAtWar=function(self,other) return self.war and other==1 end
Teams[1].IsAtWar=function(self,other) return self.war and other==0 end
Teams[0].IsAllowsOpenBordersToTeam=function() return false end
Teams[1].IsAllowsOpenBordersToTeam=function() return false end

local function remove(p,u) for i,v in ipairs(p.units) do if v==u then table.remove(p.units,i); return end end end
function unit(owner,id,typeID,p)
 local u={owner=owner,id=id,typeID=typeID,p=p,dead=false,damage=0,xp=0,promos={},locked=false}
 p.units[#p.units+1]=u
 function u:GetOwner() return self.owner end; function u:GetID() return self.id end
 function u:GetUnitType() return self.typeID end; function u:GetDomainType() return GameInfo.Units[self.typeID].Domain=='DOMAIN_SEA' and 2 or 1 end
 function u:GetPlot() return self.p end; function u:GetX() return self.p.x end; function u:GetY() return self.p.y end
 function u:IsDead() return self.dead end; function u:IsDelayedDeath() return false end; function u:IsEmbarked() return false end
 function u:IsInCombat() return false end; function u:GetCargo() return self.cargo or 0 end; function u:IsCargo() return false end
 function u:GetDamage() return self.damage end; function u:SetDamage(v) self.damage=v end; function u:GetMaxHitPoints() return 100 end
 function u:GetExperience() return self.xp end; function u:SetExperience(v) self.xp=v end
 function u:IsInvisible() return self.hidden or false end
 function u:IsHasPromotion(id) return self.promos[id] or false end; function u:SetHasPromotion(id,v) self.promos[id]=v end
 function u:CanMoveOrAttackInto() return not self.cannotEnter end
 function u:SetXY(x,y) local q=plots[x..','..y]; assert(q); remove(self.p,self); self.p=q; q.units[#q.units+1]=self end
 function u:Kill() self.dead=true; remove(self.p,self) end
 function u:GetName() return 'Mock Unit '..self.id end
 return u
end
pA,pB,pStage,pNear,pTarget=plot(0,0,0),plot(2,0,0),plot(0,2,0),plot(3,0,0),plot(5,0,1)
city={}; function city:GetX() return pStage.x end; function city:GetY() return pStage.y end
function city:Plot() return pStage end; function city:IsCoastal() return false end; pStage.city=city
u1,u2,scout,target=unit(0,1,1,pA),unit(0,2,1,pB),unit(0,6,1,pNear),unit(1,9,1,pTarget)
target.xp=100
P0={units={u1,u2,scout},cities={city},state={swapReadyTurn=0,migrationUsed=false},anima=7,next=20}
P1={units={target},cities={}}
for id,p in pairs({[0]=P0,[1]=P1}) do
 function p:IsAlive() return true end; function p:IsHuman() return id==0 end; function p:IsTurnActive() return true end
 function p:GetTeam() return id end; function p:GetCurrentEra() return 5 end
 function p:Units() return iterator(self.units) end; function p:Cities() return iterator(self.cities) end
 function p:GetUnitByID(uid) for _,u in ipairs(self.units) do if u.id==uid then return u end end end
 function p:InitUnit(t,x,y) self.next=(self.next or 30)+1; local u=unit(id,self.next,t,plots[x..','..y]); self.units[#self.units+1]=u; return u end
end
Players={[0]=P0,[1]=P1}
MapModData={Rouls={}}
local R=MapModData.Rouls
function R.IsRouls(id) return id==0 end; function R.IsMilitary(u) return u and GameInfo.Units[u.typeID].Combat>0 end
function R.IsLocked(u) return u.locked end; function R.IsLegalPlot() return true end
function R.GetState() return P0.state end; function R.Save() end; function R.GetAnima() return P0.anima end
function R.ChangeAnima(_,d) P0.anima=P0.anima+d end; function R.LockUnit(u) u.locked=true end
function R.EquivalentType() return 2 end; function R.WithSuppressedDeaths(fn) return fn() end
function R.Snapshot(u) return {unitType=u.typeID,classID=10,xp100=u.xp*100,level=1,name='victim',promotions={},script='',maxHP=100,damage=u.damage} end
function R.Restore() error('rollback unexpectedly needed') end
''')
lua.execute((ROOT / "RoulsAscendancy/Lua/RoulsActions.lua").read_text(encoding="utf-8-sig"))
lua.execute(r'''
local R=MapModData.Rouls
local ok,why,cost=R.CanSwap(0,u1,u2); assert(ok and cost==2,why)
local old1,old2=u1:GetID(),u2:GetID()
ok,why=R.DoSwap(0,old1,old2); assert(ok,why)
assert(u1:GetID()==old1 and u2:GetID()==old2 and u1:GetX()==2 and u2:GetX()==0)
assert(P0.anima==5 and P0.state.swapReadyTurn==48 and u1.locked and u2.locked)
-- A stale/repeated activation cannot spend again.
local before=P0.anima; ok=R.DoSwap(0,old1,old2); assert(not ok and P0.anima==before)
-- A Matriarch near either endpoint discounts the next valid exchange to one.
u1.locked=false; u2.locked=false; P0.state.swapReadyTurn=0
local general=unit(0,7,3,pNear); P0.units[#P0.units+1]=general
ok,why,cost=R.CanSwap(0,u1,u2); assert(ok and cost==1,why)
-- Great Migration consumes exactly seven, halves XP, moves to the victim tile,
-- locks the new unit and marks the once-per-game state.
P0.anima=7; P0.state.migrationUsed=false; u1.locked=false; u2.locked=false
ok,why=R.DoMigration(0,1,9); assert(ok,why)
assert(target.dead and P0.anima==0 and P0.state.migrationUsed)
local created=P0.units[#P0.units]
assert(created.typeID==2 and created:GetPlot()==pTarget and created.xp==50 and created.damage==25 and created.locked)
-- Limited classes and cargo are rejected before any state changes.
local t2=unit(1,10,1,pTarget); P1.units[#P1.units+1]=t2
P0.anima=7; P0.state.migrationUsed=false; t2.cargo=1
before=P0.anima; ok=R.CanMigrate(0,t2); assert(not ok and P0.anima==before and not t2.dead)
print('PASS Lua transaction scenarios: swap, cooldown, discount, stale activation, migration, XP/HP, cargo rejection')
''')
