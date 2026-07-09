Discord = {}

local COLORS = {
    create = 3066993,
    delete = 15158332,
    login = 3447003,
}

function Discord.Send(webhookUrl, payload)
    if not Config.Discord.enabled or not webhookUrl or webhookUrl == '' then return end

    PerformHttpRequest(webhookUrl, function() end, 'POST', json.encode(payload), {
        ['Content-Type'] = 'application/json',
    })
end

function Discord.SendEmbed(webhookKey, title, description, fields)
    local url = Config.Discord.webhooks[webhookKey]
    if not url or url == '' then return end

    Discord.Send(url, {
        embeds = {
            {
                title = title,
                description = description,
                color = COLORS[webhookKey] or COLORS.login,
                fields = fields or {},
                footer = { text = 'ryn-multichar' },
                timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ'),
            },
        },
    })
end

function Discord.CharacterCreated(source, character)
    local name = GetPlayerName(source) or 'Unknown'
    local charName = Utils.GetCharacterFullName(character.charinfo)
    Discord.SendEmbed('create', 'Character Created', ('**%s** created a new character.'):format(name), {
        { name = 'Character', value = charName, inline = true },
        { name = 'Citizen ID', value = character.citizenid or '—', inline = true },
        { name = 'Server ID', value = tostring(source), inline = true },
    })
end

function Discord.CharacterDeleted(source, citizenid, charName)
    local name = GetPlayerName(source) or 'Unknown'
    Discord.SendEmbed('delete', 'Character Deleted', ('**%s** deleted a character.'):format(name), {
        { name = 'Character', value = charName or citizenid, inline = true },
        { name = 'Citizen ID', value = citizenid, inline = true },
        { name = 'Server ID', value = tostring(source), inline = true },
    })
end

function Discord.CharacterLoaded(source, citizenid, charName)
    local name = GetPlayerName(source) or 'Unknown'
    Discord.SendEmbed('login', 'Character Loaded', ('**%s** entered the city.'):format(name), {
        { name = 'Character', value = charName or citizenid, inline = true },
        { name = 'Citizen ID', value = citizenid, inline = true },
        { name = 'Server ID', value = tostring(source), inline = true },
    })
end
