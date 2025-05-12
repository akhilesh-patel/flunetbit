function extract_container_name(tag, timestamp, record)
    -- Get the container ID from the tag
    local container_id = string.match(tag, "docker%.([%w]+)")
    if container_id then
        record["container_id"] = container_id
    end

    -- Debug: Uncomment to see what's in the record
    -- print("Record for container name extraction: " .. require("cjson").encode(record))

    -- Extract container name from Docker attributes if available
    if record["attrs"] then
        local attrs = record["attrs"]
        if attrs["container_name"] then
            record["container_name"] = string.gsub(attrs["container_name"], "^/", "")
        elseif attrs["name"] then
            record["container_name"] = string.gsub(attrs["name"], "^/", "")
        -- Look in labels for container name information
        elseif attrs["labels"] and attrs["labels"]["com.docker.compose.service"] then
            record["container_name"] = attrs["labels"]["com.docker.compose.service"]
        end
    elseif record["kubernetes"] and record["kubernetes"]["container_name"] then
        record["container_name"] = record["kubernetes"]["container_name"]
    else
        -- Fallback to extract from docker log
        local docker_info = record["json"] or record["log"] or ""
        local name = string.match(docker_info, '"name":"([^"]+)"')
        if name then
            record["container_name"] = name
        end
    end

    -- Try to extract directly from logs for common containers
    if (not record["container_name"] or record["container_name"] == "") and record["log"] then
        local log_content = record["log"]
        
        -- Check for common service names in logs
        local services = {"grafana", "prometheus", "loki", "fluentbit", "fluent-bit", "nginx"}
        for _, service in ipairs(services) do
            if string.find(string.lower(log_content), service) then
                record["container_name"] = service
                break
            end
        end
    end

    -- If no container name found, use container ID
    if (not record["container_name"] or record["container_name"] == "") and record["container_id"] then
        -- Try to get container name from Docker API using socket
        -- This requires Docker socket to be mounted
        if record["container_id"] then
            -- Use Docker API to get container info
            local container_id = record["container_id"]
            local cmd = "curl -s --unix-socket /var/run/docker.sock http://localhost/containers/" .. container_id .. "/json"
            local handle = io.popen(cmd)
            if handle then
                local result = handle:read("*a")
                handle:close()
                
                if result and result ~= "" then
                    -- Extract container name from JSON response
                    local name = string.match(result, '"Name":"([^"]+)"')
                    if name then
                        record["container_name"] = string.gsub(name, "^/", "")
                    end
                end
            end
        end
        
        -- Final fallback if still no name
        if not record["container_name"] or record["container_name"] == "" then
            record["container_name"] = "container-" .. record["container_id"]:sub(1, 12)
        end
    end

    return 2, timestamp, record
end
