local K=MapModData.TheKingdoms
function K.Crown(s,hid,claimant,war)
 local h=s.houses[hid];if not h then return false end
 local c=claimant and s.characters[claimant] or K.Character(s,hid,'ruler')
 c.role='ruler';c.alive=true;c.reignStart=K.Now();c.legitimacy=war and 55 or 72
 c.reignEnd=K.Now()+K.Scale(25+K.Rand(s,26))
 local keys=K.Keys(K.RulerTraits);local first=K.Pick(s,keys);c.traits={first}
 if K.Rand(s,2)==0 then local second=first;while second==first do second=K.Pick(s,keys) end;c.traits[2]=second end
 s.regnal[c.name]=(s.regnal[c.name] or 0)+1;c.number=s.regnal[c.name]
 s.ruler=c.id;h.stats.rulers=h.stats.rulers+1;h.prestige=h.prestige+18
 for _,other in ipairs(K.ActiveHouses(s)) do
  local relation=other.relations[hid] or 0
  K.Loyalty(other,other.id==hid and 20 or relation>=20 and 8 or relation<=-40 and -12 or -2)
  if relation>=50 then other.prestige=other.prestige+4 end
 end
 K.History(s,'RULERS','RULER_CROWNED',{K.CharacterName(s,c)},hid)
 K.Notify(s.pid,'RULER_CROWNED',K.CharacterName(s,c));K.Log('RULER','Crowned '..c.id)
 return true
end
function K.RulerTick(s)
 if s.war then return end
 if not s.ruler then
  local houses=K.ActiveHouses(s);if houses[1] then K.Crown(s,houses[1].id) end;return
 end
 local c=s.characters[s.ruler]
 if not c then s.ruler=nil;return end
 if K.Now()>=c.reignEnd then
  c.alive=false;c.died=K.Now();c.reignLength=K.Now()-c.reignStart
  K.History(s,'RULERS','RULER_DIED',{K.CharacterName(s,c),c.reignLength},c.house)
  K.Notify(s.pid,'RULER_DIED',K.CharacterName(s,c),c.reignLength)
  s.previousHouse=c.house;s.ruler=nil;K.Succeed(s)
 elseif K.Now()%K.Scale(5)==0 then
  c.legitimacy=K.Clamp(c.legitimacy+(s.realm>=60 and 1 or -1),0,100)
 end
end
