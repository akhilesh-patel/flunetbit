function extract_service_name(tag, timestamp, record)
    -- Try to extract service name from container labels
    local service_name = nil
    
    -- Debug: Uncomment to see what's in the record
    -- print("Record for service extraction: " .. require("cjson").encode(record))
    
    -- Check Docker labels first (most reliable source)
    if record["attrs"] and record["attrs"]["labels"] then
        local labels = record["attrs"]["labels"]
        
        -- Priority order for service name extraction
        if labels["com.docker.compose.service"] then
            service_name = labels["com.docker.compose.service"]
        elseif labels["io.kubernetes.pod.name"] then
            -- Extract service name from pod name (typically service-randomstring)
            local pod_name = labels["io.kubernetes.pod.name"]
            service_name = string.match(pod_name, "(.+)%-[a-z0-9]+$")
        elseif labels["service"] then
            service_name = labels["service"]
        elseif labels["app"] then
            service_name = labels["app"]
        end
    end
    
    -- If no service name found in labels, try container name patterns
    if not service_name and record["container_name"] then
        -- Known service names mapping
        local known_services = {
            ["grafana"] = "grafana-service",
            ["loki"] = "loki-service",
            ["fluentbit"] = "logging-service",
            ["fluent-bit"] = "logging-service",
            ["nginx"] = "web-service",
            ["prometheus"] = "monitoring-service"
        }
        
        -- If container name is a known service, use the mapped service name
        if known_services[record["container_name"]] then
            service_name = known_services[record["container_name"]]
        else
            -- Try to extract service name from container name
            -- Common pattern: service_name-1, service_name-instance-1, etc.
            service_name = string.match(record["container_name"], "(.+)%-%d+$")
            
            if not service_name then
                -- Just use container name as service name
                service_name = record["container_name"]
            end
        end
    end
    
    -- Final check to make sure we don't have container-var as service name
    if service_name and string.match(service_name, "^container%-") then
        -- Try to get service name from Docker API using socket
        if record["container_id"] then
            local container_id = record["container_id"]
            local cmd = "curl -s --unix-socket /var/run/docker.sock http://localhost/containers/" .. container_id .. "/json"
            local handle = io.popen(cmd)
            if handle then
                local result = handle:read("*a")
                handle:close()
                
                if result and result ~= "" then
                    -- Try to extract from labels in the API response
                    local compose_service = string.match(result, '"com.docker.compose.service":"([^"]+)"')
                    if compose_service then
                        service_name = compose_service
                    else
                        -- Extract from Name if no label
                        local name = string.match(result, '"Name":"([^"]+)"')
                        if name then
                            service_name = string.gsub(name, "^/", "")
                        end
                    end
                end
            end
        end
    end
    
    -- Set the service name in the record
    if service_name then
        record["service_name"] = service_name
    else
        record["service_name"] = "unknown-service"
    end
    
    return 2, timestamp, record
end
