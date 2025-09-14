local user = nil
local domain = nil
local records = {}
local authToken = nil
local domainName = nil

local domainTitle = gurt.select('#domain-title')
local domainStatus = gurt.select('#domain-status')
local recordsList = gurt.select('#records-list')
local loadingElement = gurt.select('#records-loading')

local function showError(elementId, message)
    local element = gurt.select('#' .. elementId)
    
    element.text = message
    element.classList:remove('hidden')
end

local function hideError(elementId)
    local element = gurt.select('#' .. elementId)

    element.classList:add('hidden')
end

-- Forward declarations
local loadRecords
local renderRecords

local function deleteRecord(recordId)
    print('Deleting DNS record: ' .. recordId)
    
    local response = fetch('gurt://dns.web/domain/' .. domainName .. '/records/' .. recordId, {
        method = 'DELETE',
        headers = {
            Authorization = 'Bearer ' .. authToken
        }
    })
    
    if response:ok() then
        print('DNS record deleted successfully')
        
        -- Remove the record from local records array
        for i = #records, 1, -1 do
            if records[i].id == recordId then
                table.remove(records, i)
                break
            end
        end
        
        -- Re-render the entire list from scratch
        renderRecords()
    else
        print('Failed to delete DNS record: ' .. response:text())
    end
end

-- Actual implementation
loadRecords = function()
    print('Loading DNS records for: ' .. domainName)
    local response = fetch('gurt://dns.web/domain/' .. domainName .. '/records', {
        headers = {
            Authorization = 'Bearer ' .. authToken
        }
    })
    
    if response:ok() then
        records = response:json()
        print('Loaded ' .. #records .. ' DNS records')
        renderRecords()
    else
        print('Failed to load DNS records: ' .. response:text())
        records = {}
        renderRecords()
    end
end

renderRecords = function(appendOnly)
    if loadingElement then
        loadingElement:remove()
        loadingElement = nil
    end
    
    -- Clear everything if not appending
    if not appendOnly then
        local children = recordsList.children
        while #children > 0 do
            children[1]:remove()
            children = recordsList.children
        end
    end
    
    if #records == 0 then
        local emptyMessage = gurt.create('div', {
            text = 'No DNS records found. Add your first record below!',
            style = 'text-center text-[#6b7280] py-8',
            id = '404'
        })
        recordsList:append(emptyMessage)
        return
    else
        local err = gurt.select('#404')
        if err then
            gurt.select('#404'):remove()
        end
    end
    
    -- Create header only if not appending or if list is empty
    if not appendOnly or #recordsList.children == 0 then
        local header = gurt.create('div', { style = 'w-full flex justify-between gap-4 p-4 bg-gray-600 font-bold border-b rounded-xl' })
        
        local typeHeader = gurt.create('div', { text = 'Type' })
        local nameHeader = gurt.create('div', { text = 'Name' })
        local valueHeader = gurt.create('div', { text = 'Value' })
        local ttlHeader = gurt.create('div', { text = 'TTL' })
        local actionsHeader = gurt.create('div', { text = 'Actions' })
        
        header:append(typeHeader)
        header:append(nameHeader)
        header:append(valueHeader)
        header:append(ttlHeader)
        header:append(actionsHeader)
        recordsList:append(header)
    end
    
    -- Create records list - when appending, only render the last record; otherwise render all
    local startIndex = appendOnly and #records or 1
    for i = startIndex, #records do
        local record = records[i]
        local row = gurt.create('div', { style = 'w-full flex justify-between gap-4 p-4 border-b border-gray-600 hover:bg-[rgba(244, 67, 54, 0.2)]' })
        
        local typeCell = gurt.create('div', { text = record.type, style = 'font-bold' })
        local nameCell = gurt.create('div', { text = record.name or '@' })
        local valueCell = gurt.create('div', { text = record.value, style = 'font-mono text-sm break-all' })
        local ttlCell = gurt.create('div', { text = record.ttl or 'none' })
        
        local actionsCell = gurt.create('div')
        local deleteBtn = gurt.create('button', {
            text = 'Delete',
            style = 'danger-btn text-xs px-2 py-1'
        })
        
        deleteBtn:on('click', function()
            if deleteBtn.text == 'Delete' then
                deleteBtn.text = 'Confirm Delete'
            else
                deleteRecord(record.id)
            end
        end)
        
        actionsCell:append(deleteBtn)
        
        row:append(typeCell)
        row:append(nameCell)
        row:append(valueCell)
        row:append(ttlCell)
        row:append(actionsCell)
        recordsList:append(row)
    end
end

local function getDomainNameFromURL()
    local nameParam = gurt.location.query.get('name')
    if nameParam then
        return nameParam:gsub('%%%.', '.')
    end
    return nil
end

local function updateDomainInfo()
    if domain then
        domainTitle.text = domain.name .. '.' .. domain.tld
        domainStatus.text = 'Status: ' .. (domain.status or 'Unknown')
    end
end

local function loadDomain()
    print('Loading domain details for: ' .. domainName)
    local response = fetch('gurt://dns.web/domain/' .. domainName, {
        headers = {
            Authorization = 'Bearer ' .. authToken
        }
    })
    
    if response:ok() then
        domain = response:json()
        print('Loaded domain details')
        updateDomainInfo()
        loadRecords()
    else
        print('Failed to load domain: ' .. response:text())
        --gurt.location.goto('/dashboard.html')
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
            
            domainName = getDomainNameFromURL()
            if domainName then
                loadDomain()
            else
                print('No domain name in URL, redirecting to dashboard')
                --gurt.location.goto('/dashboard.html')
            end
        else
            print('Token invalid, redirecting to login...')
            gurt.crumbs.delete('auth_token')
            --gurt.location.goto('../')
        end
    else
        print('No auth token found, redirecting to login...')
        --gurt.location.goto('../')
    end
end

local function addRecord(type, name, value, ttl)
    hideError('record-error')

    local response = fetch('gurt://dns.web/domain/' .. domainName .. '/records', {
        method = 'POST',
        headers = {
            ['Content-Type'] = 'application/json',
            Authorization = 'Bearer ' .. authToken
        },
        body = JSON.stringify({ 
            type = type,
            name = name,
            value = value,
            ttl = ttl
        })
    })
    
    if response then
        if response:ok() then
            gurt.select('#record-name').value = ''
            gurt.select('#record-value').value = ''
            gurt.select('#record-ttl').value = ''
            
            local newRecord = response:json()
            if newRecord and newRecord.id then
                table.insert(records, newRecord)
                
                local wasEmpty = (#records == 1)
                
                if wasEmpty then
                    renderRecords(false)
                else
                    renderRecords(true)
                end
            else
                loadRecords()
            end
        else
            local error = response:text()
            showError('record-error', 'Failed to add record: ' .. error)
            print('Failed to add DNS record: ' .. error)
        end
    else
        showError('record-error', 'No response from server - connection failed')
        print('Failed to add DNS record: No response')
    end
    
end

local function logout()
    gurt.crumbs.delete('auth_token')
    print('Logged out successfully')
    --gurt.location.goto("../")
end

local function goBack()
    --gurt.location.goto("/dashboard.html")
end

-- Function to update help text based on record type
local function updateHelpText()
    local recordType = gurt.select('#record-type').value
    
    -- Hide all help texts
    local helpTypes = {'A', 'AAAA', 'CNAME', 'TXT'}
    for _, helpType in ipairs(helpTypes) do
        local helpElement = gurt.select('#help-' .. helpType)
        if helpElement then
            helpElement.classList:add('hidden')
        end
    end
    
    -- Show the relevant help text
    local currentHelp = gurt.select('#help-' .. recordType)
    if currentHelp then
        currentHelp.classList:remove('hidden')
    end
    
    -- Update placeholder text based on record type
    local valueInput = gurt.select('#record-value')
    if recordType == 'A' then
        valueInput.placeholder = '192.168.1.1'
    elseif recordType == 'AAAA' then
        valueInput.placeholder = '2001:db8::1'
    elseif recordType == 'CNAME' then
        valueInput.placeholder = 'example.com'
    elseif recordType == 'TXT' then
        valueInput.placeholder = 'Any text content'
    end
end

-- Event handlers
gurt.select('#logout-btn'):on('click', logout)
gurt.select('#back-btn'):on('click', goBack)
gurt.select('#record-type'):on('change', updateHelpText)

gurt.select('#add-record-btn'):on('click', function()
    local recordType = gurt.select('#record-type').value
    local recordName = gurt.select('#record-name').value
    local recordValue = gurt.select('#record-value').value
    local recordTTL = tonumber(gurt.select('#record-ttl').value) or 'none'

    if not recordValue or recordValue == '' then
        showError('record-error', 'Record value is required')
        return
    end

    if not recordName or recordName == '' then
        recordName = '@'
    end

    addRecord(recordType, recordName, recordValue, recordTTL)
end)

-- Initialize
print('Domain management page initialized')
updateHelpText() -- Set initial help text
checkAuth()
