local boombox = nil
local boomboxObject = nil
local holdingBoombox = false
local soundName = "boombox_sound"
local currentDistance = Config.Sound.DefaultDistance
local lastUrl = nil
local lastPos = nil
local playing = false
local lastPlayedUrl = nil
local lastPlayedOffset = 0
local playTolerance = 2 -- secondes de tolérance pour éviter restart


-- Thread pour mise à jour position son
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(100)
        if holdingBoombox and boomboxObject and exports.xsound:soundExists(soundName) then
            exports.xsound:Position(soundName, GetEntityCoords(boomboxObject))
        elseif boombox and DoesEntityExist(boombox) and exports.xsound:soundExists(soundName) then
            exports.xsound:Position(soundName, GetEntityCoords(boombox))
        end
    end
end)

local function holdBoombox()
    if holdingBoombox then return end

    local playerPed = PlayerPedId()
    local model = GetHashKey("prop_boombox_01")

    RequestModel(model)
    while not HasModelLoaded(model) do Wait(0) end

    boomboxObject = CreateObject(model, 1.0, 1.0, 1.0, true, true, true)
    AttachEntityToEntity(boomboxObject, playerPed, GetPedBoneIndex(playerPed, 57005),
        0.15, 0.05, -0.05, -90.0, 0.0, 0.0, true, true, false, true, 1, true)
    holdingBoombox = true
end

local function pickupBoomboxInventory()
    if boombox and DoesEntityExist(boombox) then
        exports.ox_target:removeLocalEntity(boombox)
        DeleteEntity(boombox)
        boombox = nil

        if exports.xsound:soundExists(soundName) then
            exports.xsound:Destroy(soundName)
            playing = false
        end

        TriggerServerEvent("boombox:server:pickupBoombox")
        TriggerEvent('chat:addMessage', { args = { Config.Notifications.BoomboxInventoryPickup } })
    end
end

local function pickupBoomboxFromGround()
    if holdingBoombox then return end
    if boombox and DoesEntityExist(boombox) then
        exports.ox_target:removeLocalEntity(boombox)
        DeleteEntity(boombox)
        boombox = nil

        local playerPed = PlayerPedId()
        local model = GetHashKey("prop_boombox_01")

        RequestModel(model)
        while not HasModelLoaded(model) do Wait(0) end

        local radio = CreateObject(model, 1.0, 1.0, 1.0, true, true, true)

        TaskPlayAnim(playerPed, "pickup_object", "pickup_low", 8.0, 8.0, 2000, 50, 0, false, false, false)
        Citizen.Wait(2000)

        AttachEntityToEntity(radio, playerPed, GetPedBoneIndex(playerPed, 57005),
            0.32, 0.0, -0.05, 0.10, 270.0, 60.0, true, true, false, true, 1, true)

        boomboxObject = radio
        holdingBoombox = true

        TriggerEvent('chat:addMessage', { args = { Config.Notifications.BoomboxHeld } })
    end
end

local function spawnBoombox(coords)
    local model = GetHashKey("prop_boombox_01")

    if boombox and DoesEntityExist(boombox) then
        exports.ox_target:removeLocalEntity(boombox)
        DeleteEntity(boombox)
        boombox = nil
    end

    RequestModel(model)
    while not HasModelLoaded(model) do Wait(0) end

    boombox = CreateObject(model, coords.x, coords.y, coords.z - 1.0, true, true, true)
    PlaceObjectOnGroundProperly(boombox)
    FreezeEntityPosition(boombox, true)

    exports.ox_target:addLocalEntity(boombox, {
        {
            name = "open_radio_ui",
            icon = "fa-solid fa-music",
            label = "Open Radio",
            distance = Config.TargetDistance,
            onSelect = function()
                SetNuiFocus(true, true)
                SendNUIMessage({ type = "showUI", display = true })
            end
        },
        {
            name = "pickup_boombox_inventory",
            icon = "fa-solid fa-box",
            label = "Store in Inventory",
            distance = Config.TargetDistance,
            onSelect = function()
                pickupBoomboxInventory()
            end
        },
        {
            name = "pickup_boombox_hand",
            icon = "fa-solid fa-hand-paper",
            label = "Pick Up",
            distance = Config.TargetDistance,
            onSelect = function()
                pickupBoomboxFromGround()
            end
        }
    })
end

local function dropBoombox()
    if not holdingBoombox then return end
    local playerPed = PlayerPedId()
    local coords = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, 1.0, 0.0)

    if boomboxObject and DoesEntityExist(boomboxObject) then
        DetachEntity(boomboxObject, true, true)
        DeleteObject(boomboxObject)
        boomboxObject = nil
    end
    ClearPedTasks(playerPed)
    holdingBoombox = false

    spawnBoombox(vector3(coords.x, coords.y, coords.z))
    TriggerEvent('chat:addMessage', { args = { Config.Notifications.BoomboxPlaced } })
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if holdingBoombox then
            SetTextComponentFormat("STRING")
            AddTextComponentString(Config.TextHelpDropBoombox)
            DisplayHelpTextFromStringLabel(0, 0, 1, -1)

            if IsControlJustReleased(0, 38) then
                dropBoombox()
            end
        end
    end
end)

RegisterNetEvent("boombox:client:spawnBoombox")
AddEventHandler("boombox:client:spawnBoombox", function(coords)
    spawnBoombox(coords)
    TriggerEvent('chat:addMessage', { args = { Config.Notifications.BoomboxSpawned } })
end)

RegisterNetEvent("boombox:client:removeBoombox")
AddEventHandler("boombox:client:removeBoombox", function()
    if boombox and DoesEntityExist(boombox) then
        exports.ox_target:removeLocalEntity(boombox)
        DeleteEntity(boombox)
        boombox = nil
    end

    if exports.xsound:soundExists(soundName) then
        exports.xsound:Destroy(soundName)
        playing = false
    end
end)

-- Fonction pour lancer la lecture en tenant compte de l'offset (temps écoulé)
local function playSoundWithOffset(url, pos, offset)
    if exports.xsound:soundExists(soundName) then
        exports.xsound:Destroy(soundName)
        playing = false
    end

    -- Si offset est trop grand (ex : > 1h), on ignore
    if offset > 3600 then offset = 0 end

    local success = exports.xsound:PlayUrlPos(soundName, url, 0.5, pos)
    if success then
        exports.xsound:Distance(soundName, currentDistance)
        playing = true
        lastUrl = url
        lastPos = pos
        -- Comme xsound ne supporte pas le seek, on attend offset avant d'activer le son
        if offset > 0 then
            exports.xsound:setVolume(soundName, 0.0)
            Citizen.SetTimeout(offset * 1000, function()
                if exports.xsound:soundExists(soundName) then
                    exports.xsound:setVolume(soundName, 0.5)
                end
            end)
        else
            exports.xsound:setVolume(soundName, 0.5)
        end
    else
        print("[Boombox] Erreur: PlayUrlPos a échoué.")
    end
end

local soundStartLocalTime = 0 -- temps en ms quand la musique a commencé localement

RegisterNetEvent("boombox:client:playSound")
AddEventHandler("boombox:client:playSound", function(url, coords, offset)
    offset = offset or 0

    local now = GetGameTimer() -- ms

    -- Temps écoulé localement
    local elapsedLocal = 0
    if soundStartLocalTime > 0 then
        elapsedLocal = (now - soundStartLocalTime) / 1000 -- convert ms en sec
    end

    -- Si même URL et la différence d'offset est petite, on ignore
    if url == lastPlayedUrl and math.abs(elapsedLocal - offset) < playTolerance then
        return
    end

    lastPlayedUrl = url
    lastPlayedOffset = offset
    soundStartLocalTime = now - (offset * 1000) -- On recule le temps de départ local pour la synchro

    local pos
    if type(coords) == "vector3" then
        pos = coords
    elseif type(coords) == "table" then
        pos = vector3(coords.x or 0.0, coords.y or 0.0, coords.z or 0.0)
    else
        pos = GetEntityCoords(PlayerPedId())
    end

    if exports.xsound:soundExists(soundName) then
        exports.xsound:Destroy(soundName)
    end

    local success = exports.xsound:PlayUrlPos(soundName, url, 0.5, pos)
    if success then
        exports.xsound:Distance(soundName, currentDistance)
        playing = true
        -- Ajuste le volume selon offset (mute si offset > 0 au début)
        if offset > 0 then
            exports.xsound:setVolume(soundName, 0.0)
            Citizen.SetTimeout(offset * 1000, function()
                if exports.xsound:soundExists(soundName) then
                    exports.xsound:setVolume(soundName, 0.5)
                end
            end)
        else
            exports.xsound:setVolume(soundName, 0.5)
        end
    else
        print("[Boombox] Erreur: PlayUrlPos a échoué.")
    end
end)


-- Quand on arrête la musique, reset la variable de temps local
RegisterNetEvent("boombox:client:stopSound")
AddEventHandler("boombox:client:stopSound", function()
    if exports.xsound:soundExists(soundName) then
        exports.xsound:Destroy(soundName)
        playing = false
    end
    lastPlayedUrl = nil
    lastPlayedOffset = 0
    soundStartLocalTime = 0
end)

-- Quand on pause, il faut aussi gérer le temps local
RegisterNetEvent("boombox:client:pauseSound")
AddEventHandler("boombox:client:pauseSound", function()
    if exports.xsound:soundExists(soundName) then
        exports.xsound:Pause(soundName)
        -- Mémorise le temps local à la pause
        if soundStartLocalTime > 0 then
            local now = GetGameTimer()
            lastPlayedOffset = (now - soundStartLocalTime) / 1000
            soundStartLocalTime = 0
        end
    end
end)


RegisterNetEvent("boombox:client:pauseSound")
AddEventHandler("boombox:client:pauseSound", function()
    if exports.xsound:soundExists(soundName) then
        exports.xsound:Pause(soundName)
    end
end)

-- Quand on resume, relance la musique à l'offset donné
RegisterNetEvent("boombox:client:resumeSound")
AddEventHandler("boombox:client:resumeSound", function(offset)
    if lastPlayedUrl and lastPos then
        playSoundWithOffset(lastPlayedUrl, lastPos, offset or 0)
        -- Recalcule le temps local pour la synchro
        soundStartLocalTime = GetGameTimer() - ((offset or 0) * 1000)
    end
end)

RegisterNetEvent("boombox:client:useBoombox")
AddEventHandler("boombox:client:useBoombox", function()
    holdBoombox()
end)

local function hasBoombox()
    return boombox ~= nil and DoesEntityExist(boombox)
end

AddEventHandler('playerSpawned', function()
    Citizen.Wait(1000)
    if not hasBoombox() and not holdingBoombox then
        TriggerServerEvent("boombox:server:giveBoomboxIfNeeded")
    end
end)

-- Lorsque le joueur se rapproche d'un boombox, demander la synchro
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(3000)
        if boombox and DoesEntityExist(boombox) then
            local playerCoords = GetEntityCoords(PlayerPedId())
            local boomboxCoords = GetEntityCoords(boombox)
            local dist = #(playerCoords - boomboxCoords)
            if dist <= currentDistance then
                TriggerServerEvent("boombox:requestSync", boomboxCoords)
            end
        end
    end
end)

-- Gestion des volumes
RegisterNUICallback("setVolume", function(data, cb)
    exports.xsound:setVolume(soundName, data.volume)
    cb("ok")
end)

RegisterNUICallback('setDistance', function(data, cb)
    local newDist = tonumber(data.distance)
    if newDist and newDist > 0 and newDist <= Config.Sound.MaxDistance then
        currentDistance = newDist
        if exports.xsound:soundExists(soundName) then
            exports.xsound:Distance(soundName, currentDistance)
        end
    else
        print("[Boombox] Distance invalide ou supérieure à la distance max.")
    end
    cb('ok')
end)

RegisterNUICallback("close", function(_, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({ type = "showUI", display = false })
    cb("ok")
end)

RegisterNUICallback("playSound", function(data, cb)
    local coords = boombox and GetEntityCoords(boombox) or GetEntityCoords(PlayerPedId())
    TriggerServerEvent("boombox:playSound", data.url, coords)
    cb("ok")
end)

RegisterNUICallback("stopSound", function(_, cb)
    local coords = boombox and GetEntityCoords(boombox) or GetEntityCoords(PlayerPedId())
    TriggerServerEvent("boombox:stopSound", coords)
    cb("ok")
end)

RegisterNUICallback("pauseSound", function(_, cb)
    local coords = boombox and GetEntityCoords(boombox) or GetEntityCoords(PlayerPedId())
    TriggerServerEvent("boombox:pauseSound", coords)
    cb("ok")
end)

RegisterNUICallback("resumeSound", function(_, cb)
    local coords = boombox and GetEntityCoords(boombox) or GetEntityCoords(PlayerPedId())
    TriggerServerEvent("boombox:resumeSound", coords)
    cb("ok")
end)
