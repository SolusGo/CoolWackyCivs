local C = MapModData.Capano
local I = C.IDs

-- A Route Setter needs a hill or adjacent mountain, and Sectors cannot touch.
local buildPlot = Map.GetPlot(4, 1)
assert(C.CanBuildSector(0, 3, 4, 1, I.BoulderBuild) == false)
buildPlot.hills = true
assert(C.CanBuildSector(0, 3, 4, 1, I.BoulderBuild) == true)
Map.GetPlot(5, 1).improvement = I.BoulderSector
assert(C.CanBuildSector(0, 3, 4, 1, I.BoulderBuild) == false)
Map.GetPlot(5, 1).improvement = -1

-- Four failures against this exact stronger unit produce the full Beta stack.
for attempt = 1, 4 do
    C.OnBattleStarted(0, 2, 1)
    C.OnBattleJoined(0, 1, 0, false)
    C.OnBattleJoined(1, 2, 1, false)
    if attempt > 1 then assert(attacker:IsHasPromotion(I.BetaAttack[attempt - 1])) end
    C.OnBattleFinished()
    local data = C.GetUnitState(attacker)
    assert(data.stacks == attempt and data.targetID == 2 and data.qualifies == 1)
    assert(attacker:IsHasPromotion(I.Beta[attempt]))
end

-- Fifth attempt carries +20%, and killing the difficult target earns SEND and
-- the once-per-player Ammagamma reward because it was 1.5x base strength.
C.OnBattleStarted(0, 2, 1)
C.OnBattleJoined(0, 1, 0, false)
C.OnBattleJoined(1, 2, 1, false)
assert(attacker:IsHasPromotion(I.BetaAttack[4]))
C.OnUnitPrekill(1, 2)
Players[1].units[2] = nil
C.OnBattleFinished()
local sent = C.GetUnitState(attacker)
assert(sent.stacks == 0 and sent.sends == 1)
assert(attacker:IsHasPromotion(I.Footwork))
assert(attacker.experience == 10 and attacker.damage == 5)
assert(Players[0].science == 530 and Players[0].culture == 530 and Players[0].golden == 8)

-- Switching targets starts a fresh Project instead of carrying Beta across.
local defenderB = NewUnit(1, 5, 100, Map.GetPlot(3, 1))
defenderB.defense = 1400
Players[1].units[5] = defenderB
C.OnBattleStarted(0, 3, 1)
C.OnBattleJoined(0, 1, 0, false)
C.OnBattleJoined(1, 5, 1, false)
for _, promo in ipairs(I.BetaAttack) do assert(not attacker:IsHasPromotion(promo)) end
C.OnBattleFinished()
assert(C.GetUnitState(attacker).targetID == 5 and C.GetUnitState(attacker).stacks == 1)

-- Sector training is once per era and Plastics permanently marks Yellow.
local sector = Map.GetPlot(6, 1)
sector.improvement, sector.owner = I.BoulderSector, 0
attacker:SetPlot(sector)
Teams[0].tech[I.Plastics] = true
C.TrainOnSector(0)
local trained = C.GetUnitState(attacker)
assert(attacker.experience == 15 and trained.lastTrainingEra == 2 and trained.yellow == 1)
assert(attacker:IsHasPromotion(I.ReadSequence) and attacker:IsHasPromotion(I.Yellow))
C.TrainOnSector(0)
assert(attacker.experience == 15)
Players[0].era = 3
C.TrainOnSector(0)
assert(attacker.experience == 20)

-- Friendly entry costs at most one movement point; hostile entry costs an
-- extra point and uses the post-Architecture Purple debuff.
C.OnPlayerDoTurn(0)
attacker.moves = 60
attacker:SetPlot(Map.GetPlot(7, 1))
Map.GetPlot(7, 1).improvement, Map.GetPlot(7, 1).owner = I.BoulderSector, 0
C.OnUnitSetXY(0, 1, 7, 1)
assert(attacker.moves == 120)

Teams[0].tech[I.Architecture] = true
C.OnPlayerDoTurn(1)
enemyMover.moves = 120
enemyMover:SetPlot(Map.GetPlot(6, 1))
C.OnUnitSetXY(1, 4, 6, 1)
assert(enemyMover.moves == 60 and enemyMover:IsHasPromotion(I.AwkwardPurple))

-- A unit trained in the Competition Centre activates its attack bonus after
-- two adjacent moves, and the marker survives while the active bonus resets.
local centrePlot = Map.GetPlot(0, 1)
local centre = NewCity(0, 1, centrePlot)
centre.buildings[I.CoachingCentre] = 1
Players[0].cities[1] = centre
local competitor = NewUnit(0, 6, 100, centrePlot)
Players[0].units[6] = competitor
C.OnCityTrained(0, 1, 6, false, false)
assert(competitor:IsHasPromotion(I.Competition))
C.OnPlayerDoTurn(0)
competitor.moves = 120; competitor:SetPlot(Map.GetPlot(1, 1)); C.OnUnitSetXY(0, 6, 1, 1)
competitor.moves = 60; competitor:SetPlot(Map.GetPlot(2, 1)); C.OnUnitSetXY(0, 6, 2, 1)
assert(competitor:IsHasPromotion(I.CompetitionActive))
C.OnPlayerDoTurn(0)
assert(competitor:IsHasPromotion(I.Competition) and not competitor:IsHasPromotion(I.CompetitionActive))

-- Custom AI modifiers read save-backed achievement/war/army state.
persisted.CAPANO_V1_HARD_WINS_1 = 3
assert(C.GetDiploModifier(I.DiploRespect, 0, 1) == 10)
C.OnDeclareWar(1, 0, true); C.OnMakePeace(1, 0)
C.OnDeclareWar(1, 0, true); C.OnMakePeace(1, 0)
assert(C.GetDiploModifier(I.DiploAbandoned, 0, 1) == -10)
for id = 10, 13 do
    local veteran = NewUnit(1, id, 100, Map.GetPlot(3, 2)); veteran.level = 4
    Players[1].units[id] = veteran
end
assert(C.GetDiploModifier(I.DiploStrong, 0, 1) == 5)
