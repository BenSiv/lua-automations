-- update git with one command

require("utils").using("utils")
using("argparse")

local function main()
	local output, success
	local arg_string = [[
	    -f --file arg string false
	    -m --message arg string true
	]]

	local expected_args = def_args(arg_string)
	local args = parse_args(arg, expected_args)

	args["file"] = args["file"] or "."
	output, success = exec_command("git add " .. args["file"])
	if not success then
		return output
	end

	output, success = exec_command("git commit -m " .. args["message"])
	if not success then
		return output
	end

	output, success = exec_command("git push")
	if not success then
		return output
	end
end

main()
