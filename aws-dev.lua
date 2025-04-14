-- connect to aws ec2 instance via ssm

local length = require("utils").length

local function print_help()
	print("Usage: aws-dev")
end

local function main()
	if length(arg) ~= 2 then
		print_help()
	else
		-- Run AWS session in background
		local start_session = [[
			nohup aws ssm start-session \
			--document-name AWS-StartPortForwardingSession \
			--target i-07fd3c0a802eef6fe \
			--parameters '{"portNumber":["22"],"localPortNumber":["9022"]}' \
			--region eu-central-1 > /dev/null 2>&1 &
		]]
		os.execute(start_session)

		-- Wait for session to start (adjust sleep duration if needed)
		os.execute("sleep 3")

		-- Open SSH connection
		local open_connection = "ssh -i /home/bensiv/.ssh/celleste-dev root@localhost -p 9022"
		os.execute(open_connection)
	end
end

main()
