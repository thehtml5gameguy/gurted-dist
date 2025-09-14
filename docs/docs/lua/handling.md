# Handlers

## Event Handling

### Body Events

Global events that can be captured on the document body:

```lua
-- Keyboard events
gurt.body:on('keydown', function(event)
    trace.log('Key down: ' .. event.key)
    if event.ctrl and event.key == 's' then
        trace.log('Ctrl+S pressed - Save shortcut!')
    end
end)

gurt.body:on('keyup', function(event)
    trace.log('Key up: ' .. event.key)
end)

gurt.body:on('keypress', function(event)
    trace.log('Key pressed: ' .. event.key)
    -- Event properties: key, keycode, ctrl, shift, alt
end)

-- Mouse events
gurt.body:on('mousemove', function(event)
    trace.log('Mouse at: ' .. event.x .. ', ' .. event.y)
    -- Event properties: x, y, deltaX, deltaY
end)

gurt.body:on('mouseenter', function()
    trace.log('Mouse entered page')
end)

gurt.body:on('mouseexit', function()
    trace.log('Mouse left page')
end)
```

### Element Events

Events specific to DOM elements:

```lua
local button = gurt.select('#my-button')

-- Mouse events
button:on('click', function()
    trace.log('Button clicked!')
end)

button:on('mousedown', function()
    trace.log('Mouse button pressed')
end)

button:on('mouseup', function()
    trace.log('Mouse button released')
end)

button:on('mouseenter', function()
    trace.log('Mouse entered button')
end)

button:on('mouseexit', function()
    trace.log('Mouse left button')
end)

button:on('mousemove', function(event)
    trace.log('Mouse moved over button: ' .. event.x .. ', ' .. event.y)
end)

-- Focus events
local input = gurt.select('#text-input')
input:on('focusin', function()
    trace.log('Input gained focus')
end)

input:on('focusout', function()
    trace.log('Input lost focus')
end)

-- Form events
input:on('change', function(event)
    trace.log('Input value changed to: ' .. event.value)
end)

input:on('input', function(event)
    trace.log('Input text: ' .. event.value)
end)

-- For file inputs
local fileInput = gurt.select('#file-input')
fileInput:on('change', function(event)
    trace.log('File selected: ' .. event.fileName)
end)

-- For form submission
local form = gurt.select('#my-form')
form:on('submit', function(event)
    trace.log('Form submitted with data:')
    for key, value in pairs(event.data) do
        trace.log(key .. ': ' .. tostring(value))
    end
end)
```

## Error Handling

### pcall for Protected Calls

Use Lua's `pcall` for error handling:

```lua
local success, result = pcall(function()
    local data = JSON.parse('invalid json')
    return data
end)

if success then
    trace.log('Parse successful: ' .. tostring(result))
else
    trace.log('Parse failed: ' .. result)  -- result contains error message
end
```
