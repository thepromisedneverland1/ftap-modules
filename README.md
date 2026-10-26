# ftap-modules

## Blobman Creature Control (LocalClient)

This is a client-side replacement for the default `LocalCreatureControl` script from Dex when you decompile the code located in `Workspace.Player.LocalCreatureControl` for **ftap**.

The original game script is notoriously unstable because Mori is a complete bum. Oh, and this module also helps fix your grab when it breaks after using a Gucci or something similar.

### What it does
- Stops the nil value errors that come from `LocalCreatureControl`.
- Can be used for anything related to `CreatureBlobman`.

### How to use it

Here is a quick example of how to use it:

```lua
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local char = player.Character
local hum = char and char:FindFirstChild("Humanoid")

if hum and hum.SeatPart and hum.SeatPart.Parent.Name:find("Blobman") then
    if not getgenv().BlobmanScriptLoaded then
        getgenv().BlobmanScriptLoaded = true
        
        local url = "https://raw.githubusercontent.com/thepromisedneverland1/ftap-modules/refs/heads/main/Blobman.lua"
        local success, moduleCode = pcall(game.HttpGet, game, url)
        
        if success and moduleCode then
            local load = loadstring(moduleCode)
            if load then
                local controller = load()
                if controller and controller.Start then
                    task.spawn(controller.Start)
                end
            else
                warn("Failed to load the module code.")
            end
        else
            warn("The GitHub repo probably got deleted.")
        end
    end
else
    warn("You need to be sitting on a Blobman first.")
end
