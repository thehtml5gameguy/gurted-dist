# Regex API

Pattern matching and text processing with regular expressions.

## Regex.new(pattern)

Creates a new regex object from a pattern string.

```lua
local emailPattern = Regex.new('[a-zA-Z]+@[a-zA-Z]+\\.[a-zA-Z]+')
local phonePattern = Regex.new('\\(\\d{3}\\)\\s*\\d{3}-\\d{4}')
```

## regex:test(text)

Tests if the pattern matches anywhere in the text. Returns `true` or `false`.

```lua
local pattern = Regex.new('[a-zA-Z]+@[a-zA-Z]+\\.[a-zA-Z]+')

if pattern:test('user@example.com') then
    trace.log('Valid email format')
end

if pattern:test('Contact us at admin@site.com') then
    trace.log('Found email in text')
end
```

## regex:match(text)

Finds the first match and returns capture groups as an array, or `nil` if no match found.

```lua
local pattern = Regex.new('(\\w+)@(\\w+)\\.(\\w+)')
local result = pattern:match('Contact: admin@site.com for help')

if result then
    trace.log('Full match: ' .. result[1])  -- admin@site.com
    trace.log('Username: ' .. result[2])    -- admin
    trace.log('Domain: ' .. result[3])      -- site
    trace.log('TLD: ' .. result[4])         -- com
else
    trace.log('No match found')
end
```
