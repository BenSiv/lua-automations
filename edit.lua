-- edit file with micro editor

local function print_help()
	print("Usage: edit < file >")
end

local function main()
	if not arg[1] then
		print_help()
	else
		local file_to_edit = arg[1]
		-- local to_exec = string.format("gnome-text-editor '%s' > /dev/null 2>&1 &", file_to_edit)
		local to_exec = string.format("micro '%s'", file_to_edit)
		os.execute(to_exec)
		-- print(to_exec)
	end
end

main()
