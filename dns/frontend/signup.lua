if gurt.crumbs.get("auth_token") then
	gurt.location.goto("/dashboard.html")
end

local submitBtn = gurt.select('#submit')
local username_input = gurt.select('#username')
local password_input = gurt.select('#password')
local confirm_password_input = gurt.select('#confirm-password')
local log_output = gurt.select('#log-output')

function addLog(message)
	trace.log(message)
	log_output.text = log_output.text .. message .. '\n'
end

function clearLog()
	log_output.text = ''
end

function validateForm(username, password, confirmPassword)
	if not username or username == '' then
		addLog('Error: Username is required')
		return false
	end
	
	if not password or password == '' then
		addLog('Error: Password is required')
		return false
	end
	
	if password ~= confirmPassword then
		addLog('Error: Passwords do not match')
		return false
	end
	
	if string.len(password) < 6 then
		addLog('Error: Password must be at least 6 characters long')
		return false
	end
	
	return true
end

submitBtn:on('submit', function(event)
	local username = event.data.username
	local password = event.data.password
	local confirmPassword = event.data['confirm-password']

	clearLog()
	
	if not validateForm(username, password, confirmPassword) then
		return
	end

	local request_body = JSON.stringify({
    	username = username,
		password = password
	})
	
	local url = 'gurt://dns.web/auth/register'
	local headers = {
		['Content-Type'] = 'application/json'
	}

	addLog('Creating account for username: ' .. username)

	local response = fetch(url, {
		method = 'POST',
		headers = headers,
		body = request_body
	})
	
	addLog('Response Status: ' .. response.status .. ' ' .. response.statusText)
	
	if response:ok() then
		addLog('Account created successfully!')
		local jsonData = response:json()
		if jsonData then
			addLog('Welcome, ' .. jsonData.user.username .. '!')
			addLog('You have ' .. jsonData.user.registrations_remaining .. ' domain registrations available')

			gurt.crumbs.set({
				name = "auth_token",
				value = jsonData.token,
				lifespan = 604800
			})

			addLog('Redirecting to dashboard...')
			gurt.location.goto("/dashboard.html")
		end
	else
		addLog('Registration failed with status: ' .. response.status)
		local error_data = response:text()
		addLog('Error: ' .. error_data)
	end
end)
