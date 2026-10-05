local K=MapModData.TheKingdoms
function K.Claims(s)
 local result,total={},0
 local ruler=s.ruler and s.characters[s.ruler];local dynasty=ruler and ruler.house or s.previousHouse
 for _,h in ipairs(K.ActiveHouses(s)) do
  local age=(K.Now()-h.founded)/K.Speed
  local support=0
  for rid,n in pairs(h.relations) do if n>=50 and s.houses[rid] and s.kingdoms[s.houses[rid].kingdom].active then support=support+math.min(8,s.houses[rid].prestige*.05) end end
  h.claim=math.max(1,h.prestige*.65+K.Influence(s,h)*.4+math.min(20,age*.15)+h.stats.rulers*10+h.stats.guards*4+h.claimBonus+K.TraitSum(h,'claim')+support+(h.id==dynasty and 20+K.TraitSum(h,'dynasty') or 0))
  result[#result+1]={house=h.id,score=h.claim};total=total+h.claim
 end
 table.sort(result,function(a,b) return a.score>b.score or a.score==b.score and a.house<b.house end)
 for _,entry in ipairs(result) do entry.percent=total>0 and 100*entry.score/total or 0 end
 s.claims=result;return result
end
function K.Succeed(s)
 local claims=K.Claims(s)
 K.Log('SUCCESSION','Realm '..s.realm..'; eligible Houses '..#claims)
 if #claims==0 then return end
 if s.realm<45 and #claims>=2 then K.BeginCivilWar(s,claims) else K.Crown(s,claims[1].house) end
end
