-- open file with default program

local length = require("utils").length

local function print_help()
	print("Usage: open < what >")
end

local function main()

	if length(arg) ~= 1 then
		print_help()
	else
		local what = arg[1]
		local to_exec = string.format("xdg-open '%s' 2>/dev/null" , what)
		os.execute(to_exec)
		-- print(to_exec)
	end
end

main()
