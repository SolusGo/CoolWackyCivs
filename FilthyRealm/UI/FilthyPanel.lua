include("InstanceManager")
include("IconSupport")
include("FilthyRuntime")

local F = MapModData.FilthyRealm
local entries = InstanceManager:new("FilthyTargetEntry", "TargetButton", Controls.TargetStack)
local open, dirty, refreshing = false, true, false
local mode, selected, category, message = nil, nil, "GOLD", ""
local iconsReady = false

local function targetKey(target)
    if target.peace then return table.concat({"I", target.peace, target.owner, target.target}, ":") end
    return table.concat({"C", target.owner, target.id}, ":")
end

local function active()
    local playerID = Game.GetActivePlayer()
    return playerID, Players[playerID]
end
local function clearSelection()
    selected, message = nil, ""
    dirty = true
end
local function chooseMode(value)
    mode = value
    clearSelection()
end
local function cooldownText(playerID)
    local distortion = F.GetCooldown(playerID, "DISTORTION")
    local stop = F.GetCooldown(playerID, "STOP")
    return "Realm Distortion: " .. (distortion == 0 and "ready" or distortion .. " turns")
        .. "   |   It's Time to Stop: " .. (stop == 0 and "ready" or stop .. " turns")
        .. "[NEWLINE]Filth decays every 10 turns when trade, tourism and nearby military contact are all absent."
end
local function setCategory(value)
    category = value
    message = "Selected " .. value:lower() .. "."
    dirty = true
end
local function hookupIcons()
    if iconsReady then return end
    iconsReady = true
    IconHookup(7, 32, "FILTHY_OBJECT_ATLAS", Controls.PointsIcon)
    IconHookup(7, 32, "FILTHY_OBJECT_ATLAS", Controls.PanelPointsIcon)
    IconHookup(0, 64, "FILTHY_ICON_ATLAS", Controls.CivIcon)
    IconHookup(2, 45, "FILTHY_OBJECT_ATLAS", Controls.SalamanderIcon)
    IconHookup(4, 45, "FILTHY_OBJECT_ATLAS", Controls.DistortionIcon)
    IconHookup(5, 45, "FILTHY_OBJECT_ATLAS", Controls.RavioliIcon)
    IconHookup(6, 45, "FILTHY_OBJECT_ATLAS", Controls.StopIcon)
    IconHookup(0, 45, "FILTHY_OBJECT_ATLAS", Controls.InterventionIcon)
end
local function modeMark(value)
    return mode == value and "[ICON_CHECKBOX] " or ""
end

local function refresh()
    if refreshing then return end
    refreshing, dirty = true, false
    local playerID, player = active()
    local visible = player and player:IsAlive() and F.IsFilthy(player)
        and not (Game.IsNetworkMultiPlayer and Game.IsNetworkMultiPlayer())
    Controls.LauncherFrame:SetHide(not visible)
    Controls.MainPanel:SetHide(not visible or not open)
    if not visible then refreshing = false; return end
    hookupIcons()
    local points = F.GetPoints(playerID)
    local distortion = F.GetCooldown(playerID, "DISTORTION")
    local stop = F.GetCooldown(playerID, "STOP")
    Controls.PointsButton:SetText("ENTER THE FILTHY REALM  |  " .. points .. " FP")
    Controls.PointsButton:SetToolTipString("ENTER THE FILTHY REALM. Spend Filthy Points on active abilities and Peace Lord intervention.")
    Controls.PointsLabel:SetText(points .. " FP")
    if not open then refreshing = false; return end
    Controls.StatusLabel:SetText(cooldownText(playerID))
    Controls.SalamanderButton:SetText("SALAMANDER MAN  |  25 FP")
    Controls.DistortionButton:SetText(modeMark("distortion") .. "REALM DISTORTION  |  "
        .. (distortion == 0 and "40 FP" or distortion .. " TURNS"))
    Controls.RavioliButton:SetText(modeMark("ravioli") .. "RAVIOLI  |  60 FP")
    Controls.StopButton:SetText("IT'S TIME TO STOP  |  "
        .. (stop == 0 and "80 FP" or stop .. " TURNS"))
    Controls.InterventionButton:SetText(modeMark("intervention") .. "PEACE LORD: FILTHY INTERVENTION")
    Controls.SalamanderButton:SetToolTipString("25 FP: summon Salamander Man beside the Capital for 5 turns. His aura empowers friends and weakens enemies.")
    Controls.DistortionButton:SetToolTipString("40 FP: amplify one contaminated City's Filth penalties for 5 turns. 10-turn cooldown.")
    Controls.RavioliButton:SetToolTipString("60 FP: choose a foreign City and steal Gold, Science, Culture, Food, or Production.")
    Controls.StopButton:SetToolTipString("80 FP: exhaust nearby enemy military units and prevent their attacks. 20-turn cooldown.")
    Controls.InterventionButton:SetToolTipString("Choose a Peace Lord and an adjacent enemy below 30 HP, then force that enemy to retreat.")
    entries:ResetInstances()
    local targets = {}
    if mode == "distortion" then
        Controls.TargetHeader:SetText("TARGETING CONSOLE  |  REALM DISTORTION")
        Controls.InstructionLabel:SetText("Choose a foreign City with Filth. Penalties increase by 50% for 5 turns; your nearby units ignore Zone of Control.")
        targets = F.GetForeignCities(playerID, true)
    elseif mode == "ravioli" then
        Controls.TargetHeader:SetText("TARGETING CONSOLE  |  RAVIOLI")
        Controls.InstructionLabel:SetText("Choose a foreign City, then choose exactly which yield to steal. That City cannot be targeted again for 15 turns.")
        targets = F.GetForeignCities(playerID, false)
    elseif mode == "intervention" then
        Controls.TargetHeader:SetText("TARGETING CONSOLE  |  FILTHY INTERVENTION")
        Controls.InstructionLabel:SetText("Choose an eligible Peace Lord and adjacent enemy below 30 HP. The enemy retreats; the Peace Lord earns 10 FP and loses this action permanently.")
        targets = F.GetInterventionTargets(playerID)
    else
        Controls.TargetHeader:SetText("TARGETING CONSOLE")
        Controls.InstructionLabel:SetText("Choose an ability. Salamander Man and It's Time to Stop activate immediately; the others require a target below.")
    end
    for _, target in ipairs(targets) do
        local item, key = target, targetKey(target)
        local entry = entries:GetInstance()
        local label
        if mode == "intervention" then label = item.text
        else
            label = item.name .. " — Filth " .. item.level
            if item.cooldown and item.cooldown > 0 then label = label .. " — Ravioli cooldown " .. item.cooldown end
        end
        entry.TargetButton:SetText((selected == key and "[ICON_CHECKBOX] " or "") .. label)
        entry.TargetButton:RegisterCallback(Mouse.eLClick, function()
            selected = key
            message = "Selected " .. label .. "."
            dirty = true
        end)
    end
    Controls.TargetStack:CalculateSize()
    Controls.TargetStack:ReprocessAnchoring()
    Controls.TargetScroll:CalculateInternalSize()
    Controls.CategoryGrid:SetHide(mode ~= "ravioli")
    Controls.GoldButton:SetText((category == "GOLD" and "[ICON_CHECKBOX] " or "") .. "Gold")
    Controls.ScienceButton:SetText((category == "SCIENCE" and "[ICON_CHECKBOX] " or "") .. "Science")
    Controls.CultureButton:SetText((category == "CULTURE" and "[ICON_CHECKBOX] " or "") .. "Culture")
    Controls.FoodButton:SetText((category == "FOOD" and "[ICON_CHECKBOX] " or "") .. "Food")
    Controls.ProductionButton:SetText((category == "PRODUCTION" and "[ICON_CHECKBOX] " or "") .. "Production")
    Controls.ConfirmButton:SetHide(mode == nil)
    Controls.ConfirmButton:SetDisabled(selected == nil)
    Controls.ConfirmButton:SetText(mode == "distortion" and "Distort selected City — 40 FP"
        or mode == "ravioli" and "Steal " .. category:lower() .. " — 60 FP"
        or mode == "intervention" and "Force selected unit to retreat"
        or "Confirm")
    Controls.MessageLabel:SetText(message ~= "" and message
        or (#targets == 0 and mode and "No eligible targets at present." or ""))
    refreshing = false
end

local function useDirect(callback)
    local playerID = active()
    local ok, result = callback(playerID)
    message = result or "Ability failed."
    if ok then mode, selected = nil, nil end
    dirty = true
end
Controls.PointsButton:RegisterCallback(Mouse.eLClick, function() open = not open; dirty = true end)
Controls.CloseButton:RegisterCallback(Mouse.eLClick, function() open = false; dirty = true end)
Controls.SalamanderButton:RegisterCallback(Mouse.eLClick, function() useDirect(F.UseSalamander) end)
Controls.StopButton:RegisterCallback(Mouse.eLClick, function() useDirect(F.UseStop) end)
Controls.DistortionButton:RegisterCallback(Mouse.eLClick, function() chooseMode("distortion") end)
Controls.RavioliButton:RegisterCallback(Mouse.eLClick, function() chooseMode("ravioli") end)
Controls.InterventionButton:RegisterCallback(Mouse.eLClick, function() chooseMode("intervention") end)
Controls.GoldButton:RegisterCallback(Mouse.eLClick, function() setCategory("GOLD") end)
Controls.ScienceButton:RegisterCallback(Mouse.eLClick, function() setCategory("SCIENCE") end)
Controls.CultureButton:RegisterCallback(Mouse.eLClick, function() setCategory("CULTURE") end)
Controls.FoodButton:RegisterCallback(Mouse.eLClick, function() setCategory("FOOD") end)
Controls.ProductionButton:RegisterCallback(Mouse.eLClick, function() setCategory("PRODUCTION") end)
Controls.ConfirmButton:RegisterCallback(Mouse.eLClick, function()
    local playerID = active()
    local targets = mode == "intervention" and F.GetInterventionTargets(playerID)
        or F.GetForeignCities(playerID, mode == "distortion")
    local target = nil
    if selected then
        for _, candidate in ipairs(targets) do
            if targetKey(candidate) == selected then target = candidate; break end
        end
    end
    local ok, result = false, "Choose a target."
    if target and mode == "distortion" then ok, result = F.UseDistortion(playerID, target.owner, target.id)
    elseif target and mode == "ravioli" then ok, result = F.UseRavioli(playerID, target.owner, target.id, category)
    elseif target and mode == "intervention" then ok, result = F.UseIntervention(playerID, target.peace, target.owner, target.target) end
    message = result or "Ability failed."
    if ok then selected = nil end
    dirty = true
end)

local function markDirty() dirty = true end
LuaEvents.FilthyStateChanged.Add(markDirty)
Events.SerialEventGameDataDirty.Add(markDirty)
Events.SerialEventUnitInfoDirty.Add(markDirty)
Events.GameplaySetActivePlayer.Add(function() open, mode, selected = false, nil, nil; dirty = true end)
Events.ActivePlayerTurnStart.Add(markDirty)
Events.ActivePlayerTurnEnd.Add(function() open = false; dirty = true end)
ContextPtr:SetInputHandler(function(uiMsg, key)
    if open and uiMsg == KeyEvents.KeyDown and key == Keys.VK_ESCAPE then open = false; dirty = true; return true end
    return false
end)
local elapsed = 0
ContextPtr:SetUpdate(function(dt)
    elapsed = elapsed + dt
    if dirty and elapsed >= 0.15 then elapsed = 0; refresh() end
end)
refresh()
