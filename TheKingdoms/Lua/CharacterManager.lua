local K=MapModData.TheKingdoms
function K.Character(s,hid,role)
 local female=K.Rand(s,2)==0
 local c={id=s.nextCharacter,house=hid,role=role,female=female,
 name=K.Pick(s,female and K.FemaleNames or K.MaleNames),created=K.Now(),alive=true,traits={},stats={kills=0,battles=0}}
 s.nextCharacter=s.nextCharacter+1;s.characters[c.id]=c
 return c
end
function K.CharacterName(s,c)
 if not c then return K.Text('INTERREGNUM') end
 local h=s.houses[c.house];local name=c.name
 if c.role=='ruler' then
  return K.Text(c.female and 'QUEEN_NAME' or 'KING_NAME',name..' '..K.Regnal(c.number or 1),h and h.name or K.Text('UNKNOWN_HOUSE'))
 elseif c.role=='guard' or c.role=='candidate' then
  return K.Text(c.female and 'LADY_NAME' or 'SER_NAME',name,h and h.name or K.Text('UNKNOWN_HOUSE'))
 end
 return name..' '..(h and h.name or '')
end
function K.Regnal(n)
 local parts={};local values={{1000,'M'},{900,'CM'},{500,'D'},{400,'CD'},{100,'C'},{90,'XC'},{50,'L'},{40,'XL'},{10,'X'},{9,'IX'},{5,'V'},{4,'IV'},{1,'I'}}
 for _,p in ipairs(values) do while n>=p[1] do parts[#parts+1]=p[2];n=n-p[1] end end
 return table.concat(parts)
end
