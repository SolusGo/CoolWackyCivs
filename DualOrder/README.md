# The Dual Order

The Dual Order is Grandmaster Severin's military-religious civilization for Civilization V: Brave New World with the Community Patch. It rewards cities that maintain both halves of the realm, turns positive Faith into wartime cohesion, and uses Golden Ages as periods of concentrated military preparation.

## Unique ability — Twin Mandates

- Barracks, Armories, Temples, and their unique replacements provide +1 Production and +1 Faith.
- Normally trained military units gain Zeal when their city contains both military-training and religious infrastructure.
- Zeal grants +10% Combat Strength inside or adjacent to friendly territory and heals 10 HP after a kill. It persists through upgrades.
- While Faith per turn is positive, each civilization currently at war with the Dual Order grants +2% Combat Strength and +1% Production in all Cities, capped at five wars.
- During Golden Ages, Cities receive +25% Production toward military units and normally trained military units receive +5 XP.

The compact in-game Balance Pressure indicator reports the current faith gate, counted wars, combat bonus, and empire Production bonus.

## Unique unit — Divided Templar

The Divided Templar replaces the Longswordsman. It has 23 Combat Strength, costs 10% more Production, and begins with Cover I and Schism Strike. Schism Strike grants +20% attack strength against units below 50% HP and +10% Combat Strength while adjacent to a friendly Great Prophet, Missionary, or Inquisitor.

## Unique building — Hall of Concordance

The Hall of Concordance replaces the Armory and inherits all Community Patch Armory effects. It adds +3 Faith, +2 Production, and five more XP to trained units. A Hall provides +1 Happiness when its City follows the Dual Order's founded religion, and each Hall contributes +1 Great General Point per turn.

## Implementation notes

The unique unit and building are cloned at database activation, including their BNW and Community Patch companion-table rows. Lua controls position-sensitive promotions, below-half-health attack setup, faith-gated war tiers, dummy buildings, founded-religion Happiness, kill healing, Great General points, and the UI indicator. The project includes a deterministic Lua 5.1 mock and SQL validation against the installed Community Patch schema.

The concept sheet remains the canonical heraldry source. Its emblem is extracted without redesign for the civilization and alpha atlases; separate generated source art is retained for Grandmaster Severin, the Divided Templar, the Hall of Concordance, the Dawn of Man, and the civilization map.
