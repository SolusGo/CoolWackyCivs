"""Regenerate explicit CP inheritance/effects/localization from the installed read-only schema."""
from pathlib import Path
import sqlite3,sys
R=Path(__file__).resolve().parents[1]
sys.path[:0]=[str(R/'.tools/python'),str(R/'tools')]
from validate_mod import apply_current_cp_schema,quote
V=R/'TheKingdoms/SQL'

def main():
    user=Path.home()/"Documents/My Games/Sid Meier's Civilization 5"
    src=sqlite3.connect((user/'cache_backup/Civ5DebugDatabase.db').as_uri()+'?mode=ro',uri=True)
    db=sqlite3.connect(':memory:');src.backup(db);src.close();apply_current_cp_schema(db,user/'MODS/(1) Community Patch')
    statements=['-- Explicit companion inheritance, retaining active BNW/CP Walls and Longswordsman rules.']
    for table,base,new,col in [('Building_','BUILDING_WALLS','BUILDING_KINGDOMS_WALL','BuildingType'),('Unit_','UNIT_LONGSWORDSMAN','UNIT_KINGDOMS_GUARD','UnitType')]:
        for (name,) in db.execute("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name"):
            if not name.startswith(table):continue
            cols=[r[1] for r in db.execute('PRAGMA table_info('+quote(name)+')')]
            if col not in cols:continue
            statements.extend([f'CREATE TEMP TABLE KingdomsCompanion AS SELECT * FROM {quote(name)} WHERE {col}=\'{base}\';',f"UPDATE KingdomsCompanion SET {col}='{new}';",f'INSERT INTO {quote(name)} SELECT * FROM KingdomsCompanion;','DROP TABLE KingdomsCompanion;'])
    statements += ["INSERT INTO Building_YieldChanges(BuildingType,YieldType,Yield) SELECT 'BUILDING_KINGDOMS_WALL','YIELD_PRODUCTION',2 WHERE NOT EXISTS (SELECT 1 FROM Building_YieldChanges WHERE BuildingType='BUILDING_KINGDOMS_WALL' AND YieldType='YIELD_PRODUCTION');",
      "UPDATE Building_YieldChanges SET Yield=Yield+2 WHERE BuildingType='BUILDING_KINGDOMS_WALL' AND YieldType='YIELD_PRODUCTION' AND EXISTS (SELECT 1 FROM Building_YieldChanges WHERE BuildingType='BUILDING_WALLS' AND YieldType='YIELD_PRODUCTION');"]
    (V/'01_Kingdoms_Inheritance.sql').write_text('\n'.join(statements)+'\n',encoding='utf-8')
    effects=[]
    def dummy(name,**cols):
        typ='BUILDING_KINGDOMS_'+name
        effects.append(f"INSERT INTO BuildingClasses(Type,DefaultBuilding,Description) VALUES ('BUILDINGCLASS_KINGDOMS_{name}','{typ}','TXT_KEY_KINGDOMS_DUMMY');")
        fields={'Type':typ,'BuildingClass':'BUILDINGCLASS_KINGDOMS_'+name,'Description':'TXT_KEY_KINGDOMS_DUMMY','Cost':-1,'FaithCost':-1,'GreatWorkCount':-1,'NeverCapture':1,'NukeImmune':1,'ConquestProb':0,'IsDummy':1,'ShowInPedia':0,**cols}
        values=','.join("'"+v+"'" if isinstance(v,str) else str(v) for v in fields.values())
        effects.append('INSERT INTO Buildings('+','.join(fields)+') VALUES ('+values+');')
        return typ
    def yieldmod(typ,y,n):effects.append(f"INSERT INTO Building_YieldModifiers(BuildingType,YieldType,Yield) VALUES ('{typ}','YIELD_{y}',{n});")
    for y in ['FOOD','PRODUCTION','GOLD','SCIENCE','CULTURE','FAITH']:
        for sign in ['P','N']:
            for bit in [1,2,4,8,16]:yieldmod(dummy(y+'_'+sign+str(bit)),y,bit if sign=='P' else -bit)
    for field,column in [('MILITARY','MilitaryProductionModifier'),('XP','Experience'),('ARCHITECT','BuildingProductionModifier')]:
        for bit in [1,2,4,8,16]:dummy(field+'_'+str(bit),**{column:bit})
    war=dummy('CIVILWAR',UnmoddedHappiness=-3)
    for y,n in [('FOOD',-25),('PRODUCTION',-30),('GOLD',-20),('SCIENCE',-15)]:yieldmod(war,y,n)
    for name,penalties in [('RIOT',[('FOOD',-10),('PRODUCTION',-10)]),('ESTATES',[('PRODUCTION',-10)]),('SUPPLIES',[('PRODUCTION',-10)])]:
        typ=dummy(name)
        for y,n in penalties:yieldmod(typ,y,n)
    promotion_defs={
      'GUARD':{},'PENDING':{'OnlyDefensive':1},'CIVILWAR':{'CombatPercent':-15},'RULER_COMBAT':{'CombatPercent':5},
      'HONOURABLE':{'AdjacentMod':10},'BRUTAL':{'AttackWoundedMod':20},'PROTECTOR':{'CityDefense':25},
      'DUELIST':{'AttackMod':15},'COMMANDER':{'AdjacentTileHealChange':5},'UNYIELDING':{'DefenseMod':20},
      'RIDER':{'MovesChange':1},'SIEGEBREAKER':{'CityAttack':20},'VETERAN':{'CombatPercent':10},
      'GUARDIAN':{'FriendlyLandsModifier':15},'AGGRESSIVE':{'AttackMod':20,'DefenseMod':-5},
      'CAUTIOUS':{'RangedDefenseMod':25},'LOYAL':{'CapitalDefenseModifier':20,'CapitalDefenseFalloff':5},
      'AMBITIOUS':{'CombatPercent':15,'OutsideFriendlyLandsModifier':-5}}
    for slot in range(1,8):promotion_defs['GUARD_ID_'+str(slot)]={}
    for name,extra in promotion_defs.items():
        fields={'Type':'PROMOTION_KINGDOMS_'+name,'Description':'TXT_KEY_KINGDOMS_PROMO_'+name,'Help':'TXT_KEY_KINGDOMS_PROMO_HELP_'+name,'CannotBeChosen':1,'LostWithUpgrade':0 if name not in ['CIVILWAR','RULER_COMBAT'] else 1,'LostOnGifting':1,'PortraitIndex':2,'IconAtlas':'KINGDOMS_OBJECT_ATLAS','PediaType':'PEDIA_ATTRIBUTES','PediaEntry':'TXT_KEY_KINGDOMS_PROMO_'+name,**extra}
        values=','.join("'"+v+"'" if isinstance(v,str) else str(v) for v in fields.values())
        effects.append('INSERT INTO UnitPromotions('+','.join(fields)+') VALUES ('+values+');')
    for size in [16,24,32,45,48,64,80,128,256]:
        effects.append(f"INSERT INTO IconTextureAtlases VALUES ('KINGDOMS_OBJECT_ATLAS',{size},'KingdomsObjects{size}.dds',2,2);")
        effects.append(f"INSERT INTO IconTextureAtlases VALUES ('KINGDOMS_ALPHA_ATLAS',{size},'KingdomsAlpha{size}.dds',1,1);")
    effects.append("INSERT INTO IconTextureAtlases VALUES ('KINGDOMS_UNIT_FLAG_ATLAS',32,'KingdomsUnitFlag32.dds',1,1);")
    (V/'02_Kingdoms_Effects.sql').write_text('\n'.join(effects)+'\n',encoding='utf-8')
    text={
      'CIV':'The Kingdoms','SHORT':'The Kingdoms','ADJECTIVE':'Royal','LEADER':'The Throne','TRAIT':'The Kingdoms United','GUARD':"The King's Guards",'WALL':"The Kingdom's Wall",'DUMMY':'Royal politics',
      'LEADER_PEDIA':'The Throne is the legal voice of a union of kingdoms. Its permanent diplomacy identity represents the realm; its actual kings and queens are generated by the political simulation and displayed in the Kingdoms Overview.',
      'CIV_PEDIA':'Each city is a Kingdom with competing noble Houses. Two founding Houses expand gradually toward seven as population grows. Houses have two persistent personalities, Loyalty, Influence, Prestige, relationships and claims. Their modest benefits grow with loyalty; the ruling House enhances its traditions throughout the realm. Prosperity brings demands and rival dynasties. A Farm demand requires two additional unpillaged Farms on owned plots assigned to that Kingdom, relative to the count when issued; existing valid Farms form the baseline, and citizens need not work them. Rulers reign for a game-speed-scaled lifetime. Stable realms choose a successor peacefully; fractured realms fight internal wars of succession. Civil wars begin with neutral royal backing until you support a coalition; choosing Neutral withdraws that backing without changing House Loyalty. No extra civilization slots are used. A persistent Chronicle records the history of Houses, rulers, wars and the seven named Guards.',
      'STRATEGY':'Build strong Kingdoms before expanding rapidly. Meet House demands, watch influential rivals, and preserve legitimacy. The Overview is available under the top panel. Treasury Gifts cost Gold; Estates cost Production; Charters and Military Authority strengthen future claimants. Save a treasury for succession crises.',
      'DAWN':'Many banners gather beneath one Crown. From Kings Throne, your noble Houses govern valleys, citadels and distant shores. You represent the Kingdoms themselves, beyond the lifetime of any ruler. Let prosperity unite the Houses, let your seven Guards defend the realm, and let the Chronicle remember a Crown won without the ruin of civil war.',
      'TRAIT_HELP':'Every city is a Kingdom with persistent noble Houses. Population gradually creates more Houses; their personalities grant modest effects and political demands. Loyalty weighted by Influence determines Stability. Generated rulers and powerful Houses provide separate bonuses. Stable successions are peaceful; fractured successions cause severe civil wars. Manage politics, named Guards and the Chronicle through the Kingdoms Overview.',
      'GUARD_PEDIA':"Elite replacements for Longswordsmen, unlocked at the active Longswordsman technology. Strength 28, normal Longswordsman cost, movement, resources, artwork and upgrade chain. Remain trainable in all later eras. At most seven living Guards, including pending appointments and upgraded Guards. Choose from up to three warriors from different active Houses; appointment grants the House +15 Loyalty and +8 Prestige. Each Guard receives a permanent personality promotion, name and House affiliation. Upgrades retain identity and count toward seven. Death frees a slot. In civil wars, disloyal families in rival coalitions may request a personal oath decision after you support a faction. Neutral backing creates no opposition crisis; Guards are never randomly stolen or deleted.",
      'GUARD_HELP':"28 Combat Strength. Maximum SEVEN living King's Guards, including upgrades and pending appointments. Remains trainable after later technologies. Choose a named House candidate and permanent personality promotion. Normal military upgrades preserve identity and affiliation.",
      'GUARD_STRATEGY':'Seven elite champions represent your Houses. Appoint warriors to balance military traits with noble loyalty. Upgrade them through the normal ruleset progression. Death frees a slot; queued excess completions are refunded.',
      'WALL_PEDIA':"Retains all active Walls defenses and companion effects. Adds +1 local Happiness, +2 Production and +5 local Kingdom Stability. A practical defense against both invaders and domestic discord.",
      'WALL_HELP':'Normal Walls effects, plus +1 Happiness, +2 Production and +5 Kingdom Stability.','WALL_STRATEGY':'Fortify each Kingdom to strengthen defense, production and the loyalty-weighted local Stability.',
      'TITLE':'THE KINGDOMS | THE REALM AND ITS HOUSES','INTERREGNUM':'Interregnum','UNKNOWN_HOUSE':'an unknown House','CAPITAL':'Kings Throne',
      'YEAR_BC':'{1_Num} BC','YEAR_AD':'{1_Num} AD','TURN':'Turn {1_Num}','KING_NAME':'King {1_Name} of House {2_House}','QUEEN_NAME':'Queen {1_Name} of House {2_House}','SER_NAME':'Ser {1_Name} {2_House}','LADY_NAME':'Lady {1_Name} {2_House}',
      'HOUSE_FOUNDED':'House {1_House} was founded in {2_Kingdom}.','HOUSE_SPLIT':'House {1_Parent} divided. House {2_House} was founded in {3_Kingdom}.','HEAD_CHANGED':'House {1_House} appointed {2_Name} as its head.',
      'RELATION_CHANGED':'House {1_House} and House {2_House} became {3_Relation}.','KINGDOM_FOUNDED':'{1_Kingdom} joined the realm as a Kingdom.',
      'CAPITAL_LOST':'{1_Capital} has fallen. Legitimacy and dynasty claims suffer; Realm Stability loses 20 for 20 Standard turns.','CAPITAL_RESTORED':'{1_Capital} has been restored. The Crown regains legitimacy.',
      'REALM_CRITICAL':'Realm Stability is critical. Demands, hostile Houses and succession may tear the realm apart.',
      'RULER_CROWNED':'{1_Ruler} ascends the Throne.','RULER_DIED':'{1_Ruler} died after a reign of {2_Turns} turns. The Kingdoms await a successor.','RULER_DEPOSED':'{1_Ruler} was deposed by a rebellion of the Houses.',
      'CIVIL_WAR_BEGAN':'War of Succession {1_Number} has begun. {2_Count} coalitions contest the Crown.','CIVIL_WAR_ENDED':'War of Succession {1_Number} ended after {3_Turns} turns. House {2_House} seized the Throne.',
      'FACTION_DEFECTED':'House {1_House} declared for the {2_Leader} coalition.','WAR_BATTLE':'At the Battle of Red Fields, House {1_Winner} defeated forces of House {2_Loser}.','WAR_INTRIGUE':'The allies of House {1_House} made a political breakthrough.',
      'WAR_TREASURY':'The royal treasury lost {1_Gold} Gold; House {2_House} gained strength.','WAR_KINGDOM':'The lords of {1_Kingdom} rallied to House {2_House}.','WAR_UNREST':'Unrest swept through the realm; House {1_House} consolidated its position.','RIOT':'The people of {1_Kingdom} riot. Rebel soldiers appear and local yields suffer temporarily.',
      'WAR_SUPPORTED':'The realm supported House {1_House}: {2_Action}.','WAR_NEUTRAL':'The realm withdrew faction backing and remained neutral.','APPEASED':'House {1_House} received {2_Action}.',
      'GUARD_CHOOSE':"A King's Guard must be chosen. Noble warriors seek appointment in the Guards tab.",'GUARD_CAP':'The seven Guard places are filled. Excess queued production has been refunded.',
      'GUARD_APPOINTED':"{1_Name} of House {2_House} joined the King's Guard.",'GUARD_FALLEN':"{1_Name}, member of the King's Guard, has fallen.",'GUARD_LEFT':'{1_Name} left royal service after a transfer to another owner.','GUARD_RETURNED':'{1_Name} returned to the family estates with royal permission.',
      'GUARD_OATH':"A question of loyalty: {1_Name}'s House opposes the Crown. Pay for continued service, permit a compensated return, or demand an oath in the Guards tab.",'OATH_KEPT':'{1_Name} swore a faithful oath.','OATH_FAILED':'{1_Name} resisted the oath, suffered wounds and lost movement for a turn.','OATH_PAID':'{1_Name} remained in royal service after a treasury payment.',
      'UNAVAILABLE':'This action is unavailable.','COOLDOWN':'Available in {1_Turns} turns.','NEED_GOLD':'Requires {1_Gold} Gold.','MILITARISTIC_ONLY':'Only Militaristic Houses may receive Military Authority.','NEED_ARMY':'Requires at least two military units.','ACTION_DONE':'The political decision has been recorded.',
      'ACTION_GIFT':'Treasury Gift','ACTION_ESTATES':'Grant Estates','ACTION_CHARTER':'Royal Charter','ACTION_AUTHORITY':'Military Authority',
      'ACTION_HELP_GIFT':'Pay {1_Gold} Gold for +{2_Loyalty} Loyalty and +{3_Influence} Influence. Ten Standard turns between House actions.',
      'ACTION_HELP_ESTATES':'Pay {1_Gold} Gold for +{2_Loyalty} Loyalty and +{3_Influence} Influence. The Kingdom loses 10% Production for twelve Standard turns.',
      'ACTION_HELP_CHARTER':'Pay {1_Gold} Gold for +{2_Loyalty} Loyalty, +{3_Influence} Influence, +6 Prestige and +8 future Claim.',
      'ACTION_HELP_AUTHORITY':'Pay {1_Gold} Gold for +{2_Loyalty} Loyalty and +{3_Influence} Influence. Grants +18 Claim to a potential rival dynasty.',
      'REFUSE':'Refuse current demand','REFUSE_HELP':'Refusal costs at least 22 Loyalty, more for Proud Houses and Arrogant or Paranoid rulers.',
      'WAR_ACTION_FUND':'Send Gold','WAR_ACTION_MILITARY':'Provide military supplies','WAR_ACTION_DENOUNCE':'Denounce rival coalitions','WAR_ACTION_CONCESSION':'Grant political concessions','WAR_ACTION_TREASURY':'Distribute the treasury','WAR_ACTION_ALLIANCE':'Negotiate a noble alliance','WAR_ACTION_NEUTRAL':'Remain neutral',
      'WAR_ACTION_HELP':'Pay {1_Gold} Gold for +{2_Strength} faction strength. Supporting a faction angers its rivals. Supplies also cost 10% Production for five Standard turns. Concessions cost 10% local Production for eight turns. Decisions have a four-turn cooldown.',
      'WAR_ACTION_HELP_NEUTRAL':'Withdraw faction backing at no Gold cost. House Loyalty, relations and faction strength are unchanged. Existing timed supply and concession effects expire normally. Decisions have a four-turn cooldown.',
      'OATH_KEEP':'Pay to retain the Guard','OATH_RETURN':'Permit return to House (retires unit)','OATH_OATH':'Demand an oath (risk of wounds)',
      'OATH_HELP_KEEP':'Pay {1_Gold} Gold. Keep the Guard; the House loses 5 Loyalty.','OATH_HELP_RETURN':'Retire this Guard with your permission. Gain 50 speed-scaled Gold, +12 House Loyalty and +4 Prestige. Frees a Guard place.',
      'OATH_HELP_OATH':'Success grants +8 House Loyalty. Failure costs 12 Loyalty, adds up to 20 damage (capped at 80% maximum HP without healing existing wounds), and ends movement. The Guard remains yours. Loyalty, trait, tenure, relationships and Prestige determine the chance.',
      'LAUNCHER':'Realm Stability: {1_Value} | {2_State} | KINGDOMS','SUMMARY':'{1_Ruler}[NEWLINE]Realm: {2_Value} ({3_State}) | Kingdoms: {4_Count} | Houses: {5_Count} | Guards: {6_Count}/7',
      'CURRENT_RULER':'CURRENT RULER: {1_Name}','REIGN':'Reign: {1_Turns} turns | Legitimacy: {2_Value}','TRAITS':'Traits: {1_Traits}',
      'RULER_EFFECTS':'Personal effects: +{1_Building}% building Production, {2_Science}% Science, {3_Gold}% Gold, {4_Production}% Production, {5_Military}% military Production. Other traits affect Stability, loyalty, faith or combat.',
      'REALM_STABILITY':'REALM STABILITY: {1_Value} | {2_State}','HOUSE_COUNTS':'Supportive Houses: {1_Loyal} | Neutral: {2_Neutral} | Hostile: {3_Hostile}','GUARD_COUNT':"King's Guards: {1_Count} / 7 places filled",
      'OVERVIEW_HELP':'Use Kingdoms to inspect Houses and demands, Succession to examine claims or influence civil wars, Guards to appoint champions and resolve loyalty decisions, and Chronicle to read the history. Influence percentages and claims are normalized scores. The current ruling House enhances its traditions across every Kingdom.',
      'KINGDOM_ROW':'{1_Name} | Pop {2_Pop} | {3_Count} Houses | Stability {4_Value}','NO_KINGDOMS':'No active Kingdoms. Historical Houses are retained during occupation or elimination.',
      'KINGDOM_DETAIL':'{1_Name}[NEWLINE]Population {2_Pop} | Stability {3_Value}: {4_State}[NEWLINE]{5_Houses} Houses; population target {6_Target}. New Houses form gradually.',
      'HOUSE_ROW':'House {1_Name}: {2_Influence}% Influence | Loyalty {3_Loyalty} | Prestige {4_Prestige}','INSPECT_HOUSE':'Inspect House {1_Name}','HOUSE':'HOUSE {1_Name}',
      'HOUSE_ORIGIN':'Origin: {1_Kingdom} | Founded {2_Date}','HERALDRY':'Heraldry: {1_Symbol} | Field {2_Field} | Color {3_Color}','FOUNDER':'Founder: {1_Name}','HEAD':'Current head: {1_Name}','PARENT':'Parent House: {1_House}','DESCENDANTS':'Split descendants: {1_Houses}',
      'HOUSE_STATS':'Influence {1_Influence}% | Loyalty {2_Loyalty} ({3_State})[NEWLINE]Prestige {4_Prestige} | Claim {5_Claim} | Power {6_Power}','HOUSE_HISTORY':'Rulers {1_Rulers} | Guards {2_Guards} | Wars supported {3_Wars}[NEWLINE]Demands completed {4_Completed} | Failed/refused {5_Failed}',
      'ACTIVE_DEMAND':'Demand: {1_Name}[NEWLINE]Progress {2_Progress}/{3_Target} | Expires in {4_Turns} turns','NO_DEMAND':'No active demand.','HOUSE_RELATION':'House {1_Name}: {2_State} ({3_Value})','HOUSE_TIMELINE':'RECENT HOUSE HISTORY',
      'WAR_DETAIL':'WAR OF SUCCESSION {1_Number}[NEWLINE]{2_Turns} turns elapsed | Forced resolution within {3_Remaining} turns','WAR_PENALTIES':'Civil war: -25% Food, -30% Production, -20% Gold, -15% Science, -15% combat strength and -3 global Happiness per Kingdom. Riots may worsen local penalties. All war penalties end when the conflict resolves.',
      'FACTION_ROW':'{1_House} coalition | {2_Percent}%','CLAIMANT':'Claimant: {1_Name}','MEMBERS':'Member Houses: {1_Houses}','PLAYER_SUPPORT':'Royal backing: {1_House} coalition','PLAYER_SUPPORT_NEUTRAL':'Royal backing: {1_State}','CLAIMS_HELP':'SUCCESSION CLAIMS[NEWLINE]Scores combine Prestige, Influence, House age, previous rulers, Guards, allies and dynasty continuity. Percentages show relative political weight. Stability below 45 causes a disputed succession. At 10 or lower, an extreme crisis may depose the ruler. These are political scores, not literal RNG odds.',
      'CLAIM_ROW':'House {1_House} | {2_Percent}%','GUARDS_HELP':'New Guards require an appointment. Pending appointments and upgraded units count toward seven. Each candidate strengthens a House; rivals lose a little Loyalty. Scroll down for personal loyalty decisions.','GUARD_CANDIDATES':'APPOINTMENT FOR UNIT {1_ID}','APPOINT_HELP':'Appointment: House {1_House} +15 Loyalty, +8 Prestige. Passed-over Houses lose 3 Loyalty.',
      'GUARD_DETAIL':'{1_Name}[NEWLINE]Trait: {2_Trait} | Appointed {3_Date}[NEWLINE]Kills {4_Kills} | Battles {5_Battles}','CHRONICLE_HELP':'CHRONICLE OF THE REALM[NEWLINE]Choose a category. Events are saved with the game; newest entries appear first.','UI_HINT':'Select a Kingdom or House. Political choices and the full Chronicle are saved with the game.',
    }
    for key,value in [('UNITED','United'),('STABLE','Stable'),('UNEASY','Uneasy'),('FRACTURED','Fractured'),('CRISIS','Succession Crisis'),('REBELLIOUS','Rebellious'),('DEVOTED','Devoted'),('LOYAL','Loyal'),('SUPPORTIVE','Supportive'),('NEUTRAL','Neutral'),('DISCONTENT','Discontent'),('HOSTILE','Hostile'),('REL_FEUD','Blood Feud'),('REL_RIVAL','Rivals'),('REL_DISTRUST','Distrustful'),('REL_NEUTRAL','Neutral'),('REL_FRIENDLY','Friendly'),('REL_ALLIED','Allied'),('REL_MARRIAGE','Marriage Alliance')]:text[key]=value
    for key,name in [('OVERVIEW','Overview'),('KINGDOMS','Kingdoms'),('SUCCESSION','Succession'),('GUARDS',"King's Guard"),('CHRONICLE','Chronicle')]:text['TAB_'+key]=name
    for key,name in [('ALL','All events'),('RULERS','Rulers'),('HOUSES','Houses'),('CIVILWARS','Civil Wars'),('GUARDS',"King's Guard"),('KINGDOMS','Kingdoms')]:text['FILTER_'+key]=name
    house_traits='Militaristic Agrarian Mercantile Expansionist Isolationist Traditionalist Religious Scholarly Ambitious Loyalist Opportunistic Proud Defensive Maritime Industrial Diplomatic Populist Zealous Cautious Honourable'.split()
    ruler_traits='Conqueror Architect Scholar Diplomat Steward Warrior Pious Popular Arrogant Cruel Indecisive Greedy Paranoid Reckless Weak Unpopular'.split()
    for name in house_traits:text['TRAIT_'+name.upper()]=name
    for name in ruler_traits:text['RULER_TRAIT_'+name.upper()]='The Conqueror' if name=='Conqueror' else name
    for name in 'Lion Stag Tower Sword Wolf Crown Raven Tree Horse Sun Moon Wyvern Eagle Rose'.split():text['SYMBOL_'+name.upper()]=name
    guard_help={'HONOURABLE':'+10% strength adjacent to a friendly unit.','BRUTAL':'+20% attack against wounded units.','PROTECTOR':'+25% strength defending a city.','DUELIST':'+15% attack.','COMMANDER':'Heals adjacent units by 5 HP per turn.','UNYIELDING':'+20% defense.','RIDER':'+1 Movement.','SIEGEBREAKER':'+20% attack against cities.','VETERAN':'+10% combat strength.','GUARDIAN':'+15% strength in friendly territory.','AGGRESSIVE':'+20% attack, -5% defense.','CAUTIOUS':'+25% defense against ranged attacks.','LOYAL':'+20% defense near the capital, diminishing by distance; better oath reliability.','AMBITIOUS':'+15% strength, -5% outside friendly lands; worse oath reliability.'}
    for name,help in guard_help.items():text['GUARD_TRAIT_'+name]=name.title();text['GUARD_TRAIT_HELP_'+name]=help
    for name in promotion_defs:
        if name.startswith('GUARD_ID_'):
            text['PROMO_'+name]='Royal Guard identity '+name[-1]
            text['PROMO_HELP_'+name]='Persistent royal-service slot. Retained through upgrades; counts toward the seven-Guard limit.'
            continue
        text['PROMO_'+name]=name.title() if name not in ['GUARD','PENDING','CIVILWAR','RULER_COMBAT'] else {'GUARD':"King's Guard",'PENDING':'Awaiting Appointment','CIVILWAR':'War of Succession','RULER_COMBAT':'The Conqueror'}[name]
        text['PROMO_HELP_'+name]=guard_help.get(name,{'GUARD':'One of seven permanent Guard identities. Retained through military upgrades.','PENDING':'Appoint a candidate in the Guards panel. Cannot attack before appointment.','CIVILWAR':'-15% combat strength during a civil war. Removed when the war ends.','RULER_COMBAT':'+5% combat strength while a Conqueror rules.'}.get(name,''))
    demands={'FARMS':'Build {1_Target} new Farms in this Kingdom','MINE':'Build a new Mine in this Kingdom','RESOURCE':'Improve a strategic resource in this Kingdom','BARRACKS':'Construct Barracks','MARKET':'Construct Market','LIBRARY':'Construct Library','SHRINE':'Construct Shrine','WALL':"Construct the Kingdom's Wall",'CULTURE':'Construct Monument','GROW':'Reach population {1_Target}','UNITS':'Train {1_Target} military units','GARRISON':'Station {1_Target} combat units near this Kingdom','ENEMY':'Kill {1_Target} enemy combat units','BARBARIANS':'Kill {1_Target} Barbarian combat units','CAMP':'Clear a Barbarian Camp','CAPTURE':'Capture an enemy city','WAR':'Declare war on the chosen rival','WAR_TURNS':'Remain at war with the chosen rival for {1_Target} turns','PEACE':'Make peace with the chosen rival','GOLD':'Accumulate {1_Target} Gold','FAITH':'Accumulate {1_Target} Faith','GPT':'Reach {1_Target} Gold per turn','TECH':'Research the selected technology','TRADE':'Maintain {1_Target} trade routes','EXPAND':'Found or acquire another Kingdom','GREAT_PERSON':'Generate a Great Person'}
    demands['FARMS']='Build {1_Target} new Farms on owned plots assigned to this Kingdom; they need not be worked'
    for key,value in demands.items():text['DEMAND_'+key]=value
    for name,verb in [('ISSUED','requests'),('COMPLETED','completed'),('FAILED','failed'),('REFUSED','refused'),('INVALID','withdrew an invalid demand')]:text['DEMAND_'+name]='House {1_House} '+verb+': {2_Demand}.'
    cities=['Kings Throne','Stormwatch','Riverhold','Goldmere','Ashenford','Highwall','Ravenbridge','Dawnspire','Stonehaven','Redwater','Crownreach','Silverhall','Northgate','Westwatch','Lionhold','Oakenmere','Brightvale','Ironford','Sunward','Mosskeep','Rosehaven','Caelbridge','Gildenfell','Windrest','Harrowmont','Emberwatch','Ivorykeep','Thornwall','Greyhaven','Wintercrest']
    for i,name in enumerate(cities):text['CITY_'+str(i)]=name
    sql=['INSERT INTO Language_en_US(Tag,Text) VALUES\n'+',\n'.join("('TXT_KEY_KINGDOMS_"+key+"','"+value.replace("'","''")+"')" for key,value in text.items())+';']
    for i in range(len(cities)):sql.append(f"INSERT INTO Civilization_CityNames VALUES ('CIVILIZATION_KINGDOMS','TXT_KEY_KINGDOMS_CITY_{i}');")
    # Generic medieval court dialogue, with no permanent named King.
    dialogue={'FIRST_GREETING':'Many banners, one Crown. The Kingdoms receive you at Kings Throne.','GREETING_NEUTRAL_HELLO':'The Throne hears your petition.','GREETING_POLITE_HELLO':'Our Houses welcome your friendship.','GREETING_HOSTILE_HELLO':'The Houses question your intentions.','DECLAREWAR':'Our banners are united. The Crown calls the Kingdoms to war.','ATTACKED':'You have awakened every citadel of the realm.','DEFEATED':'The banners fall, but the Chronicle will remember us.','TRADE_ACCEPT_ACCEPTABLE':'The royal council accepts these terms.','TRADE_REJECT_UNACCEPTABLE':'The Houses will not approve these terms.'}
    for key,value in dialogue.items():
        tag='TXT_KEY_KINGDOMS_DIPLO_'+key
        sql.append("INSERT INTO Language_en_US VALUES ('"+tag+"','"+value.replace("'","''")+"');")
    # Match installed diplomacy shape through explicit clone with custom response tags.
    for key in dialogue:
        sql += [f"CREATE TEMP TABLE KingdomsDialogue AS SELECT * FROM Diplomacy_Responses WHERE LeaderType='LEADER_ELIZABETH' AND ResponseType='RESPONSE_{key}';",f"UPDATE KingdomsDialogue SET LeaderType='LEADER_THE_THRONE',Response='TXT_KEY_KINGDOMS_DIPLO_{key}';",'INSERT INTO Diplomacy_Responses SELECT * FROM KingdomsDialogue;','DROP TABLE KingdomsDialogue;']
    sql.append("INSERT INTO Language_en_US VALUES ('TXT_KEY_CIVILOPEDIA_LEADERS_KINGDOMS_HEADING_1','The Throne'),('TXT_KEY_CIVILOPEDIA_LEADERS_KINGDOMS_TEXT_1','The permanent diplomatic voice of the Kingdoms. Open the Kingdoms Overview to see the actual reigning King or Queen.');")
    (V/'10_Kingdoms_Text.sql').write_text('\n'.join(sql)+'\n',encoding='utf-8')
    print('Generated inherited relations, 79 political buildings, 25 promotions and',len(text),'localized entries')

if __name__=='__main__':main()
