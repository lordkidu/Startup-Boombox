ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

local BOOMBOX_ITEM = "boombox" -- nom exact de ton item

ESX.RegisterUsableItem(BOOMBOX_ITEM, function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    TriggerClientEvent("boombox:client:useBoombox", source)
    xPlayer.removeInventoryItem(BOOMBOX_ITEM, 1)
end)

RegisterServerEvent("boombox:server:pickupBoombox")
AddEventHandler("boombox:server:pickupBoombox", function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local item = xPlayer.getInventoryItem("boombox")
    if item.count == 0 then
        xPlayer.addInventoryItem("boombox", 1)
    end
    TriggerClientEvent("boombox:client:removeBoombox", src)
end)

local BOOMBOX_MAX_DISTANCE = Config.Sound.MaxDistance

RegisterServerEvent("boombox:playSound")
AddEventHandler("boombox:playSound", function(url, coords)
    for _, playerId in ipairs(GetPlayers()) do
        local ped = GetPlayerPed(playerId)
        local playerCoords = GetEntityCoords(ped)
        local dist = #(playerCoords - vector3(coords.x, coords.y, coords.z))
        if dist <= BOOMBOX_MAX_DISTANCE then
            TriggerClientEvent("boombox:client:playSound", playerId, url, coords)
        end
    end
end)

RegisterServerEvent("boombox:stopSound")
AddEventHandler("boombox:stopSound", function(coords)
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
    for _, playerId in ipairs(GetPlayers()) do
        local ped = GetPlayerPed(playerId)
        local playerCoords = GetEntityCoords(ped)
        local dist = #(playerCoords - vector3(coords.x, coords.y, coords.z))
        if dist <= BOOMBOX_MAX_DISTANCE then
            TriggerClientEvent("boombox:client:pauseSound", playerId)
        end
    end
end)

RegisterServerEvent("boombox:resumeSound")
AddEventHandler("boombox:resumeSound", function(coords)
    for _, playerId in ipairs(GetPlayers()) do
        local ped = GetPlayerPed(playerId)
        local playerCoords = GetEntityCoords(ped)
        local dist = #(playerCoords - vector3(coords.x, coords.y, coords.z))
        if dist <= BOOMBOX_MAX_DISTANCE then
            TriggerClientEvent("boombox:client:resumeSound", playerId)
        end
    end
end)

RegisterServerEvent("boombox:server:giveBoomboxIfNeeded")
AddEventHandler("boombox:server:giveBoomboxIfNeeded", function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local items = xPlayer.getInventoryItem("boombox")

    if items.count == 0 then
        xPlayer.addInventoryItem("boombox", 1)
        TriggerClientEvent('chat:addMessage', src, { args = { '^2Boombox has been given back to you on reconnect.' } })
    end
end)
