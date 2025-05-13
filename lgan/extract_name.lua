function extract_container_name(tag, timestamp, record)
    -- Get the container ID from the tag
    local container_id = string.match(tag, "docker%.([%w]+)")
    if container_id then
        record["container_id"] = container_id
    end
    
    -- Extract from Docker attributes
    if record["attrs"] then
        local attrs = record["attrs"]
        
        -- Try from container name fields
        if attrs["container_name"] then
            record["container_name"] = string.gsub(attrs["container_name"], "^/", "")
            return 2, timestamp, record
        elseif attrs["name"] then
            record["container_name"] = string.gsub(attrs["name"], "^/", "")
            return 2, timestamp, record
        end
        
        -- Try from container labels
        if attrs["labels"] then
            local labels = attrs["labels"]
            if labels["com.docker.compose.service"] then
                record["container_name"] = labels["com.docker.compose.service"]
                return 2, timestamp, record
            end
        end
    end
    
    -- Known containers based on container ID
    if container_id then
        -- Use shortened container ID
        record["container_name"] = "container-" .. string.sub(container_id, 1, 12)
    else
        record["container_name"] = "unknown-container"
    end

    return 2, timestamp, record
end
