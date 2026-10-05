local K=MapModData.TheKingdoms
function K.History(s,category,key,args,house,kingdom)
 local e={id=s.nextHistory,turn=K.Now(),category=category,key=key,args=args or {},house=house,kingdom=kingdom}
 s.nextHistory=s.nextHistory+1;s.history[#s.history+1]=e
 if house and s.houses[house] then local t=s.houses[house].timeline;t[#t+1]=e.id end
 K.Log('HISTORY',category..':'..key)
 return e
end
function K.HistoryText(e) return K.Text(e.key,unpack(e.args)) end
function K.Date(turn)
 local year=Game.GetTurnYear and Game.GetTurnYear(turn)
 if year then return K.Text(year<0 and 'YEAR_BC' or 'YEAR_AD',math.abs(year)) end
 return K.Text('TURN',turn)
end
