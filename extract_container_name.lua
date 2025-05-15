function extract_container_name(tag, timestamp, record)
    -- Docker container logs have standard naming patterns that we can use
    -- to extract the container name
    
    -- First try to get the container name from the container_id field
    local container_id = record["container_id"] or ""
    
    -- If we can't find container_id in the record, try to extract it from the source field
    if container_id == "" then
        local source = record["source"] or ""
        container_id = string.match(source, "/([^/]+)%.log$") or ""
    end
    
    -- If we still don't have a container_id, try to get it from the log_path
    if container_id == "" then
        local log_path = record["log_path"] or ""
        container_id = string.match(log_path, "/([^/]+)%.log$") or ""
    end
    
    -- Now extract the container name based on the container ID
    if container_id ~= "" then
        -- Simple direct matching for our known containers
        if string.find(container_id, "nginx") then
            record["container_name"] = "nginx"
        elseif string.find(container_id, "mysql") then
            record["container_name"] = "mysql"
        else
            -- Try to extract container name from Docker's standard naming pattern
            local name = record["container_name"]
            if not name or name == "" then
                -- Default to container_id if we can't determine name
                record["container_name"] = string.sub(container_id, 1, 12)
            end
        end
    else
        -- Last resort: check if there are any clues in the log content
        local log = record["log"] or ""
        if string.find(log:lower(), "nginx") then
            record["container_name"] = "nginx"
        elseif string.find(log:lower(), "mysql") then
            record["container_name"] = "mysql"
        else
            -- Set a default if we still can't determine
            record["container_name"] = "unknown"
        end
    end
    
    return 1, timestamp, record
end
