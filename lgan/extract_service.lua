function extract_service_name(tag, timestamp, record)
    -- Static service name mapping
    local known_services = {
        ["grafana"] = "grafana-service",
        ["loki"] = "loki-service",
        ["fluentbit"] = "fluentbit-service",
        ["nginx"] = "nginx-service",
        ["react"] = "react-service",
        ["frontend"] = "frontend-service",
        ["apache2"] = "apache2-service"
    }
    
    -- Try to get the container name from the record
    if record["container_name"] then
        local container_name = record["container_name"]
        
        -- Check if this is a known service
        if known_services[container_name] then
            record["service_name"] = known_services[container_name]
        else
            -- Default: use container name + "-service" suffix
            record["service_name"] = container_name .. "-service"
        end
    else
        -- If container name is not available, use unknown-service
        record["service_name"] = "unknown-service"
    end
    
    return 2, timestamp, record
end
