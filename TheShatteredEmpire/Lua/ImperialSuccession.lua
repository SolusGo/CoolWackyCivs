local I=MapModData.TheShatteredEmpire
function I.SuccessionTick(s)
 local p=Players[s.pid];local era=p:GetCurrentEra()
 if s.succession then
  if I.Now()>=s.succession.deadline then I.SelectSuccessor(s,I.BestSuccessor(s)) end
 elseif era>0 and era>s.eraSeen and I.Now()>=s.successionNext and p:GetNumCities()>0 then
  local candidates={}
  for _,kind in ipairs({'BLOOD','STEEL','COUNCIL'}) do
   candidates[kind]={name=I.Name(s),archetype=kind,trait=I.Text('HEIR_TRAIT_'..kind),related=kind=='BLOOD' and I.Reign(s).name or I.Text('HEIR_COUNCIL_RELATION'),generated=I.Now()}
  end
  s.succession={id=s.nextSuccession,created=I.Now(),deadline=I.Now()+I.Scale(10),era=era,candidates=candidates};s.nextSuccession=s.nextSuccession+1
  s.eraSeen=era;s.successionNext=I.Now()+I.Scale(40)
  I.History(s,'SUCCESSION',I.Text('HISTORY_COUNCIL',I.Reign(s).name));I.Notify(s,I.Text('SUCCESSION_TITLE'),I.Text('SUCCESSION_NOTICE'))
 end
end
function I.BestSuccessor(s)
 if s.authority<55 then return 'BLOOD' end
 if s.averageLoyalty<55 and s.authority>65 then return 'COUNCIL' end
 if I.Wars(s.pid)>0 then return 'STEEL' end
 return 'BLOOD'
end
function I.SelectSuccessor(s,kind)
 local pending=s.succession;local candidate=pending and pending.candidates[kind];if not candidate then return end
 local old=I.Reign(s);old.finish=I.Now();old.length=old.finish-old.start;old.succession=kind
 local crisis=s.authority<40;local discontent=0
 for _,g in ipairs(I.Provinces(s)) do if g.loyalty<45 then discontent=discontent+1 end end
 crisis=crisis or discontent>=3
 if crisis then I.Authority(s,-10);I.History(s,'SUCCESSION',I.Text('HISTORY_SUCCESSION_CRISIS')) else I.Authority(s,5) end
 if kind=='BLOOD' then
  I.Authority(s,15);for _,g in ipairs(I.Provinces(s)) do if g.archetype=='AMBITIOUS' or g.ambition>70 then g.loyalty=math.max(0,g.loyalty-10);g.relationship=math.max(-100,g.relationship-10) end end
 elseif kind=='STEEL' then
  for _,r in pairs(s.units) do r.oath=I.Clamp(r.oath+15,0,100) end
  for _,g in ipairs(I.Provinces(s)) do if g.archetype=='MERCHANT' or g.archetype=='POPULIST' then g.loyalty=math.max(0,g.loyalty-10) end end
 else
  I.Authority(s,-15);s.councilUntil=I.Now()+I.Scale(10)
  for _,g in ipairs(I.Provinces(s)) do g.loyalty=I.Clamp(g.loyalty+10,0,100) end
 end
 s.dynasty[#s.dynasty+1]={name=candidate.name,archetype=kind,trait=candidate.trait,related=candidate.related,start=I.Now(),wars=0,rebellions=0,acquired=0,lost=0,reforms=0,circumstance=crisis and 'CRISIS' or 'PEACEFUL'}
 if #s.dynasty>50 then table.remove(s.dynasty,1) end
 s.succession=nil;I.History(s,'SUCCESSION',I.Text('HISTORY_SUCCESSOR',candidate.name,I.Text('HEIR_'..kind)))
end
