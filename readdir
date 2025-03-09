#!/bin/lua

require("utils").using("utils")
using("prettyprint")
local lfs = require("lfs")

local function get_content(directory)
	local files = {hidden={}, visible={}}
	local dirs = {hidden={}, visible={}}

	local dir, err = pcall(lfs.dir, directory)
    if not dir then
        return nil
    end

    for entry in lfs.dir(directory) do
        if entry ~= "." and entry ~= ".." then
			local path = directory .. "/" .. entry
            local mode = lfs.attributes(path, "mode")
            if mode == "file" then
            	if starts_with(entry, ".") then
	            	table.insert(files.hidden, entry)
            	else
	            	table.insert(files.visible, entry)
            	end
            else
            	if starts_with(entry, ".") then
            		table.insert(dirs.hidden, entry)
            	else
            		table.insert(dirs.visible, entry)
            	end
            end
        end
    end

    local content = {files = files, dirs = dirs}
    sorted_content = deep_sort(content)
    return sorted_content
end

local function main()
	local path = arg[1] or "."
    local mode = lfs.attributes(path, "mode")

    if not mode then
        color("Error: cannot access " .. path .. ": No such file or directory", "red")
    elseif mode == "file" then
        print(path)
    else
        local content = get_content(path)
        if not content then
            color("Error: could not read content of " .. directory, "red")
        else

        	-- print hidden directories
			for _, dir in pairs(content["dirs"]["hidden"]) do
	        	color(dir, "blue")
	        end

	        -- print visible directories
	        for _, dir in pairs(content["dirs"]["visible"]) do
	            color(dir, "blue")
	        end

			-- print hidden files
			for _, file in pairs(content["files"]["hidden"]) do
	        	print(file)
	        end

	        -- print visible files
	        for _, file in pairs(content["files"]["visible"]) do
	            print(file)
	        end
	        
        end
    end
end

main()

