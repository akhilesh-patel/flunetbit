function extract_container_name(tag, timestamp, record)
    -- Safe extraction of container ID from tag (e.g., docker.123abc456def...)
    local container_id = nil
    if tag then
        container_id = string.match(tag, "docker%.([a-fA-F0-9]+)")
        if container_id then
            -- Debug print statement to show the extracted container_id
            print("Extracted container_id: " .. container_id)
            record["container_id"] = container_id
        else
            print("Container ID not found in tag")
        end
    end

    -- Try to extract container_name from Docker attributes
    if record["attrs"] then
        local attrs = record["attrs"]

        -- Prefer container_name field
        if attrs["container_name"] then
            record["container_name"] = string.gsub(attrs["container_name"], "^/", "")
            return 2, timestamp, record

        -- Or fallback to "name" field
        elseif attrs["name"] then
            record["container_name"] = string.gsub(attrs["name"], "^/", "")
            return 2, timestamp, record
        end

        -- Check labels for Compose service name
        if attrs["labels"] and attrs["labels"]["com.docker.compose.service"] then
            record["container_name"] = attrs["labels"]["com.docker.compose.service"]
            return 2, timestamp, record
        end
    end

    -- Fallback: build name from container_id or use default
    if container_id then
        record["container_name"] = "container-" .. string.sub(container_id, 1, 12)
    else
        record["container_name"] = "unknown-container"
    end

    return 2, timestamp, record
end

