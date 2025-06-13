-- connect to docker container

local function main()
	local name = arg[1] or "celleste-dev"
	local start_container = string.format("docker start '%s'", name)
	os.execute(start_container)
	
	local open_container = string.format("docker exec -it '%s' bash", name)
	os.execute(open_container)
end

main()
