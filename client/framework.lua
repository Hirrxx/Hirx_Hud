HudFramework = {
    name = 'standalone',
    hunger = 100,
    playerLoaded = false
}

local function clampPercent(val)
    local num = tonumber(val) or 0
    if num < 0 then return 0 end
    if num > 100 then return 100 end
    return math.floor(num + 0.5)
end

local function detectFramework()
    if Config.Framework ~= 'auto' then
        return string.lower(Config.Framework)
    end

    if GetResourceState('es_extended') == 'started' then
        return 'esx'
    end

    if GetResourceState('qb-core') == 'started' or GetResourceState('qbx_core') == 'started' then
        return 'qbcore'
    end

    return 'standalone'
end

local function setupESX()
    local ESX = nil
    local ok, obj = pcall(function()
        return exports['es_extended']:getSharedObject()
    end)
    if ok and obj then
        ESX = obj
    else
        TriggerEvent('esx:getSharedObject', function(sharedObj)
            ESX = sharedObj
        end)
    end

    if ESX and ESX.IsPlayerLoaded and ESX.IsPlayerLoaded() then
        HudFramework.playerLoaded = true
        TriggerEvent('esx_status:getStatus', 'hunger', function(status)
            if status then
                local pct = status.getPercent and status.getPercent() or (status.val and (status.val / 10000)) or 100
                HudFramework.hunger = clampPercent(pct)
            end
        end)
    end

    RegisterNetEvent('esx:playerLoaded', function()
        HudFramework.playerLoaded = true
    end)

    RegisterNetEvent('esx:onPlayerLogout', function()
        HudFramework.playerLoaded = false
    end)

    AddEventHandler('esx_status:onTick', function(data)
        if type(data) ~= 'table' then return end
        for i = 1, #data do
            local status = data[i]
            if status and status.name == 'hunger' then
                local pct = status.percent
                if pct == nil and status.val ~= nil then
                    pct = status.val / 10000
                end
                if pct ~= nil then
                    HudFramework.hunger = clampPercent(pct)
                end
                break
            end
        end
    end)
end

local function applyQBCoreData(playerData)
    if type(playerData) ~= 'table' then return end
    if playerData.metadata and playerData.metadata.hunger ~= nil then
        HudFramework.hunger = clampPercent(playerData.metadata.hunger)
    end
end

local function setupQBCore()
    local QBCore = nil
    if GetResourceState('qb-core') == 'started' then
        local ok, obj = pcall(function()
            return exports['qb-core']:GetCoreObject()
        end)
        if ok and obj then
            QBCore = obj
        end
    end

    if QBCore and QBCore.Functions and QBCore.Functions.GetPlayerData then
        local data = QBCore.Functions.GetPlayerData()
        if data and data.citizenid then
            HudFramework.playerLoaded = true
            applyQBCoreData(data)
        end
    elseif LocalPlayer and LocalPlayer.state and LocalPlayer.state.isLoggedIn then
        HudFramework.playerLoaded = true
    end

    RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
        HudFramework.playerLoaded = true
        if QBCore and QBCore.Functions and QBCore.Functions.GetPlayerData then
            applyQBCoreData(QBCore.Functions.GetPlayerData())
        end
    end)

    RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
        HudFramework.playerLoaded = false
    end)

    RegisterNetEvent('QBCore:Player:SetPlayerData', function(val)
        applyQBCoreData(val)
    end)

    RegisterNetEvent('hud:client:UpdateNeeds', function(newHunger)
        if newHunger ~= nil then
            HudFramework.hunger = clampPercent(newHunger)
        end
    end)
end

CreateThread(function()
    HudFramework.name = detectFramework()

    if HudFramework.name == 'esx' then
        setupESX()
    elseif HudFramework.name == 'qbcore' then
        setupQBCore()
    else
        HudFramework.playerLoaded = true
    end
end)
