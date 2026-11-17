function lib.getFilesInDirectory(path, pattern)
    local resource = cache.resource

    if path:sub(1, 1) ~= '@' then
        path = ('%s/%s'):format(GetResourcePath(resource), path)
    end

    local files = {}
    local fileCount = 0
    local dir = io.readdir(path)

    if dir then
        for line in dir:lines() do
            if line:match(pattern) then
                fileCount = fileCount + 1
                files[fileCount] = line
            end
        end

        dir:close()
    end

    return files, fileCount
end

return lib.getFilesInDirectory
