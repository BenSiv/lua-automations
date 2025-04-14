-- find a sequence within files

require("utils").using("utils")
using("argparse")

local function main(arg)	
	local arg_string = [[
	    -s --what arg string true
	    -l --where arg string true
	    -u --unique flag string false
	]]

	local expected_args = def_args(arg_string)
	local args = parse_args(arg, expected_args)

	local base_command = {"grep", "--recursive", "--line-number", "--color=always"}

	if args["unique"]  then
		table.insert(base_command, "--files-with-matches")
	end

	table.insert(base_command, args["what"])
	table.insert(base_command, args["where"])

	local to_exec = table.concat(base_command, " ")
	os.execute(to_exec)
	-- print(to_exec)
end

main(arg)
