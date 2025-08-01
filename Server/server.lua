ESX = nil
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

local BOOMBOX_ITEM = "boombox" -- nom exact de ton item
local BOOMBOX_MAX_DISTANCE = Config.Sound.MaxDistance

local currentSound = {
    url = nil,
    startTime = nil, -- timestamp serveur (os.time())
    paused = false,
    pauseTime = nil,
    coords = nil
}

ESX.RegisterUsableItem(BOOMBOX_ITEM, function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    TriggerClientEvent("boombox:client:useBoombox", source)
    xPlayer.removeInventoryItem(BOOMBOX_ITEM, 1)
end)

RegisterServerEvent("boombox:server:pickupBoombox")
AddEventHandler("boombox:server:pickupBoombox", function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local item = xPlayer.getInventoryItem(BOOMBOX_ITEM)
    if item.count == 0 then
        xPlayer.addInventoryItem(BOOMBOX_ITEM, 1)
    end
    TriggerClientEvent("boombox:client:removeBoombox", src)
end)

RegisterServerEvent("boombox:playSound")
AddEventHandler("boombox:playSound", function(url, coords)
    currentSound.url = url
    currentSound.startTime = os.time()
    currentSound.paused = false
    currentSound.pauseTime = nil
    currentSound.coords = coords

    for _, playerId in ipairs(GetPlayers()) do
        local ped = GetPlayerPed(playerId)
        local playerCoords = GetEntityCoords(ped)
        local dist = #(playerCoords - vector3(coords.x, coords.y, coords.z))
        if dist <= BOOMBOX_MAX_DISTANCE then
            TriggerClientEvent("boombox:client:playSound", playerId, url, coords, 0)
        end
    end
end)

RegisterServerEvent("boombox:stopSound")
AddEventHandler("boombox:stopSound", function(coords)
    currentSound = {url = nil, startTime = nil, paused = false, pauseTime = nil, coords = nil}
    for _, playerId in ipairs(GetPlayers()) do
        local ped = GetPlayerPed(playerId)
        local playerCoords = GetEntityCoords(ped)
        local dist = #(playerCoords - vector3(coords.x, coords.y, coords.z))
        if dist <= BOOMBOX_MAX_DISTANCE then
            TriggerClientEvent("boombox:client:stopSound", playerId)
        end
    end
end)

RegisterServerEvent("boombox:pauseSound")
AddEventHandler("boombox:pauseSound", function(coords)
    if not currentSound.paused and currentSound.startTime then
        currentSound.paused = true
        currentSound.pauseTime = os.time()
        for _, playerId in ipairs(GetPlayers()) do
            local ped = GetPlayerPed(playerId)
            local playerCoords = GetEntityCoords(ped)
            local dist = #(playerCoords - vector3(coords.x, coords.y, coords.z))
            if dist <= BOOMBOX_MAX_DISTANCE then
                TriggerClientEvent("boombox:client:pauseSound", playerId)
            end
        end
    end
end)

RegisterServerEvent("boombox:resumeSound")
AddEventHandler("boombox:resumeSound", function(coords)
    if currentSound.paused and currentSound.pauseTime then
        local pausedDuration = os.time() - currentSound.pauseTime
        currentSound.startTime = currentSound.startTime + pausedDuration
        currentSound.paused = false
        currentSound.pauseTime = nil

        for _, playerId in ipairs(GetPlayers()) do
            local ped = GetPlayerPed(playerId)
            local playerCoords = GetEntityCoords(ped)
            local dist = #(playerCoords - vector3(coords.x, coords.y, coords.z))
            if dist <= BOOMBOX_MAX_DISTANCE then
                local elapsed = os.time() - currentSound.startTime
                TriggerClientEvent("boombox:client:resumeSound", playerId, elapsed)
            end
        end
    end
end)

RegisterServerEvent("boombox:requestSync")
AddEventHandler("boombox:requestSync", function(coords)
    local src = source
    if currentSound.url and currentSound.startTime and not currentSound.paused then
        local elapsed = os.time() - currentSound.startTime
        TriggerClientEvent("boombox:client:playSound", src, currentSound.url, coords, elapsed)
    elseif currentSound.url and currentSound.paused then
        TriggerClientEvent("boombox:client:pauseSound", src)
    end
end)

RegisterServerEvent("boombox:server:giveBoomboxIfNeeded")
AddEventHandler("boombox:server:giveBoomboxIfNeeded", function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local items = xPlayer.getInventoryItem(BOOMBOX_ITEM)

    if items.count == 0 then
        xPlayer.addInventoryItem(BOOMBOX_ITEM, 1)
        TriggerClientEvent('chat:addMessage', src, { args = { '^2Boombox has been given back to you on reconnect.' } })
    end
end)
