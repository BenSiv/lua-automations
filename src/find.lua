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

	if not args then
		return
	end

	local print_unique = ""
	if args["unique"]  then
		print_unique =  "--files-with-matches"
	end

	args["where"] = args["where"] or "."

	local to_exec = string.format("grep --recursive --line-number --color=always %s '%s' '%s'", print_unique, args["what"], args["where"])
	local output, success = exec_command(to_exec)
	if not success then
		print("Failes to run command: " .. to_exec)
	end
	print(output)
end

main(arg)
