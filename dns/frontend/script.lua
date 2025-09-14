if gurt.crumbs.get("auth_token") then
	gurt.location.goto("/dashboard.html")
end

local submitBtn = gurt.select('#submit')
local username_input = gurt.select('#username')
local password_input = gurt.select('#password')
local log_output = gurt.select('#log-output')

function addLog(message)
	trace.log(message)
	log_output.text = log_output.text .. message .. '\\n'
end

submitBtn:on('submit', function(event)
	local username = event.data.username
	local password = event.data.password

	local request_body = JSON.stringify({
    	username = username,
		password = password
	})
	print(request_body)
	local url = 'gurt://dns.web/auth/login'
	local headers = {
		['Content-Type'] = 'application/json'
	}

	addLog('Attempting to log in with username: ' .. username)
	log_output.text = ''

	local response = fetch(url, {
		method = 'POST',
		headers = headers,
		body = request_body
	})
	
	addLog('Response Status: ' .. response.status .. ' ' .. response.statusText)
	
	if response:ok() then
		addLog('Login successful!')
		local jsonData = response:json()
		if jsonData then
			addLog('Logged in as user: ' .. jsonData.user.username)

			gurt.crumbs.set({
				name = "auth_token",
				value = jsonData.token,
				lifespan = 604800
			})

			gurt.location.goto("/dashboard.html")
		end
	else
		addLog('Request failed with status: ' .. response.status)
		local error_data = response:text()
		addLog('Error response: ' .. error_data)
	end
end)