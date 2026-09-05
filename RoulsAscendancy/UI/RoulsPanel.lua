include("InstanceManager")
-- One entry point loads all gameplay even when the active human is another civ.
include("RoulsCore")
include("RoulsActions")
local R=MapModData.Rouls
local entries=InstanceManager:new("RoulsUnitEntry","UnitButton",Controls.UnitStack)
local open,dirty,refreshing=false,true,false
local mode,first,second,victim="swap",nil,nil,nil
local message=""
local function player() local id=Game.GetActivePlayer(); return id,Players[id] end
local function clear() first,second,victim=nil,nil,nil; message=""; dirty=true end
local function name(u)
    return u:GetName().."  ("..u:GetX()..","..u:GetY()..")  XP "..u:GetExperience()
end
local function selection(p,id) return id and p:GetUnitByID(id) or nil end
local function refresh()
    if refreshing then return end
    refreshing=true; dirty=false
    local id,p=player()
    local visible=p and p:IsAlive() and R.IsRouls(p) and not (Game.IsNetworkMultiPlayer and Game.IsNetworkMultiPlayer())
    Controls.AnimaButton:SetHide(not visible)
    Controls.MainPanel:SetHide(not visible or not open)
    if not visible then refreshing=false; return end
    local s=R.GetState(id)
    local reserve="Anima: "..R.GetAnima(id).." / "..R.GetCap(id)
    Controls.AnimaButton:SetText("[ICON_RESEARCH] "..reserve)
    Controls.AnimaButton:SetToolTipString("Consciousness harvested from enemy military losses. Rebirth costs 1 Anima (twice per turn); TRANSMIGRATION costs 2, or 1 near a Matriarch. Click to command the Choir.")
    Controls.ReserveLabel:SetText(reserve)
    if not open then refreshing=false; return end
    local cooldown=math.max(0,(s.swapReadyTurn or 0)-Game.GetGameTurn())
    local buddy=s.buddy and ("Buddy returns in "..math.max(0,s.buddy.readyTurn-Game.GetGameTurn()).." turns; requires a free coastal berth.") or "Buddy has no return pending."
    Controls.StatusLabel:SetText("TRANSMIGRATION: "..(cooldown==0 and "ready" or cooldown.." turns")
        .."   |   Rebirths: "..(s.rebirthTurn==Game.GetGameTurn() and s.rebirthCount or 0).." / 2[NEWLINE]"
        .."Great Migration: "..(s.migrationUsed and "already used" or (p:GetCurrentEra()<GameInfoTypes.ERA_MODERN and "unlocks in Modern Era" or "available at 7 Anima")).."[NEWLINE]"..buddy)
    entries:ResetInstances()
    local units={}
    if mode=="swap" then
        Controls.InstructionLabel:SetText("Choose two of your units. Land exchanges with land; ships with ships. A Matriarch within 2 tiles of either unit reduces the cost to 1.")
        for u in p:Units() do if R.SwapEligible(id,u) then units[#units+1]=u end end
        table.sort(units,function(a,b) return a:GetID()<b:GetID() end)
    else
        Controls.InstructionLabel:SetText("Choose a visible enemy military unit within 3 tiles of your military. This once-per-game ability consumes 7 Anima. Confirm to consume its vessel.")
        for otherID=0,(GameDefines.MAX_PLAYERS or 64)-1 do
            local other=Players[otherID]
            if other and other:IsAlive() and Teams[p:GetTeam()]:IsAtWar(other:GetTeam()) then
                for u in other:Units() do if R.CanMigrate(id,u) then units[#units+1]=u end end
            end
        end
        table.sort(units,function(a,b) return a:GetOwner()<b:GetOwner() or (a:GetOwner()==b:GetOwner() and a:GetID()<b:GetID()) end)
    end
    for _,u in ipairs(units) do
        local unitID,ownerID=u:GetID(),u:GetOwner()
        local selected=(mode=="swap" and (unitID==first or unitID==second)) or (mode=="migration" and victim and victim.owner==ownerID and victim.id==unitID)
        local e=entries:GetInstance()
        e.UnitButton:SetText((selected and "[ICON_CHECKBOX] " or "")..name(u))
        e.UnitButton:RegisterCallback(Mouse.eLClick,function()
            if mode=="swap" then
                if unitID==first then first=second; second=nil
                elseif unitID==second then second=nil
                elseif not first then first=unitID else second=unitID end
            else victim={owner=ownerID,id=unitID} end
            message=""; dirty=true
        end)
    end
    Controls.UnitStack:CalculateSize(); Controls.UnitStack:ReprocessAnchoring(); Controls.UnitScroll:CalculateInternalSize()
    local ok,why,cost=false,"Choose units above.",nil
    if mode=="swap" then
        if first and second then ok,why,cost=R.CanSwap(id,selection(p,first),selection(p,second)) end
        Controls.ConfirmButton:SetText(cost and "Exchange: "..cost.." Anima" or "Exchange selected units")
    else
        if victim then local owner=Players[victim.owner]; ok,why=R.CanMigrate(id,owner and owner:GetUnitByID(victim.id)) end
        Controls.ConfirmButton:SetText("Consume vessel: 7 Anima")
    end
    Controls.ConfirmButton:SetDisabled(not ok)
    Controls.ConfirmButton:SetToolTipString(why or "Both movement and attacks are exhausted until your next turn.")
    Controls.MessageLabel:SetText(message~="" and message or (#units==0 and "No eligible units. Check the reserve, cooldown and target requirements." or (why or "Ready. Confirm to activate.")))
    refreshing=false
end
Controls.AnimaButton:RegisterCallback(Mouse.eLClick,function() open=not open; dirty=true end)
Controls.CloseButton:RegisterCallback(Mouse.eLClick,function() open=false; dirty=true end)
Controls.ClearButton:RegisterCallback(Mouse.eLClick,clear)
Controls.SwapTab:RegisterCallback(Mouse.eLClick,function() mode="swap"; clear() end)
Controls.MigrationTab:RegisterCallback(Mouse.eLClick,function() mode="migration"; clear() end)
Controls.ConfirmButton:RegisterCallback(Mouse.eLClick,function()
    local id=player(); local ok,result
    if mode=="swap" and first and second then ok,result=R.DoSwap(id,first,second)
    elseif mode=="migration" and victim then ok,result=R.DoMigration(id,victim.owner,victim.id) end
    if ok then clear() end
    message=result or "Select eligible units first."; dirty=true
end)
local function markDirty() dirty=true end
LuaEvents.RoulsStateChanged.Add(markDirty)
Events.SerialEventGameDataDirty.Add(markDirty)
Events.SerialEventUnitInfoDirty.Add(markDirty)
Events.GameplaySetActivePlayer.Add(function() open=false; clear() end)
Events.ActivePlayerTurnStart.Add(markDirty)
Events.ActivePlayerTurnEnd.Add(function() open=false; clear() end)
ContextPtr:SetInputHandler(function(uiMsg,key)
    if open and uiMsg==KeyEvents.KeyDown and key==Keys.VK_ESCAPE then open=false; dirty=true; return true end
    return false
end)
local elapsed=0
ContextPtr:SetUpdate(function(dt)
    elapsed=elapsed+dt
    if dirty and elapsed>=0.15 then elapsed=0; refresh() end
end)
refresh()
