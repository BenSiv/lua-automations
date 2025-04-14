#!/bin/lua

-- view table from delimited file

require("utils").using("utils")
using("delimited_files")
using("dataframes")
using("argparse")

local arg_string = [[
    -i --input arg string true
]]

local expected_args = def_args(arg_string)
local args = parse_args(arg, expected_args)

function main(args)
	local delimited_map = {
		tsv = "\t",
		csv = ","
	}
	
	local file_extension = split(args["input"], ".")[2]
	local delimited = delimited_map[file_extension]
	local content = readdlm(args["input"], delimited, true)
	view(content)
end

-- run script
main(args)
