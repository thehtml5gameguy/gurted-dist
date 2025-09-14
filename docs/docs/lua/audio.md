# Audio API

Work with audio elements for sound playback.

```lua
local audio = gurt.select('#my-audio')

audio:play()    -- Start playback
audio:pause()   -- Pause playback
audio:stop()    -- Stop and reset

audio.currentTime = 30.0            -- Seek to 30 seconds
audio.volume = 0.8                  -- Set volume (0.0 - 1.0)
audio.loop = true                   -- Enable looping
audio.src = 'gurt://new-audio.mp3'  -- Change source

local duration = audio.duration
local currentPos = audio.currentTime
local isPlaying = audio.playing
local isPaused = audio.paused
```