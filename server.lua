local TEST_COORDS = vector4(-1330.3804, -2200.3894, 13.9893, 146.1964)
local END_COORDS  = vector4(-1035.4265, -2730.4011, 13.7566, 331.3417)

local playerTestDrives = {}
local pendingRequests = {}

local function getPlayer(id)
    local pid = tonumber(id)
    if not pid then return nil end
    if GetPlayerEndpoint(pid) == nil then return nil end
    return pid
end

local function isAdmin(src)
    if src == 0 then return true end
    return IsPlayerAceAllowed(src, "oh-testdrive.admin")
end

local function cleanupTestVehicle(pid)
    local entry = playerTestDrives[pid]
    if not entry then return false end
    local veh = NetworkGetEntityFromNetworkId(entry.netId)
    if veh and veh ~= 0 then
        DeleteEntity(veh)
    end
    playerTestDrives[pid] = nil
    return true
end

RegisterCommand('testdrive', function(source, args)
    if not isAdmin(source) then
        TriggerClientEvent('chat:addMessage', source, { args = { '^1[oh-testdrive]', 'You do not have permission.' } })
        return
    end

    local targetId = getPlayer(args[1])
    local modelArg = args[2]

    if not targetId or not modelArg then
        TriggerClientEvent('chat:addMessage', source, { args = { '^1[oh-testdrive]', 'Usage: /testdrive <id> <model>' } })
        return
    end

    cleanupTestVehicle(targetId)

    pendingRequests[targetId] = source
    TriggerClientEvent('oh-testdrive:client:start', targetId, {
        coords = { x = TEST_COORDS.x, y = TEST_COORDS.y, z = TEST_COORDS.z, h = TEST_COORDS.w },
        model = modelArg
    })
end, false)

RegisterNetEvent('oh-testdrive:server:registerVehicle', function(netId, plate)
    local src = source
    if not netId or not plate then return end
    playerTestDrives[src] = { netId = netId, plate = plate }
    local adminSrc = pendingRequests[src]
    if adminSrc then
        TriggerClientEvent('chat:addMessage', adminSrc, { args = { '^2[oh-testdrive]', ('Spawned test vehicle for %d: %s'):format(src, plate) } })
        pendingRequests[src] = nil
    end
end)

RegisterNetEvent('oh-testdrive:server:modelInvalid', function(modelName)
    local src = source
    local adminSrc = pendingRequests[src]
    if adminSrc then
        TriggerClientEvent('chat:addMessage', adminSrc, { args = { '^1[oh-testdrive]', ('Invalid vehicle model for %d: %s'):format(src, tostring(modelName)) } })
        pendingRequests[src] = nil
    end
    TriggerClientEvent('chat:addMessage', src, { args = { '^1[oh-testdrive]', ('Invalid vehicle model: %s'):format(tostring(modelName)) } })
end)

RegisterCommand('endtest', function(source, args)
    if not isAdmin(source) then
        TriggerClientEvent('chat:addMessage', source, { args = { '^1[oh-testdrive]', 'You do not have permission.' } })
        return
    end

    local targetId = getPlayer(args[1])
    if not targetId then
        TriggerClientEvent('chat:addMessage', source, { args = { '^1[oh-testdrive]', 'Usage: /endtest <id>' } })
        return
    end

    local cleaned = cleanupTestVehicle(targetId)

    TriggerClientEvent('oh-testdrive:client:end', targetId, {
        coords = { x = END_COORDS.x, y = END_COORDS.y, z = END_COORDS.z, h = END_COORDS.w }
    })

    if cleaned then
        TriggerClientEvent('chat:addMessage', source, { args = { '^2[oh-testdrive]', ('Ended test drive for %d'):format(targetId) } })
    else
        TriggerClientEvent('chat:addMessage', source, { args = { '^3[oh-testdrive]', ('No active test vehicle found for %d (teleported anyway)'):format(targetId) } })
    end
end, false)

AddEventHandler('playerDropped', function()
    local src = source
    cleanupTestVehicle(src)
    pendingRequests[src] = nil
end)
