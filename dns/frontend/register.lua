local user = nil
local tlds = {}
local authToken = nil

local userInfo = gurt.select('#user-info')
local tldSelector = gurt.select('#tld-selector')
local loadingElement = gurt.select('#tld-loading')
local displayElement = gurt.select('#invite-code-display')
local remainingElement = gurt.select('#remaining')
local redeemBtn = gurt.select('#redeem-invite-btn')

local options

displayElement:hide()

local function showError(elementId, message)
    local element = gurt.select('#' .. elementId)
    
    element.text = message
    element.classList:remove('hidden')
end

local function hideError(elementId)
    local element = gurt.select('#' .. elementId)

    element.classList:add('hidden')
end

local function updateUserInfo()
    userInfo.text = 'Welcome, ' .. user.username .. '!'
    remainingElement.text = 'Register New Domain (' .. user.registrations_remaining .. ' remaining)'
end

local function renderTLDSelector()
    loadingElement:remove()

    tldSelector.text = ''
    local i = 1
    local total = #tlds
    local intervalId

    intervalId = setInterval(function()
        if i > total then
            clearInterval(intervalId)
            return
        end

        local tld = tlds[i]
        local option = gurt.create('button', {
            text = '.' .. tld,
            style = 'tld-option',
            ['data-tld'] = tld
        })

        tldSelector:append(option)
        
        option:on('click', function()
            -- Clear previous selection
            if not options then
                options = gurt.selectAll('.tld-option')
            end

            for j = 1, #options do
                if options[j].classList:contains('tld-selected') then
                    options[j].classList:remove('tld-selected')
                end
            end

            -- Select this option
            option.classList:add('tld-selected')
        end)
        i = i + 1
    end, 16)
end

local function loadTLDs()
    print('Loading available TLDs...')
    local response = fetch('gurt://dns.web/tlds')
    
    if response:ok() then
        tlds = response:json()
        print('Loaded ' .. #tlds .. ' TLDs')
        renderTLDSelector()
    else
        print('Failed to load TLDs: ' .. response:text())
    end
end

local function checkAuth()
    authToken = gurt.crumbs.get("auth_token")
    
    if authToken then
        print('Found auth token, checking validity...')
        local response = fetch('gurt://dns.web/auth/me', {
            headers = {
                Authorization = 'Bearer ' .. authToken
            }
        })
        
        if response:ok() then
            user = response:json()
            print('Authentication successful for user: ' .. user.username)
            updateUserInfo()
            loadTLDs()
        else
            print('Token invalid, redirecting to login...')
            gurt.crumbs.delete('auth_token')
            gurt.location.goto('../')
        end
    else
        print('No auth token found, redirecting to login...')
        gurt.location.goto('../')
    end
end

local function logout()
    gurt.crumbs.delete('auth_token')
    print('Logged out successfully')
    gurt.location.goto("../")
end

local function goToDashboard()
    gurt.location.goto("/dashboard.html")
end

local function submitDomain(name, tld)
    hideError('domain-error')
    print('Submitting domain: ' .. name .. '.' .. tld)
    
    local response = fetch('gurt://dns.web/domain', {
        method = 'POST',
        headers = { 
            ['Content-Type'] = 'application/json',
            Authorization = 'Bearer ' .. authToken
        },
        body = JSON.stringify({ name = name, tld = tld })
    })
    
    if response:ok() then
        print('Domain submitted successfully.')
        
        -- Update user registrations remaining
        user.registrations_remaining = user.registrations_remaining - 1
        updateUserInfo()
        
        -- Clear form
        gurt.select('#domain-name').text = ''
        
        -- Redirect to dashboard
        gurt.location.goto('/dashboard.html')
    else
        local error = response:text()
        showError('domain-error', 'Domain submission failed: ' .. error)
        print('Domain submission failed: ' .. error)
    end
end

local function createInvite()
    print('Creating invite code...')
    local response = fetch('gurt://dns.web/auth/invite', { 
        method = 'POST',
        headers = {
            Authorization = 'Bearer ' .. authToken
        }
    })
    
    if response:ok() then
        local data = response:json()
        local inviteCode = data.invite_code
        displayElement.text = 'Invite code: ' .. inviteCode .. ' (copied to clipboard)'
        displayElement:show()
        Clipboard.write(inviteCode)
        
        user.registrations_remaining = user.registrations_remaining - 1
        updateUserInfo()
        
        print('Invite code created and copied to clipboard: ' .. inviteCode)
    else
        print('Failed to create invite: ' .. response:text())
    end
end

local function redeemInvite(code)
    hideError('redeem-error')
    print('Redeeming invite code: ' .. code)
    
    local response = fetch('gurt://dns.web/auth/redeem-invite', {
        method = 'POST',
        headers = { 
            ['Content-Type'] = 'application/json',
            Authorization = 'Bearer ' .. authToken
        },
        body = JSON.stringify({ invite_code = code })
    })
    
    if response:ok() then
        local data = response:json()
        print('Invite redeemed: +' .. data.registrations_added .. ' registrations')
        
        -- Update user info
        user.registrations_remaining = user.registrations_remaining + data.registrations_added
        updateUserInfo()
        
        -- Clear form
        gurt.select('#invite-code-input').value = ''
        redeemBtn.text = 'Success!'
        gurt.setTimeout(function()
            redeemBtn.text = 'Redeem'
        end, 1000)
    else
        local error = response:text()
        showError('redeem-error', 'Failed to redeem invite: ' .. error)
        print('Failed to redeem invite: ' .. error)
    end
end

-- Event handlers
gurt.select('#logout-btn'):on('click', logout)
gurt.select('#dashboard-btn'):on('click', goToDashboard)

gurt.select('#submit-domain-btn'):on('click', function()
    local name = gurt.select('#domain-name').value
    local selectedTLD = gurt.select('.tld-selected')

    print('Submit domain button clicked')
    print('Input name:', name)
    print('Selected TLD element:', selectedTLD)

    if not name or name == '' then
        print('Validation failed: Domain name is required')
        showError('domain-error', 'Domain name is required')
        return
    end

    if not selectedTLD then
        print('Validation failed: No TLD selected')
        showError('domain-error', 'Please select a TLD')
        return
    end

    local tld = selectedTLD:getAttribute('data-tld')
    print('Submitting domain with name:', name, 'tld:', tld)
    submitDomain(name, tld)
end)

gurt.select('#create-invite-btn'):on('click', createInvite)

redeemBtn:on('click', function()
    local code = gurt.select('#invite-code-input').value
    if code and code ~= '' then
        redeemInvite(code)
    end
end)

-- Initialize
print('Register page initialized')
checkAuth()
