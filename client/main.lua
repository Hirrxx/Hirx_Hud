local STYLE_ALIASES = {
    ['1'] = 'minimal',
    ['minimal'] = 'minimal',
    ['2'] = 'rings',
    ['rings'] = 'rings',
    ['3'] = 'tactical',
    ['tactical'] = 'tactical'
}

local STYLE_ORDER = { 'minimal', 'rings', 'tactical' }

local function resolveStyleName(input)
    if type(input) ~= 'string' then return nil end
    return STYLE_ALIASES[string.lower(input)]
end

local savedStyle = GetResourceKvpString('hirx_hud_style')
local currentStyle = resolveStyleName(savedStyle) or resolveStyleName(Config.DefaultStyle) or 'minimal'

local nuiReady = false
local manualHidden = false
local isVisible = false
local voiceMode = 2
local maxObservedOxygen = Config.MaxOxygenTime or 10.0

local lastStatus = {
    hp = -1,
    armor = -1,
    food = -1,
    stamina = -1,
    oxygen = -1,
    talking = nil,
    voiceMode = -1
}

local lastVehicle = {
    showSpeedo = nil,
    speed = -1,
    gear = '',
    rpm = -1
}

local function clampPercent(val)
    if val < 0 then return 0 end
    if val > 100 then return 100 end
    return math.floor(val + 0.5)
end

local function pushConfig()
    SendNUIMessage({
        type = 'config',
        style = currentStyle,
        speedUnit = (Config.SpeedUnit == 'mph') and 'MPH' or 'KM/H',
        maxSpeed = Config.MaxSpeedDisplay or 240,
        voiceLabels = Config.VoiceLabels
    })
end

local function setHudStyle(styleInput)
    local resolved = resolveStyleName(styleInput)
    if not resolved then return false end

    currentStyle = resolved
    SetResourceKvp('hirx_hud_style', currentStyle)
    if nuiReady then
        pushConfig()
    end
    return true
end

local function nextStyle()
    for i = 1, #STYLE_ORDER do
        if STYLE_ORDER[i] == currentStyle then
            local nextIdx = (i % #STYLE_ORDER) + 1
            return STYLE_ORDER[nextIdx]
        end
    end
    return 'minimal'
end

local function setVisibility(visible)
    if isVisible == visible then return end
    isVisible = visible
    SendNUIMessage({
        type = 'visibility',
        visible = visible
    })
end

-- pma-voice: modo de voz actual
AddEventHandler('pma-voice:setTalkingMode', function(mode)
    local num = tonumber(mode)
    if num and num >= 1 and num <= 3 then
        voiceMode = num
    end
end)

CreateThread(function()
    Wait(500)
    if LocalPlayer and LocalPlayer.state and LocalPlayer.state.proximity then
        local prox = LocalPlayer.state.proximity
        if type(prox) == 'table' and prox.index then
            voiceMode = prox.index
        end
    end
end)

RegisterNUICallback('ready', function(_, cb)
    nuiReady = true
    pushConfig()
    SendNUIMessage({
        type = 'visibility',
        visible = isVisible
    })
    cb('ok')
end)

exports('SetHudStyle', setHudStyle)
exports('GetHudStyle', function()
    return currentStyle
end)
exports('SetHudVisible', function(state)
    manualHidden = not state
end)
exports('SetHunger', function(val)
    local num = tonumber(val)
    if num then
        HudFramework.hunger = clampPercent(num)
    end
end)

if Config.AllowStyleCommand then
    RegisterCommand(Config.StyleCommand, function(_, args)
        local target = args[1]
        if not target then
            target = nextStyle()
        end

        if setHudStyle(target) then
            local names = {
                minimal = '1 - Capsula Minimalista',
                rings = '2 - Anillos Circulares',
                tactical = '3 - Dock Tactico'
            }
            TriggerEvent('chat:addMessage', {
                color = { 255, 255, 255 },
                args = { '[hirx_hud]', 'Estilo cambiado a: ' .. (names[currentStyle] or currentStyle) }
            })
        else
            TriggerEvent('chat:addMessage', {
                color = { 255, 255, 255 },
                args = { '[hirx_hud]', 'Uso: /' .. Config.StyleCommand .. ' [1|2|3]' }
            })
        end
    end, false)
end

if Config.AllowToggleCommand then
    RegisterCommand(Config.ToggleCommand, function()
        manualHidden = not manualHidden
    end, false)
end

-- Hilo de estado del jugador (vida, armadura, comida, stamina, oxigeno, voz)
CreateThread(function()
    while true do
        local playerId = PlayerId()
        local ped = PlayerPedId()
        local shouldShow = not manualHidden and HudFramework.playerLoaded and DoesEntityExist(ped)

        if shouldShow and Config.HideWhenPaused and IsPauseMenuActive() then
            shouldShow = false
        end

        if nuiReady then
            setVisibility(shouldShow)
        end

        if shouldShow and nuiReady then
            local rawHp = GetEntityHealth(ped) - 100
            local maxHp = math.max(GetEntityMaxHealth(ped) - 100, 1)
            local hp = IsEntityDead(ped) and 0 or clampPercent((rawHp / maxHp) * 100)

            local armor = clampPercent(GetPedArmour(ped))
            local food = clampPercent(HudFramework.hunger)
            local stamina = clampPercent(100.0 - GetPlayerSprintStaminaRemaining(playerId))

            local oxygen = 100
            if IsPedSwimmingUnderWater(ped) then
                local remaining = GetPlayerUnderwaterTimeRemaining(playerId)
                if remaining > maxObservedOxygen then
                    maxObservedOxygen = remaining
                end
                oxygen = clampPercent((remaining / math.max(maxObservedOxygen, 1.0)) * 100)
            end

            local talking = NetworkIsPlayerTalking(playerId)

            if hp ~= lastStatus.hp
                or armor ~= lastStatus.armor
                or food ~= lastStatus.food
                or stamina ~= lastStatus.stamina
                or oxygen ~= lastStatus.oxygen
                or talking ~= lastStatus.talking
                or voiceMode ~= lastStatus.voiceMode
            then
                lastStatus.hp = hp
                lastStatus.armor = armor
                lastStatus.food = food
                lastStatus.stamina = stamina
                lastStatus.oxygen = oxygen
                lastStatus.talking = talking
                lastStatus.voiceMode = voiceMode

                SendNUIMessage({
                    type = 'status',
                    hp = hp,
                    armor = armor,
                    food = food,
                    stamina = stamina,
                    oxygen = oxygen,
                    talking = talking,
                    voiceMode = voiceMode
                })
            end

            Wait(Config.StatusTickMs)
        else
            Wait(250)
        end
    end
end)

-- Hilo del velocimetro (solo rapido cuando esta dentro de un vehiculo)
CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local inVeh = isVisible and DoesEntityExist(ped) and IsPedInAnyVehicle(ped, false)
        local showSpeedo = isVisible and (Config.AlwaysShowSpeedo or inVeh)

        if nuiReady then
            if showSpeedo and inVeh then
                local veh = GetVehiclePedIsIn(ped, false)
                local rawSpeed = GetEntitySpeed(veh)
                local mult = (Config.SpeedUnit == 'mph') and 2.236936 or 3.6
                local speed = math.floor((rawSpeed * mult) + 0.5)

                local rawGear = GetVehicleCurrentGear(veh)
                local gear = tostring(rawGear)
                if rawGear == 0 then
                    local vec = GetEntitySpeedVector(veh, true)
                    if vec.y < -0.35 then
                        gear = 'R'
                    else
                        gear = 'N'
                    end
                end

                local rpm = math.floor((GetVehicleCurrentRpm(veh) * 100) + 0.5)

                if showSpeedo ~= lastVehicle.showSpeedo
                    or speed ~= lastVehicle.speed
                    or gear ~= lastVehicle.gear
                    or math.abs(rpm - lastVehicle.rpm) >= 2
                then
                    lastVehicle.showSpeedo = showSpeedo
                    lastVehicle.speed = speed
                    lastVehicle.gear = gear
                    lastVehicle.rpm = rpm

                    SendNUIMessage({
                        type = 'vehicle',
                        show = true,
                        speed = speed,
                        gear = gear,
                        rpm = rpm
                    })
                end

                Wait(Config.VehicleTickMs)
            else
                if lastVehicle.showSpeedo ~= showSpeedo or (showSpeedo and lastVehicle.speed ~= 0) then
                    lastVehicle.showSpeedo = showSpeedo
                    lastVehicle.speed = 0
                    lastVehicle.gear = 'N'
                    lastVehicle.rpm = 0

                    SendNUIMessage({
                        type = 'vehicle',
                        show = showSpeedo,
                        speed = 0,
                        gear = 'N',
                        rpm = 0
                    })
                end

                Wait(250)
            end
        else
            Wait(250)
        end
    end
end)
