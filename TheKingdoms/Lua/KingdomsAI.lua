local K=MapModData.TheKingdoms
function K.AITick(s)
 local p=Players[s.pid];if p:IsHuman() then return end
 for _,uid in ipairs(K.Keys(s.pending)) do K.AutoAppoint(s.pid,uid) end
 for _,cid in ipairs(K.Keys(s.guards)) do
  local g=s.guards[cid]
  if g.oathPending then K.Oath(s.pid,cid,p:GetGold()>=K.Scale(80) and 'KEEP' or 'OATH') end
 end
 if s.war then
  local best
  for _,f in ipairs(K.Factions(s)) do if not best or f.strength>best.strength then best=f end end
  if best and p:GetGold()>K.Scale(250) then K.Support(s.pid,best.id,'FUND') end
 elseif K.Now()>=(s.aiNext or 0) then
  local best,score
  for _,h in ipairs(K.ActiveHouses(s)) do
   if h.loyalty<20 then
    local n=(25-h.loyalty)*K.Influence(s,h)*s.kingdoms[h.kingdom].population
    if not score or n>score then best,score=h,n end
   end
  end
  if best and p:GetGold()>K.Scale(200) then K.Appease(s.pid,best.id,'GIFT') end
  s.aiNext=K.Now()+K.Scale(8)
 end
end
