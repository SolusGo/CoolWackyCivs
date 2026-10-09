local I=MapModData.TheShatteredEmpire
function I.History(s,kind,text)
 s.history[#s.history+1]={id=s.nextHistory,turn=I.Now(),kind=kind,text=text};s.nextHistory=s.nextHistory+1
 if #s.history>300 then table.remove(s.history,1) end
 I.Log(kind,text)
end
function I.Notify(s,title,text,g)
 local p=Players[s.pid]
 if p:IsHuman() then p:AddNotification(NotificationTypes.NOTIFICATION_GENERIC,text,title,g and g.x or -1,g and g.y or -1) end
end
function I.PoliticalRecord(g,text)
 g.history[#g.history+1]={turn=I.Now(),text=text}
 if #g.history>12 then table.remove(g.history,1) end
end
function I.Reign(s) return s.dynasty[#s.dynasty] end
