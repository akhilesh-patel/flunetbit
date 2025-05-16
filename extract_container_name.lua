local os_env = os.getenv

-- Dynamically load container and service mappings from environment
local container_service_map = {}

-- Define the prefixes for env variable lookup (CONTAINER_X / SERVICE_X)
local known_prefixes = { "NGINX", "MYSQL", "POSTGRES", "REACT" }  -- Add more as needed

for _, prefix in ipairs(known_prefixes) do
    local container_env = os_env("CONTAINER_" .. prefix)
    local service_env = os_env("SERVICE_" .. prefix)
    if container_env and service_env then
        container_service_map[container_env] = service_env
    end
end

function extract_container_name(tag, timestamp, record)
    local log_line = ""
    if type(record["log"]) == "string" then
        log_line = record["log"]
    end

    local source = record["source"] or ""
    local container_id = string.match(source, "/([^/]+)%.log$") or ""
    local container_name = string.sub(container_id, 1, 12)

    local matched = false
    local service_name = nil

    -- Match against known container names
    for cname, sname in pairs(container_service_map) do
        if string.find(source, cname) or string.find(string.lower(log_line), string.lower(cname)) then
            container_name = cname
            service_name = sname
            matched = true
            break
        end
    end

    if matched then
        record["container_name"] = container_name
        record["service_name"] = service_name
        return 1, timestamp, record
    else
        -- Skip unmatched logs in production
        return -1, 0, 0
    end
end

