-- update git with one command

require("utils").using("utils")
using("argparse")
using("paths")

local function main(args)
	local output, success
	
	args["file"] = args["file"] or "."
	output, success = exec_command(string.format("git add '%s'", args["file"]))
	if not success then
		return output
	end

	output, success = exec_command(string.format("git commit -m '%s'", args["message"]))
	if not success then
		return output
	end

	output, success = exec_command("git push")
	if not success then
		return output
	end
end

arg_string = [[
	    -f --file arg string false
	    -m --message arg string true
	]]

expected_args = def_args(arg_string)
args = parse_args(arg, expected_args)
	
if get_file_name(arg[0]) == "gitup.lua" then
	main(args)
end
