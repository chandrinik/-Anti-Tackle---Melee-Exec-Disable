local isScriptActive = false

LocalPlayer.state:set('isPvPOn', false, true)

local meleeControls = {
    0x2277FAE9,	--INPUT_MELEE_GRAPPLE--
    0x018C47CF,	--INPUT_MELEE_GRAPPLE_CHOKE--
    0x91C9A817,	--INPUT_MELEE_GRAPPLE_REVERSAL--
    0xB2F377E8,	--INPUT_MELEE_ATTACK--
    0xADEAF48C,	--INPUT_MELEE_GRAPPLE_ATTACK--
    0x07CE1E61,	--INPUT_ATTACK--
    0x0283C582	--INPUT_ATTACK2--
}

local function DrawNotification(text)
    SetTextScale(0.35, 0.35)
    SetTextFontForCurrentCommand(1)
    SetTextColor(255, 255, 255, 215)
    SetTextCentre(1)
    
    local str = CreateVarString(10, "LITERAL_STRING", text)
    DisplayText(str, 0.5, 0.90)
end

local function GetClosestPlayerWithinDistance(maxDistance)
    local myPed = PlayerPedId()
    local myCoords = GetEntityCoords(myPed)
    local activePlayers = GetActivePlayers()
    
    for _, playerId in ipairs(activePlayers) do
        local targetPed = GetPlayerPed(playerId)
        
        if targetPed ~= myPed and DoesEntityExist(targetPed) and not IsEntityDead(targetPed) then
            local targetCoords = GetEntityCoords(targetPed)
            local distance = #(myCoords - targetCoords)
            
            if distance <= maxDistance then
                return true
            end
        end
    end
    
    return false
end

RegisterCommand('togglemeleedisable', function()
    isScriptActive = not isScriptActive
    
    LocalPlayer.state:set('isPvPOn', isScriptActive, true)
    
    if isScriptActive then
        TriggerEvent('chat:addMessage', {
            color = {0, 255, 0},
            multiline = true,
            args = {"[System]", "PvP On."}
        })
    else
        TriggerEvent('chat:addMessage', {
            color = {255, 0, 0},
            multiline = true,
            args = {"[System]", "PvP Off."}
        })
    end
end, false)

RegisterKeyMapping('togglemeleedisable', 'Toggle Melee Disabler', 'keyboard', 'F4')

Citizen.CreateThread(function()
    while true do
        local sleep = 0
        local disableCombat = false
        
        local myPed = PlayerPedId()
        local myCoords = GetEntityCoords(myPed)
        
        local foundClosePlayer = false
        local foundProtectedPlayer = false

        for _, playerId in ipairs(GetActivePlayers()) do
            if playerId ~= PlayerId() then -- Αγνοούμε τον εαυτό μας
                local targetPed = GetPlayerPed(playerId)
                
                if DoesEntityExist(targetPed) and not IsEntityDead(targetPed) then
                    local distance = #(myCoords - GetEntityCoords(targetPed))
                    
                    if distance <= 6.0 then
                        foundClosePlayer = true
                        
                        local targetServerId = GetPlayerServerId(playerId)
                        if targetServerId > 0 and Player(targetServerId).state.isPvPOn == true then
                            foundProtectedPlayer = true
                        end
                    end
                end
            end
        end
        
        if isScriptActive and foundClosePlayer then
            disableCombat = true
            
        elseif not isScriptActive and foundProtectedPlayer then
            disableCombat = true
        end

        
        if disableCombat then
            sleep = 0
            
            for _, controlHash in ipairs(meleeControls) do
                DisableControlAction(0, controlHash, true)
            end
            
            DisablePlayerFiring(PlayerId(), true)
            
            DrawNotification("~COLOR_RED~Combat Disabled (PvP Rules)")
        end

        Citizen.Wait(sleep)
    end
end)