-- connect to docker container

local function main()
	local name = arg[1] or "celleste-dev"
	local start_container = string.format("podman start '%s'", name)
	os.execute(start_container)
	
	local open_container = string.format("podman exec -it '%s' bash", name)
	os.execute(open_container)
end

main()
