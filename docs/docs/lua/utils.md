# Additional utilities

Gurted includes several helpful utilities:

### print(...)
We modify the global `print()` function to log to the browser console, and also convert any type (e.g. tables) to a readable string.

```lua
print('Hello, world!')
print({ name = 'Alice', age = 30, hobbies = {'reading', 'coding'} }) -- {age=30,hobbies={1="reading",2="coding"},name="Alice"}
```

### table.tostring(table)

Converts a table to a readable string representation.

```lua
local data = { name = 'John', age = 30, hobbies = {'reading', 'coding'} }
local str = table.tostring(data) -- {age=30,hobbies={1="reading",2="coding"},name="John"}
```

### string.replace(text, search, replacement)

Replaces the first occurrence of a string or regex pattern.

```lua
local text = 'Hello world, hello universe'
local result = string.replace(text, 'hello', 'hi')
trace.log(result)  -- Hello world, hi universe

local pattern = Regex.new('\\b\\w+@\\w+\\.\\w+\\b')
local masked = string.replace('Email: john@test.com', pattern, '[EMAIL]')
trace.log(masked)  -- Email: [EMAIL]
```

### string.replaceAll(text, search, replacement)

Replaces all occurrences of a string or regex pattern.

```lua
local text = 'Hello world, hello universe'
local result = string.replaceAll(text, 'hello', 'hi')
trace.log(result) -- Hello world, hi universe

local pattern = Regex.new('\\b\\w+@\\w+\\.\\w+\\b')
local text = 'Emails: john@test.com, jane@demo.org'
local masked = string.replaceAll(text, pattern, '[EMAIL]')
trace.log(masked) -- Emails: [EMAIL], [EMAIL]
```

### string.trim(text)

Removes whitespace from the beginning and end of a string.

```lua
local messy = '   Hello World   '
local clean = string.trim(messy)
trace.log('"' .. clean .. '"')  -- "Hello World"
```

### onNextFrame(callback)

Schedules a function to execute on the next frame render cycle. This helps sync your code with Godot's render pipeline, eliminating stuff like flickering.

```lua
local canvas = gurt.select("#my-canvas")
local ctx = canvas:withContext("2d")

onNextFrame(function()
    local x = math.random(0, canvas.width - 100)
    local y = math.random(0, canvas.height - 100)
    ctx:fillRect(x, y, 100, 100, "#ff0000")
end)
```
