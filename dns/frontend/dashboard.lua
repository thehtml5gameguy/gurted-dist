local user = nil
local domains = {}
local authToken = nil

local userInfo = gurt.select('#user-info')
local domainsList = gurt.select('#domains-list')
local loadingElement = gurt.select('#tld-loading')

local options

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
end

local function renderDomains()
    local loadingElement = gurt.select('#domains-loading')
    if loadingElement then
        loadingElement:remove()
    end
    
    domainsList.text = ''
    
    if #domains == 0 then
        local emptyMessage = gurt.create('div', {
            text = 'No domains registered yet. Click "New" to register your first domain!',
            style = 'text-center text-[#6b7280] py-8'
        })
        domainsList:append(emptyMessage)
        return
    end
    
    for i, domain in ipairs(domains) do
        local domainItem = gurt.create('div', {
            style = 'domain-item cursor-pointer hover:bg-[#4b5563]'
        })
        
        local domainInfo = gurt.create('div', { style = 'w-full' })
        
        local domainName = gurt.create('div', {
            text = domain.name .. '.' .. domain.tld,
            style = 'font-bold text-lg'
        })
        
        local domainStatus = gurt.create('div', {
            text = 'Status: ' .. (domain.status or 'Unknown'),
            style = 'text-[#6b7280]'
        })
        
        domainInfo:append(domainName)
        domainInfo:append(domainStatus)
        
        domainItem:append(domainInfo)
        
        domainItem:on('click', function()
            gurt.location.goto('/domain.html?name=' .. domain.name .. '.' .. domain.tld)
        end)
        
        domainsList:append(domainItem)
    end
end

local function loadDomains()
    print('Loading domains...')
    local response = fetch('gurt://dns.web/auth/domains?page=1&limit=100', {
        headers = {
            Authorization = 'Bearer ' .. authToken
        }
    })
    
    if response:ok() then
        local data = response:json()
        domains = data.domains or {}
        print('Loaded ' .. #domains .. ' domains')
        renderDomains()
    else
        print('Failed to load domains: ' .. response:text())
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
        print(table.tostring(response))
        if response:ok() then
            user = response:json()
            print('Authentication successful for user: ' .. user.username)
            updateUserInfo()
            loadDomains()
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

local function goToRegister()
    gurt.location.goto("/register.html")
end

-- Event handlers
gurt.select('#logout-btn'):on('click', logout)
gurt.select('#new-btn'):on('click', goToRegister)

-- Initialize
print('Dashboard initialized')
checkAuth()