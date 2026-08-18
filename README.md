Maclib (Matcha Edition)
Custom UI Library built for the Matcha LuaVM environment.

Author: a256

Features
Native Matcha UI integration (Tabs, Sections, Multi-page containers)
Keybind system supporting Enum.KeyCode and Win32 Virtual Key Codes
Single and dual colorpickers (Visible / Invisible color pairs)
Integer and floating-point sliders
Dynamic combo / dropdown menus
Config manager with JSON file persistence (writefile / readfile)
Watermark overlay with live FPS and Ping calculation via Drawing API
Bootstrapper
lua

local Maclib = loadstring(httpget("https://raw.githubusercontent.com/ars240/Maclib-Matcha/main/Maclib.lua"))()
local Window = Maclib:Window({
    Title = "Script Title",
    Subtitle = "Matcha Edition",
    Watermark = true,
    ConfigFolder = "ScriptConfigs"
})
local Tab = Window:Tab({ Name = "Main" })
local Section = Tab:Section({ Name = "Combat", Side = "Left" })
local Toggle = Section:Toggle({
    Name = "Aimbot",
    Id = "aim_on",
    Default = false,
    Callback = function(state)
        print("Aimbot:", state)
    end
})
Toggle:Keybind({
    Id = "aim_key",
    Default = Enum.KeyCode.MouseButton2,
    Mode = "Hold",
    HotkeyLabel = "Aimbot"
})
Documentation
Window Creation
lua

local Window = Maclib:Window({
    Title = "Title",
    Subtitle = "Subtitle",
    Watermark = true,
    ConfigFolder = "ConfigFolderName"
})
Tabs & Sections
lua

local Tab = Window:Tab({ Name = "Visuals" })
-- Standard Section
local Section = Tab:Section({ Name = "ESP", Side = "Left" })
-- Multi-Page Section
local MultiPage = Tab:Section({
    Name = "Targeting",
    Side = "Left",
    Pages = {"Main", "Advanced"},
    MaxHeight = 400
})
Elements
Toggle with Keybind & Colorpicker
lua

local Toggle = Section:Toggle({
    Name = "Box ESP",
    Id = "esp_box",
    Default = true,
    Callback = function(state) end
})
-- Keybind (Modes: "Hold", "Toggle", "Always", "Click")
Toggle:Keybind({
    Id = "esp_box_kb",
    Default = Enum.KeyCode.F,
    Mode = "Toggle",
    HotkeyLabel = "Box ESP"
})
-- Colorpicker
Toggle:Colorpicker({
    Id = "esp_box_col",
    Default = Color3.fromRGB(255, 0, 0),
    Alpha = 1.0,
    Callback = function(color, alpha) end
})
-- Dual Colorpicker
Toggle:Colorpicker2({
    Id1 = "vis_col",
    Default1 = Color3.fromRGB(0, 255, 0),
    Id2 = "invis_col",
    Default2 = Color3.fromRGB(255, 0, 0),
    Callback = function(c1, a1, c2, a2) end
})
Sliders
lua

-- Integer
Section:Slider({
    Name = "FOV Radius",
    Id = "aim_fov",
    Min = 10,
    Max = 800,
    Default = 150,
    Callback = function(val) end
})
-- Float
Section:Slider({
    Name = "Smoothing",
    Id = "aim_smooth",
    Min = 0.1,
    Max = 20.0,
    Default = 5.0,
    IsFloat = true,
    Format = "%.1f",
    Callback = function(val) end
})
Dropdowns
lua

local Dropdown = Section:Dropdown({
    Name = "Hitbox",
    Id = "aim_hitbox",
    Options = {"Head", "Torso", "HumanoidRootPart"},
    Default = "Head",
    Callback = function(text, index) end
})
Dropdown:Add("Arms")
Dropdown:Remove("Torso")
Dropdown:Clear()
Inputs & Buttons
lua

Section:Input({
    Name = "Webhook",
    Id = "webhook_input",
    Placeholder = "Enter URL...",
    Callback = function(text) end
})
Section:Button({
    Name = "Action Button",
    Callback = function()
        print("Clicked")
    end
})
Config Manager UI
lua

Window:BuildConfigSection(Tab, "Right")
Author
a256
