Playtime = {
    sessions = {},
}

function Playtime.Start(source, citizenid)
    if not source or not citizenid then return end
    Playtime.sessions[source] = {
        citizenid = citizenid,
        startedAt = os.time(),
    }
end

function Playtime.Flush(source)
    local session = Playtime.sessions[source]
    if not session then return end

    local elapsed = math.max(0, os.time() - session.startedAt)
    if elapsed > 0 then
        MySQL.update.await(
            'UPDATE ryn_multichar_metadata SET playtime = playtime + ? WHERE character_id = ?',
            { elapsed, session.citizenid }
        )
    end

    Playtime.sessions[source] = nil
end

AddEventHandler('playerDropped', function()
    Playtime.Flush(source)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for playerSource in pairs(Playtime.sessions) do
        Playtime.Flush(playerSource)
    end
end)
