return function(config)
    local apiKey = GetConvar('FIVEMANAGE_LOGS_API_KEY', '')

    if apiKey == '' then
        error("convar 'FIVEMANAGE_LOGS_API_KEY' has not been set")
    end

    local provider = {
        name = 'Fivemanage',
        endpoint = 'https://api.fivemanage.com/api/logs/batch',
        headers = {
            ['Content-Type'] = 'application/json',
            ['Authorization'] = apiKey,
            ['User-Agent'] = 'rnv-core',
        },
        status = {
            ok = 200,
        },
    }

    function provider.append(log)
        log.resource = log.metadata.resource
        log.metadata.resource = nil

        return log
    end

    function provider.encode(logs) return json.encode(logs, config.jsonOptions) end

    function provider.onResponse(status, response)
        if status == provider.status.ok then return true end

        if type(response) ~= 'string' then
            return false, ('\t%s'):format(status)
        end

        return false, response
    end

    return provider
end
