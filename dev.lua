-- connect to docker container

local length = require("utils").length

local function print_help()
	print("Usage: dev < name >")
end

local function main()
	if length(arg) ~= 3 then
		print_help()
	else
		local name = arg[1]
		local start_container = string.format("docker start '%s'", name)
		os.execute(start_container)
		
		local open_container = string.format("docker exec -it '%s' bash", name)
		os.execute(open_container)
	end
end

main()
