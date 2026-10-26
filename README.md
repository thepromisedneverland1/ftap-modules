# ftap-modules
Blobman Creature Control (LocalClient)
This is a client-side replacement for the default LocalCreatureControl script from dex when u compile the code located in Workspace.Player.LocalCreatureControl for ^ftap^

The original game script is notoriously unstable because of Mori being a entire bumass

What it does
should stop the nil errors that are from LocalCreatureControl

Can be used for anything related to CreatureBlobman

Here is a quick example of how to use it:

local Diddy = [[
    -- Paste the entire LocalCreatureControl.lua code inside these brackets or paste a loadstring
]]

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local char = player.Character
local hum = char and char:FindFirstChild("Humanoid")

if hum and hum.SeatPart and hum.SeatPart.Parent.Name:find("Blobman") or ("CreatureBlobman") then
    if not getgenv().BlobmanScriptLoaded then
        getgenv().BlobmanScriptLoaded = true
        
        local load = loadstring(moduleCode)
        if load then
            local controller = load()
            if controller and controller.Start then
                task.spawn(controller.Start)
            end
        end
    end
else
    warn("Sit on a blob")
end

License
Do whatever you want with it just don't diddy it.
