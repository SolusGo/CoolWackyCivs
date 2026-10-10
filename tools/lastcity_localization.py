"""English localization source for generated Last City SQL."""
TEXT={
 'CIV':'The Last City — Humanity\'s Final Refuge','SHORT':'The Last City','ADJECTIVE':'Sanctuary',
 'LEADER':'The Warden','CAPITAL':'Last Light','TRAIT':'The Final Sanctuary',
 'TRAIT_HELP':'One permanent city. Cannot found more cities or capture enemy cities after founding Last Light. Defenders within three plots of the capital gain +15% Defense. Every fifth invasion is a Major Siege; each defeated Major Siege grants +2% City Defense, up to +30%. Refugees, Provisions, Housing, Morale and rationing are managed in the Sanctuary Council.',
 'CIV_PEDIA':'When the world fell, one city refused to die. Last Light shelters the remnants of humanity behind walls built from the ruins of vanished kingdoms. Its strength comes from the people it saves, and every new arrival must share its finite supplies. Its chronicles remember every siege and every difficult choice.',
 'LEADER_PEDIA':'The Warden holds no crown. The office exists to keep the gates standing, the wells clean and the last fires alight. Compassion and necessity contend at every council meeting. The Warden must protect Last Light without forgetting why it deserves to survive.',
 'STRATEGY':'Build the Sanctuary District, supply improvements and a defensive garrison early. Assign Farmers before population outruns Provisions; build housing before accepting large caravans. Preserve Last Watch survivors during Major Sieges to develop their veteran legacy. Prepare for the Dawn Initiative after twelve victories in the Atomic Era.',
 'DAWN':'When the world fell, one city refused to die. Warden, beyond your walls the old world is ash. At your gates stand the exhausted, the wounded and the hopeful. Feed them. Shelter them. Remember them. Let the last light become the first dawn.',
 'WATCH':'Last Watch','WATCH_HELP':'Replaces Spearman and retains its normal abilities. Shares the civilization\'s +15% local Defense bonus, without a duplicate bonus. Surviving Major Sieges while present within three plots of Last Light grants +3% local Defense per siege, up to +15%. Last Watch identity and veteran ranks persist through upgrades.',
 'WATCH_PEDIA':'Their oaths are carved into the stones of the gate. The Last Watch stands between the city and the long night. Experienced survivors carry their knowledge into every later generation of defenders.',
 'WATCH_STRATEGY':'Keep these defenders near Last Light during Major Sieges, and upgrade survivors to retain veteran ranks.',
 'DISTRICT':'Sanctuary District','DISTRICT_HELP':'Replaces Granary and retains all Granary effects. Adds +6 Housing and +2 Provisions per turn. Enables quarantine and Sanctuary infrastructure.',
 'DISTRICT_PEDIA':'A Granary became a shelter, a shelter became a neighborhood, and a neighborhood became the beating heart of Last Light. Here caravans are counted, supplies are shared and survivors rebuild their lives.',
 'DISTRICT_STRATEGY':'The foundation of refugee processing, housing and further survival infrastructure.',
 'DUMMY':'Sanctuary Council Effects','COUNCIL':'SANCTUARY COUNCIL','OVERVIEW':'City','REFUGEES':'Refugees','EXPERTS':'Experts','RATIONS':'Rations','BUILDINGS':'Works','CRISES':'Crises','HISTORY':'Chronicle',
 'FOUND_FIRST':'Found Last Light to establish the Sanctuary Council.','SAVE_UNSUPPORTED':'Last City save unavailable — see Lua log.',
 'STATUS':'Provisions {1_Num} | Morale {2_Num}',
 'DASHBOARD':'Population {1_Num} / Housing {2_Num} | Provisions {3_Num} / {4_Num}[NEWLINE]Income +{5_Num} | Consumption -{6_Num} | Net {7_Num} per turn',
 'MORALE_STATUS':'Morale {1_Num}: {2_Name} | Rations: {3_Name}',
 'WAVE_ACTIVE':'Wave {1_Num}: {2_Num} invaders remain','NEXT_WAVE':'Invasion in {1_Num} turns',
 'LEGACY_STATUS':'Victories {1_Num} | Major Sieges {2_Num} | Bosses {3_Num}[NEWLINE]Permanent City Defense +{4_Num}% | Military losses {5_Num}',
 'EXPERT_OVERVIEW':'Accepted caravans {1_Num} | Refusals {2_Num} | Shortage progression {3_Num}',
 'OVERVIEW_HELP':'The city survives through people, supplies and defenders. Completed Farms and Fishing Boats in its owned city radius yield Provisions. Combat units consume supplies even when exempt from Gold maintenance. The Chronicle records choices and consequences.',
 'UNITED':'United (+10% Production, +5% local Defense)','STABLE':'Stable','ANXIOUS':'Anxious (-5% Production)','UNREST':'Unrest (-15% Production)','BREAKING':'Breaking Point (-30% Production)',
 'GENEROUS':'Generous','STANDARD':'Standard','STRICT':'Strict','EMERGENCY':'Emergency',
 'RATION_HELP':'Select a policy to preview its effects, then confirm. Cooldown remaining: {1_Num} turns. Growth adjusts stored Food by a fraction of positive native surplus; shortages add a further penalty.',
 'RATION_PREVIEW':'{1_Name}: Consumption {2_Num}, Net {3_Num}[NEWLINE]Morale {4_Num}/turn | Surplus growth adjustment {5_Num}%',
 'RATION_WAIT':'Ration policy locked for {1_Num} more turns.','RATION_CHANGED':'Ration policy changed.',
 'EXPERTS_HELP':'Available experts are survivors, separate from normal city specialists. Assign up to five in each category. Unassigned survivors remain available. Losses remove available experts and reduce assignments when necessary.',
 'EXPERT_ROW':'{1_Name}: available {2_Num}, assigned {3_Num} / {4_Num}','EXPERT_CAP':'No available expert or assignment capacity.','ASSIGNMENT_CHANGED':'Council assignment changed.',
 'ENGINEERS':'Engineers','SCIENTISTS':'Scientists','PHYSICIANS':'Physicians','VETERANS':'Veterans','FARMERS':'Farmers','SCHOLARS':'Scholars',
 'SKILL_ENGINEERS':'+3% Production per assigned Engineer; maximum +15%.',
 'SKILL_SCIENTISTS':'+3% Science per assigned Scientist; maximum +15%.',
 'SKILL_PHYSICIANS':'Each assigned Physician reduces caravan disease risk, shortage mortality risk and outbreak treatment cost/severity. Maximum five.',
 'SKILL_VETERANS':'+2% Defense per assigned Veteran to combat units within three plots of Last Light; maximum +10%.',
 'SKILL_FARMERS':'+2 Provisions per turn per assigned Farmer; maximum +10.',
 'SKILL_SCHOLARS':'+3% Culture per assigned Scholar, and +0.08 Morale recovery per turn under safe, adequately supplied conditions; maximum five.',
 'ACCEPT':'Accept','QUARANTINE':'Quarantine','REFUSE':'Refuse','SELECT':'Preview','QUEUE':'Queue','BUILT':'Completed','CONFIRM':'CONFIRM COUNCIL DECISION',
 'SELECT_HELP':'Select an available decision to review its effects before confirming.','BUSY':'The Council is already processing a decision.','UNAVAILABLE':'This action is currently unavailable.','EVENT_EXPIRED':'This event has already been resolved or has expired.',
 'SUPPLIES_REQUIRED':'Requires {1_Num} Provisions.','PRODUCTION_REQUIRED':'Requires {1_Num} stored Production in the current build order.','MILITIA_REQUIRED':'Requires more than one Population and an empty, owned, passable nearby land plot.',
 'QUARANTINE_HOUSING':'Requires Sanctuary District or Refugee Barracks and no more than four Population above Housing after acceptance.',
 'ALREADY_QUARANTINED':'This caravan has already passed through quarantine.',
 'REFUGEE_ACCEPT':'Accept: +{1_Num} Population, +1 available {2_Name}, pay {3_Num} Provisions. Full risk unless already quarantined.',
 'REFUGEE_QUARANTINE':'Quarantine: pay {3_Num} Provisions now, delay processing, and reduce infectious risk. The remaining cost is due on acceptance.',
 'REFUGEE_REFUSE':'Refuse: no Population or expertise. Preserve supplies and lose 10 Morale. Earlier refusals can fuel later unrest.',
 'CARAVAN_DETAILS':'{1_Num} survivors | +{2_Num} Population | Expertise: {3_Name}',
 'NO_REFUGEES':'No caravan waiting. Estimated next arrival in {1_Num} turns.','REFUGEES_WAITING':'A refugee caravan waits at the gates.',
 'QUARANTINE_WAIT':'Quarantine completes in {1_Num} turns.','QUARANTINE_CLEARED':'Quarantine complete; the caravan awaits a final decision.',
 'ACCEPTED':'Refugees accepted.','REFUSED':'Refugees refused.','QUARANTINED':'Caravan quarantined.','CARAVAN_LEFT':'The caravan departed before a decision.','CARAVAN':'Caravan arrival','COMPLICATION':'Survivor consequence',
 'FOUNDED':'Last Light founded — the final sanctuary begins.','STARVATION_DEATH':'Population lost to sustained shortages.','PILLAGED':'Infrastructure was pillaged.','EXPERT_LOST':'Expert lost.','SOLDIER_LOST':'A defender fell.','CITY_RETURNED':'An additional city was returned.','EXTRA_CITY_PENDING':'An additional city awaits return.','CAPITAL_LOST':'Last Light has fallen.','RETURN_BLOCKED':'A gifted city has no living recipient. It remains an exceptional puppet; see engine limitations.',
 'WARNING':'An invasion approaches. Prepare the walls.','THREAT':'Estimated force: up to {1_Num} units. Assault in {2_Num} turns.',
 'ASSAULT':'The gates are under assault.','MAJOR_ASSAULT':'A Major Siege begins.','FINAL_NIGHT':'THE FINAL NIGHT — Humanity faces its greatest siege.',
 'SCAVENGERS':'Starving Scavengers','MARAUDERS':'Marauder Warbands','CULTS':'Siege Cults','PLAGUEBOUND':'The Plaguebound','REAVERS':'Iron Reavers','REMNANTS':'The Remnants','HARBINGERS':'The Harbingers',
 'HARROWER':'The Harrower','FINAL_COMMANDER':'The Extinguisher, Herald of the Final Night',
 'SIEGE_VICTORY':'The invasion was defeated. Last Light endures.','ENEMY_RETREAT':'The invasion withdrew or could not be confirmed defeated. No siege legacy was awarded.',
 'SPAWN_BLOCKED':'The approach is blocked. The invasion has been postponed; no survival reward was granted.',
 'HUMANITY_ENDURES':'HUMANITY ENDURES — Humanity has survived. Now it must learn to live again. Endless Survival continues; ordinary victory conditions remain available.',
 'DAWN_REQUIREMENTS':'Requires Atomic Era, twelve invasion victories, 55 Morale and 150 Provisions. The Dawn Initiative costs 900 base Production and consumes 150 Provisions when launched.',
 'DAWN_LOCKED':'The Dawn Initiative: reach Atomic Era, defeat twelve invasions, maintain 55 Morale and gather 150 Provisions, then construct the Initiative.',
 'DAWN_AWAITING_SUPPLIES':'The Dawn Initiative is built. Restore 55 Morale and 150 Provisions to launch the Final Night.',
 'DAWN_FINAL_PENDING':'The Dawn Initiative has launched. The Final Night is approaching.',
 'DAWN_FINAL_ACTIVE':'The Final Night is underway. Defeat every tagged attacker to achieve Humanity Endures.',
 'DAWN_ENDURES':'HUMANITY ENDURES. The city has survived the Final Night. Endless Survival continues.',
 'DAWN_LAUNCHED':'The Dawn Initiative launched. 150 Provisions committed; the Final Night approaches.',
 'DAWN_AWAITING':'The Dawn Initiative is complete but requires restored Morale and supplies.',
 'DISTRICT_REQUIRED':'Construct the Sanctuary District first.','TECH_REQUIRED':'Research the required technology first.',
 'BUILD_HELP':'Base Production cost: {1_Num}. Native game-speed Production scaling applies.','QUEUED':'Construction queued.','BUILDINGS_HELP':'These are unique, one-time infrastructure investments built through the normal Production queue. Confirming replaces the current queue; stored progress uses normal Civ V rules.',
 'CRISIS':'A city crisis','CRISIS_WAITING':'The Council must resolve a crisis.','NO_CRISIS':'No active crisis. The city has a moment to breathe.','CRISIS_RESOLVED':'Crisis resolved.',
 'COST':'Cost: {1_Num} Provisions and {2_Num} stored Production.','ASH_SOLUTION':'The accepted Engineers of Ash remember the old gateworks. Their expertise halves the supply cost of repairs.',
 'HISTORY_ROW':'Turn {1_Num}: {2_Name}[NEWLINE]{3_Name}',
 'CONCEPT_ECONOMY':'Provisions, Housing and Morale','CONCEPT_HELP_ECONOMY':'Provisions start at 45 with capacity 200. Base income is 4 per turn, plus 2 from the District, 1 per owned unpillaged Farm/Fishing Boats in the city radius, and 2 per assigned Farmer. Consumption is ceil(ceil(Population*0.6+combat units*0.4)*ration multiplier). Housing starts at 12; the District adds 6. Morale changes Production and local Defense.',
 'CONCEPT_REFUGEES':'Survivors at the Gates','CONCEPT_HELP_REFUGEES':'Caravans arrive about every 8–14 Standard turns after founding. Accept, quarantine or refuse them. Six separate expertise categories can each assign five survivors; assignments do not use normal specialist slots. Quarantine delays processing and reduces complication risk. Decisions are remembered across saves.',
 'CONCEPT_SIEGES':'The Endless Siege','CONCEPT_HELP_SIEGES':'The first invasion follows about 24 Standard turns after founding, with later waves about every 16–24 turns. Every fifth is a Major Siege. Failed spawns and timeouts grant no victories. The Harrower strengthens nearby invaders. The Atomic-era Dawn Initiative triggers the Final Night and a narrative achievement after a confirmed victory.',
}

INFRA={
 'BARRACKS':('Refugee Barracks','+4 Housing. Requires Masonry and Sanctuary District. Base cost: 100 Production.'),
 'RESIDENTIAL':('Expanded Residential Quarter','+8 Housing. Requires Engineering and Sanctuary District. Base cost: 220 Production.'),
 'SHELTER':('Underground Shelter','+10 Housing. Requires Dynamite and Sanctuary District. Base cost: 400 Production.'),
 'HOSPITAL':('Emergency Field Hospital','Medical mitigation equivalent to two assigned Physicians. Requires Biology and Sanctuary District. Base cost: 300 Production.'),
 'STORAGE':('Protected Storehouses','+75 Provisions capacity. Requires Metal Casting and Sanctuary District. Base cost: 240 Production.'),
 'DEPOT':('Deep Supply Depot','+100 Provisions capacity. Requires Railroad and Sanctuary District. Base cost: 450 Production.'),
 'WATER':('Reclaimed Waterworks','+4 Provisions per turn. Requires Chemistry and Sanctuary District. Base cost: 300 Production.'),
 'DAWN':('The Dawn Initiative','900 base Production. Requires Atomic Theory, Atomic Era, twelve confirmed invasion victories, 55 Morale and 150 Provisions. Launch spends 150 Provisions and triggers the Final Night. Defeat it to achieve Humanity Endures and continue Endless Survival.')}
for k,(name,help_text) in INFRA.items():TEXT['BUILDING_'+k]=name;TEXT['BUILDING_HELP_'+k]=help_text

CARAVANS={
 'ASH':('The Engineers of Ash','A caravan has escaped the machinery halls of a fallen industrial settlement. Its engineers bring blueprints and the memory of strong gates.'),
 'OBSERVATORY':('The Fallen Observatory','Astronomers carry rescued instruments under dust-stained blankets. One claims to have solved a problem the old world never could.'),
 'MERCY':('The Sisters of Mercy','A travelling clinic has crossed the wasteland. Its physicians ask for clean water and a place to lay their wounded.'),
 'BROKEN_BANNER':('The Broken Banner','Soldiers of a defeated garrison arrive with empty quivers. Their commander still knows how to hold a wall.'),
 'SEED':('The Keepers of Seed','Farmers have carried sealed jars through winter and ruin. Their seeds and knowledge could feed another generation.'),
 'ARCHIVE':('The Walking Archive','Teachers have memorized the books they could not carry. They offer stories, laws and a stubborn faith in civilization.'),
 'FEVER':('The Fever Road','An exhausted medical caravan approaches. Several children are feverish, and its physicians have used their last medicine.'),
 'SMUGGLERS':('The Lantern Smugglers','Mechanics pull carts covered in false bottoms. Their hidden cargo could replenish the stores, but trust is fragile.'),
 'HUNGRY':('The Hollow Harvest','A farming village has lost its last crop. Hunger has taught its survivors to take what they need.'),
 'EXILES':('The Exiles of the Forum','Scholars driven from a ruined republic debate at the gates. They will remember how the Warden treats the powerless.'),
 'CROWDED':('The Last Lecture Hall','Students and researchers arrive with their families. Their science is valuable; their numbers strain the shelters.'),
 'SILENT':('The Silent Patrol','A small patrol refuses to name its former commander. Its veterans may be protectors, or the eyes of an approaching army.')}
for k,(name,story) in CARAVANS.items():TEXT['CARAVAN_'+k]=name;TEXT['STORY_'+k]=story

RISKS={
 'DISEASE':'Risk: infectious illness may consume medical supplies, damage Morale and cost Population; Physicians and quarantine mitigate it.',
 'SMUGGLING':'Possible consequence: hidden supplies (+8 base Provisions) and distrust (-3 Morale).',
 'INFILTRATION':'Risk: enemy infiltration costs supplies and Morale, and increases later unrest pressure.',
 'OVERCROWDING':'Risk: housing tensions (-5 Morale), in addition to normal overcrowding penalties.',
 'UNREST':'Risk: political unrest. Earlier refusals make the consequences worse.',
 'THEFT':'Risk: hungry survivors steal 10 base Provisions.',
 'LEADERSHIP':'Possible benefit: skilled leadership adds 10 Morale.',
 'MEDICAL':'Possible benefit: an extra available Physician and +4 Morale.',
 'BRILLIANT':'Possible benefit: an extra available Scientist.',
 'COMMANDER':'Possible benefit: an extra available Veteran and +6 Morale.',
 'SUPPLIES':'Possible benefit: the caravan carries 20 base Provisions.'}
for k,v in RISKS.items():TEXT['RISK_'+k]=v

CRISES={
 'OUTBREAK':('Infectious Outbreak','The crowded infirmary reports a spreading fever.',[
  'Treat the outbreak: spend medical supplies, gain 3 Morale and reduce shortage progression. Physicians lower cost.',
  'Isolate the affected quarter: lose 4 Morale and 4 base Provisions.',
  'Let the fever run: lose up to 12 Morale; without three medical experts, lose one Population.']),
 'GATES':('The Gates Are Breaking','The outer gate shudders. There is little time to decide.',[
  'Reinforce the gates: spend 20 base Provisions and 20 base stored Production, repair 60 city damage, gain +20% City Defense for six base turns. Accepted Engineers of Ash halve the supply cost.',
  'Recruit emergency militia: lose one Population and 3 Morale; gain a temporary defender and +20% City Defense for six base turns.',
  'Abandon the outer wall: lose 15 Morale, suffer -20% City Defense for six base turns and lose two Housing until repaired (damage capped at four).']),
 'THEFT':('Food Store Theft','Supplies are disappearing from the protected stores.',[
  'Restore fair distribution: spend supplies and gain 5 Morale.',
  'Amnesty in exchange for return: lose 5 base Provisions and gain 2 Morale.',
  'Leave the theft unanswered: lose 12 base Provisions and 5 Morale.']),
 'DESERTION':('Military Desertion','Exhausted defenders are speaking of leaving their posts.',[
  'Care for the garrison: spend supplies and gain 8 Morale.',
  'Enforce the oath: lose 5 Morale, gain +20% City Defense for three base turns.',
  'Allow departures: lose a military unit if more than one remains, and 6 Morale.']),
 'PROTESTS':('Refugee Protests','Names of refused caravans are being read aloud in the square.',[
  'Hold a public council: spend supplies, gain 10 Morale and reduce the refusal grievance by two.',
  'Listen to their testimony: gain 2 Morale and reduce the refusal grievance by one.',
  'Close the square: lose 8 Morale.']),
 'SCIENTIST':('A Missing Scientist','One of the rescued researchers has vanished beyond the lower district.',[
  'Fund a search: spend supplies, recover the researcher and an apprentice, gain one available Scientist and 5 Morale.',
  'Let the community search: lose 3 Morale, preserve expertise.',
  'Abandon the search: lose one available Scientist and 4 Morale.']),
 'WATER_FAILURE':('Broken Water Infrastructure','The lower wells are fouled and a pressure main has burst.',[
  'Rebuild the water main: spend supplies, gain 4 Morale and end the disruption. Accepted Engineers of Ash reduce supply cost.',
  'Use temporary wells: -3 Provisions income for four base turns and -3 Morale.',
  'Ration clean water: -3 Provisions income for ten base turns, -8 Morale and an additional medical case.']),
 'DESPERATE':('A Desperate Caravan','Families caught between two raiding armies beg for shelter.',[
  'Open the gates: spend supplies, gain two Population, one available Farmer and 5 Morale.',
  'Offer directions and aid: gain 2 Morale; survivors remember the gesture.',
  'Refuse sanctuary: lose 10 Morale and add a refusal grievance.']),
 'LAST_HOSPITAL':('The Last Functioning Hospital','The old infirmary has only enough equipment for one more week.',[
  'Reequip the clinic: spend supplies, gain one available Physician and 5 Morale.',
  'Share the remaining equipment: spend 4 base Provisions and gain 1 Morale.',
  'Close the wards: lose one available Physician and 8 Morale.']),
 'CONSPIRACY':('An Internal Conspiracy','A secret faction is promising security without the Council.',[
  'Expose the conspirators through public testimony: spend supplies, gain 8 Morale and end infiltration.',
  'Offer reconciliation: lose 3 Morale and end infiltration.',
  'Ignore their organization: lose 10 Morale; infiltration persists for ten base turns.']),
 'HERO':('A Hero of the Last Watch','A defender has rescued families from a burning watchtower.',[
  'Honor the rescuer: spend supplies, gain 12 Morale and one available Veteran.',
  'Record the deed in the Chronicle: gain 6 Morale.',
  'Let the families remember privately: gain 2 Morale.']),
 'SUPPLY_CACHE':('Abandoned Supplies','Scouts have found sealed stores below an old railway station.',[
  'Equip a recovery expedition: spend 8 base Provisions, recover 40 and gain 5 Morale.',
  'Retrieve what is close to the entrance: gain 15 base Provisions.',
  'Leave it for wandering survivors: gain 3 Morale.']),
 'EXPERT_ACCIDENT':('The Sudden Loss of an Expert','A workshop collapse has trapped a member of the refugee council.',[
  'Fund an emergency rescue: spend supplies and gain 3 Morale; preserve expertise.',
  'Send the medical team: with two medical experts, preserve expertise and lose 2 Morale; otherwise lose the expert and 6 Morale.',
  'Accept the loss: lose the affected available expert and 6 Morale.']),
 'REBUILD':('Rebuilding a Damaged Quarter','Families are ready to clear the broken outer residences.',[
  'Fund reconstruction: spend supplies, restore all damaged Housing and gain 7 Morale.',
  'Organize volunteer crews: restore one Housing and gain 2 Morale.',
  'Leave the ruins: lose 5 Morale.']),
 'SIEGE_CHILD':('A Child Born During a Siege','Above the rumble of siege engines, the infirmary hears a newborn cry.',[
  'Share a small feast: spend supplies and gain 12 Morale.',
  'Name the child for the morning: gain 6 Morale.',
  'Keep the moment within the family: gain 2 Morale.'])}
for k,(name,story,choices) in CRISES.items():
 TEXT['CRISIS_'+k]=name;TEXT['CRISIS_STORY_'+k]=story
 for i,v in enumerate(choices,1):TEXT['CHOICE_'+k+'_'+str(i)]=v

PROMOS={
 'SANCTUARY':('The Final Sanctuary','+15% Defense while within three plots of Last Light. Refreshed on movement and turns.'),
 'NO_CONQUEST':('The Last Refuge','Cannot enter or capture enemy cities. The Last City may keep one permanent city.'),
 'WATCH':('Oath of the Last Watch','Eligible for persistent Major Siege veteran ranks. The oath survives upgrades.'),
 'RESOLVE':('United Resolve','+5% Defense within three plots of Last Light while Morale is at least 80.'),
 'INVADER':('Endless Siege','+10% Attack.'),'BOSS':('The Harrower','+25% Combat Strength, +35% City Attack; nearby tagged invasion troops receive +10% Combat Strength.'),
 'COMMAND':('Under the Harrower','+10% Combat Strength within two plots of the living wave commander; refreshed on turns.'),
 'PLAGUE':('The Plaguebound','Remaining within two plots of Last Light can spread a bounded infection. Physicians and the Hospital resist infection, reduce supply drain and shorten treatment.'),
 'ELITE':('Final Night Elite','+15% Combat Strength.')}
for n in range(1,6):
 PROMOS['VETERAN_'+str(n)]=(f'Watch Veteran {n}',f'Persistent record of {n} Major Sieges survived near Last Light. Grants +{3*n}% Defense locally through an active promotion.')
 PROMOS['VETERAN_ACTIVE_'+str(n)]=(f'Siege Experience +{3*n}%',f'+{3*n}% Defense within three plots of Last Light.')
 PROMOS['TRAINING_'+str(n)]=(f'Refugee Veteran Training +{2*n}%',f'+{2*n}% Defense within three plots of Last Light from assigned refugee Veterans.')
for k,(name,help_text) in PROMOS.items():TEXT['PROMO_'+k]=name;TEXT['PROMO_HELP_'+k]=help_text

for i,name in enumerate(['Ember','Greycloak','Dusk','Lantern','Cinder','Hope','Sparrow','Vigil','Ashen','Dawn'],1):TEXT['SPY_'+str(i)]=name
TEXT.update({
 'DIPLO_FIRST_GREETING':'We shelter those the world has forgotten. Approach our gates in peace.',
 'DIPLO_GREETING_NEUTRAL_HELLO':'The watch fires still burn. What do you seek?',
 'DIPLO_GREETING_POLITE_HELLO':'Your friendship brings warmth to a difficult night.',
 'DIPLO_GREETING_HOSTILE_HELLO':'Our walls remember the footsteps of our enemies.',
 'DIPLO_DECLAREWAR':'We fight so our people may live to see another morning.',
 'DIPLO_ATTACKED':'You have brought the long night to our gates. We will meet it.',
 'DIPLO_DEFEATED':'Remember the people who lived here. Let their light reach someone.'})
TEXT.update({
 'LAST_LIGHT_FALLEN':'THE LAST LIGHT HAS FALLEN[NEWLINE]The walls have been breached. The defenders are gone. The final sanctuary of humanity has fallen silent.',
 'WALLS_BREACHED':'THE WALLS ARE BREACHED[NEWLINE]Multiple invaders surround Last Light, the walls are near collapse and no defenders remain nearby. Restore a defender within two plots or repair the walls before the sanctuary falls.',
 'COLLAPSE_STATUS':'Military collapse: {1_Num} / {2_Num} consecutive turns. Repair the walls or return a combat defender within two plots immediately.',
 'SPAWN_BLOCKED':'No safe approach for a physical army. A siege blockade now drains Provisions and Morale and may damage shelter. Physical spawning will be retried; this encounter grants no military victory.',
 'PRESSURE_STATUS':'Siege blockade: {1_Num} turns remaining',
 'PRESSURE_ENDED':'The blockade lifts. Another physical invasion will be attempted shortly.',
 'BLOCKADE':'Saboteurs struck the sanctuary supply routes.',
 'ORPHAN_RELEASED':'An extra city with no living previous owner was released to a living custodian, or dismantled when no custodian existed. Last Light remains the only sanctuary.',
 'INFECTION':'PLAGUE AT THE GATES[NEWLINE]Plaguebound siege troops have infected the sanctuary. Assign Physicians or build the Hospital; emergency outbreak treatment can clear the infection.',
 'INFECTION_STATUS':'Infection severity {1_Num} / 4 | {2_Num} turns remaining[NEWLINE]Additional consumption {3_Num}/turn | Medical protection {4_Num}',
 'INFECTION_RECOVERED':'The sanctuary infection has ended. A short immunity period follows.',
 'INFECTION_DEATH':'An untreated severe infection claimed a civilian.',
 'HARROWER_DEFEATED':'THE HARROWER HAS FALLEN[NEWLINE]The invasion commander is dead. Morale +6. His command bonus ends; surviving attackers still threaten Last Light.',
 'OUTSKIRTS_RAID':'Enemies infiltrated the sanctuary outskirts. A smaller physical raid has appeared on empty owned plots at least three tiles from Last Light. The Final Night still requires its full-strength eligibility check.',
 'SKILL_PHYSICIANS':'Reduces refugee disease and starvation mortality. Resists Plaguebound infection, reduces severity and supply drain, and shortens treatment. Three medical protection speeds recovery. Maximum five assigned Physicians.',
 'REFUGEE_REFUSE':'Refuse the caravan. No Provisions cost; Morale -10. Previous quarantine costs are not refunded.',
 'BUILD_HELP':'Request this building through the native production queue. Current engine Production requirement: {1_Num}. The request replaces the existing queue.',
})
