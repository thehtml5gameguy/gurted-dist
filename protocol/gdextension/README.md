GURT networking extension for Godot.

## Quick Start

1. **Build the extension:**
   ```bash
   ./build.sh
   ```

2. **Install in your Godot project:**
   - Copy `addon/gurt-protocol/` to your project's `addons/` folder (e.g. `addons/gurt-protocol`)
   - Enable the plugin in `Project Settings > Plugins`

3. **Use in your game:**
   ```gdscript
   var client = GurtProtocolClient.new()
   client.create_client(30)  # 30s timeout
   
   var response = client.request("gurt://127.0.0.1:4878", {"method": "GET"})

   client.disconnect() # cleanup
   
   if response.is_success:
      print(response.body) // { "content": ..., "headers": {...}, ... }
   else:
      print("Error: ", response.status_code, " ", response.status_message)
   ```

## Build Options

```bash
./build.sh                    # Release build for current platform
./build.sh -t debug           # Debug build
./build.sh -p windows         # Build for Windows
./build.sh -p linux           # Build for Linux  
./build.sh -p macos           # Build for macOS
```