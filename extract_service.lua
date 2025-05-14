function extract_service_name(tag, timestamp, record)
    -- Debug log
    print("Processing record for service name extraction")
    
    -- Try to get the container name from the record
    if record["container_name"] then
        local container_name = record["container_name"]
        print("Found container name: " .. container_name)
        
        -- Check Docker Compose service name from labels
        if record["attrs"] and record["attrs"]["labels"] then
            local labels = record["attrs"]["labels"]
            if labels["com.docker.compose.service"] then
                record["service_name"] = labels["com.docker.compose.service"]
                print("Using Docker Compose service name: " .. record["service_name"])
                return 2, timestamp, record
            end
        end
        
        -- If no Docker Compose service found, extract service name from container name
        local service_name = container_name
        
        -- Remove common prefixes
        service_name = string.gsub(service_name, "^container%-", "")
        service_name = string.gsub(service_name, "^docker%-", "")
        
        -- Remove project prefix (e.g., 'flunetbit_')
        service_name = string.gsub(service_name, "^[^_]+_", "")
        
        -- Remove trailing instance number (e.g., '_1')
        service_name = string.gsub(service_name, "_%d+$", "")
        
        -- Remove any remaining special characters
        service_name = string.gsub(service_name, "[^%w%-]", "")
        
        -- Clean up the log field if it exists
        if record["log"] then
            -- Try to parse the nested JSON
            local success, parsed = pcall(function()
                return json.decode(record["log"])
            end)
            
            if success and parsed then
                -- If we have a nested log field, use that
                if parsed["log"] then
                    record["log"] = parsed["log"]
                end
            end
        end
        
        -- Store both the original container name and the cleaned service name
        record["container_name"] = container_name
        record["service_name"] = service_name
        print("Extracted service name: " .. service_name)
    else
        -- If container name is not available, use unknown-service
        record["service_name"] = "unknown-service"
        print("No container name found, using unknown-service")
    end
    
    return 2, timestamp, record
end
