local K=MapModData.TheKingdoms
K.HouseNames={'Valen','Torr','Marr','Edran','Corren','Aren','Vey','Ardyn','Dorran','Cael','Thorne','Roth','Halren','Morwyn','Valecrest','Storme','Darion','Cressen','Renwick','Aldren','Ashford','Briar','Calder','Dunmere','Elthorn','Falken','Gilden','Harrow','Iveren','Jorren','Kestrel','Lorn','Merewyn','Norren','Orlan','Perrin','Quen','Ravenholt','Sable','Torwyn','Umberfell','Varren','Westmere','Yarrow','Zephyr','Aster','Bracken','Cairn','Duskvale','Ember','Frostmere','Greyford','Highmere','Ironvale','Juniper','Kingswell','Larkspur','Mourn','Nettle','Oakheart','Pike','Quill','Redwyck','Silvermere','Tallwyn','Ulric','Verden','Winterford','Wren','Yorren','Auric','Bellmont','Cinder','Devrin','Everholt','Fenwick','Gallow','Hartmere','Ivoryn','Jasper','Kelren','Lowen','Marwick','Northwatch','Orrick','Primrose','Rill','Stoneward','Thistlen','Ulden','Voss','Willowmere','Yarden','Althorn','Beldran','Crestfall','Dawnhold','Foxmere','Goldwyn','Hazelmere','Mistvale','Rook','Sunward','Wyvern','Roseward'}
K.MaleNames={'Aldric','Alaric','Garrick','Edric','Osric','Cedric','Rowan','Darian','Tavian','Corwin','Emrys','Leoric','Merek','Ronan','Silas','Theron','Valric','Wystan','Aren','Beren','Calen','Doran','Eamon','Ferran','Galen','Hadric','Ilan','Jareth','Kael','Lucan','Maelor','Norric','Orin','Perrin','Quentin','Renard','Soren','Tristan','Ulric','Varen'}
K.FemaleNames={'Mira','Elara','Alys','Isolde','Lyra','Seren','Arwenna','Briennea','Cerys','Dahlia','Eira','Faye','Gwyn','Helena','Ilena','Jessamine','Kira','Liora','Maera','Nerys','Orianna','Petra','Rhea','Selene','Talia','Una','Vera','Wynne','Yara','Zora'}
K.Symbols={'Lion','Stag','Tower','Sword','Wolf','Crown','Raven','Tree','Horse','Sun','Moon','Wyvern','Eagle','Rose'}
K.HouseTraits={
 Militaristic={military=3,xp=1,demands={'UNITS','BARRACKS','ENEMY','WAR'},war=1},
 Agrarian={food=3,demands={'FARMS','GROW','RESOURCE'},war=-1},
 Mercantile={gold=3,demands={'GOLD','MARKET','TRADE','GPT'}},
 Expansionist={production=2,demands={'EXPAND','CAPTURE'},war=1},
 Isolationist={culture=2,demands={'WALL','PEACE','GARRISON'},war=-2},
 Traditionalist={stability=3,culture=1,demands={'WALL','CULTURE'},dynasty=10},
 Religious={faith=3,demands={'SHRINE','FAITH'}},
 Scholarly={science=3,demands={'LIBRARY','TECH'}},
 Ambitious={production=2,demands={'CAPTURE','EXPAND','GOLD'},claim=12,alliance=-5},
 Loyalist={stability=3,demands={'GARRISON','WALL'},loyalty=1,dynasty=18},
 Opportunistic={gold=2,demands={'GOLD','TRADE'},claim=6,alliance=-8},
 Proud={culture=2,demands={'CULTURE','WALL'},refusal=4},
 Defensive={military=2,stability=1,demands={'WALL','GARRISON','PEACE'}},
 Maritime={gold=2,demands={'TRADE','MARKET','GPT'}},
 Industrial={production=3,demands={'MINE','UNITS','RESOURCE'}},
 Diplomatic={gold=1,stability=2,demands={'PEACE','TRADE'},alliance=10},
 Populist={food=2,stability=1,demands={'GROW','GOLD'},loyalty=1},
 Zealous={faith=2,military=1,demands={'SHRINE','FAITH','WAR'},war=1},
 Cautious={science=1,stability=2,demands={'GARRISON','PEACE','LIBRARY'},war=-1},
 Honourable={xp=2,stability=1,demands={'CAMP','BARBARIANS','UNITS'},alliance=8}
}
K.RulerTraits={
 Conqueror={military=8,combat=5,peaceDiscontent=2}, Architect={building=10}, Scholar={science=8},
 Diplomat={gold=3,stability=4}, Steward={gold=5,production=4}, Warrior={military=6,xp=3},
 Pious={faith=8}, Popular={stability=8,loyalty=1}, Arrogant={refusal=6,claim=5},
 Cruel={military=6,loyalty=-1}, Indecisive={production=-4,stability=-3}, Greedy={gold=8,loyalty=-1},
 Paranoid={stability=-5,refusal=3}, Reckless={military=8,stability=-5}, Weak={military=-5,stability=-4},
 Unpopular={stability=-8,loyalty=-1}
}
K.GuardTraits={
 Honourable={promotion='HONOURABLE',value=8}, Brutal={promotion='BRUTAL',value=10},
 Protector={promotion='PROTECTOR',value=8}, Duelist={promotion='DUELIST',value=9},
 Commander={promotion='COMMANDER',value=10}, Unyielding={promotion='UNYIELDING',value=9},
 Rider={promotion='RIDER',value=10}, Siegebreaker={promotion='SIEGEBREAKER',value=8},
 Veteran={promotion='VETERAN',value=11}, Guardian={promotion='GUARDIAN',value=9},
 Aggressive={promotion='AGGRESSIVE',value=9}, Cautious={promotion='CAUTIOUS',value=7},
 Loyal={promotion='LOYAL',value=8,oath=25}, Ambitious={promotion='AMBITIOUS',value=11,oath=-20}
}
K.Actions={
 GIFT={gold=80,loyalty=12,influence=1}, ESTATES={gold=150,loyalty=24,influence=8,penalty=12},
 CHARTER={gold=120,loyalty=16,influence=5,prestige=6,claim=8},
 AUTHORITY={gold=100,loyalty=20,influence=7,claim=18,militaristic=true}
}
function K.Keys(t)
 local r={};for k in pairs(t) do r[#r+1]=k end;table.sort(r);return r
end
function K.Rand(s,n)
 s.rng=(s.rng*48271)%2147483647;return math.floor(s.rng/2147483647*n)
end
function K.Pick(s,t) return t[1+K.Rand(s,#t)] end
function K.HasTrait(h,key) for _,v in ipairs(h.traits or {}) do if v==key then return true end end;return false end
function K.TraitSum(h,key,defs)
 local n=0;for _,v in ipairs(h.traits or {}) do n=n+(((defs or K.HouseTraits)[v] or {})[key] or 0) end;return n
end
