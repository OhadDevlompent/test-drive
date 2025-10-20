local function spawnVehAt(modelHash, x, y, z, h)
    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do
        Wait(0)
    end

    ClearAreaOfVehicles(x, y, z, 8.0, false, false, false, false, false)

    local veh = CreateVehicle(modelHash, x + 0.0, y + 0.0, z + 0.5, h + 0.0, true, false)
    SetEntityAsMissionEntity(veh, true, true)

    local ped = PlayerPedId()
    SetPedIntoVehicle(ped, veh, -1)

    local netId = NetworkGetNetworkIdFromEntity(veh)
    SetNetworkIdCanMigrate(netId, true)
    SetVehicleHasBeenOwnedByPlayer(veh, true)

    local plate = ('TEST%03d'):format(math.random(0, 999))
    SetVehicleNumberPlateText(veh, plate)

    SetVehicleDirtLevel(veh, 0.0)
    SetVehicleEngineOn(veh, true, true, false)
    SetVehicleDoorsLocked(veh, 1)
    SetVehicleFuelLevel(veh, 100.0)

    if TriggerEvent then
        pcall(TriggerEvent, 'vehiclekeys:client:SetOwner', plate)
        pcall(TriggerEvent, 'wasabi_carlock:client:giveKeys', veh)
        pcall(TriggerEvent, 'cd_garage:AddKeys', plate)
    end

    SetModelAsNoLongerNeeded(modelHash)
    return veh, netId, plate
end

local function tpTo(x, y, z, h)
    local ped = PlayerPedId()
    RequestCollisionAtCoord(x, y, z)
    SetEntityCoordsNoOffset(ped, x, y, z, false, false, false)
    SetEntityHeading(ped, h or 0.0)
    local timer = GetGameTimer() + 3000
    while not HasCollisionLoadedAroundEntity(ped) and GetGameTimer() < timer do
        Wait(0)
    end
end

RegisterNetEvent('oh-testdrive:client:start', function(data)
    if not data or not data.coords or not data.model then return end
    local c = data.coords
    local modelName = tostring(data.model)
    local hash = joaat(modelName)
    if not IsModelInCdimage(hash) or not IsModelAVehicle(hash) then
        TriggerServerEvent('oh-testdrive:server:modelInvalid', modelName)
        return
    end
    tpTo(c.x, c.y, c.z, c.h)
    local veh, netId, plate = spawnVehAt(hash, c.x, c.y, c.z, c.h)
    TriggerServerEvent('oh-testdrive:server:registerVehicle', netId, plate)
end)

RegisterNetEvent('oh-testdrive:client:end', function(data)
    if not data or not data.coords then return end
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh and veh ~= 0 then
        SetEntityAsMissionEntity(veh, true, true)
        DeleteVehicle(veh)
    end
    local c = data.coords
    tpTo(c.x, c.y, c.z, c.h)
end)
