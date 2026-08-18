-- Maclib UI Library (Comprehensive Drawing Engine with Full INS-ui Features)
-- Author: a256

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local Maclib = {
    Version = "3.0.0",
    Flags = {},
    Elements = {},
    Keybinds = {},
    Colors = {},
    Open = true,
    ConfigFolder = "MaclibConfigs",
    HotkeysEnabled = true,
    WatermarkEnabled = true,
    Rainbow = false,
    RainbowSpeed = 1.0
}

-- Key code mapping
local KeyNames = {
    [0x00] = "None", [0x01] = "M1", [0x02] = "M2", [0x04] = "M3", [0x05] = "M4", [0x06] = "M5",
    [0x08] = "Backspace", [0x09] = "Tab", [0x0D] = "Enter", [0x10] = "Shift",
    [0x11] = "Ctrl", [0x12] = "Alt", [0x1B] = "Esc", [0x20] = "Space",
    [0x21] = "PageUp", [0x22] = "PageDown", [0x23] = "End", [0x24] = "Home",
    [0x25] = "Left", [0x26] = "Up", [0x27] = "Right", [0x28] = "Down",
    [0x2D] = "Insert", [0x2E] = "Delete"
}
for i = 0x41, 0x5A do KeyNames[i] = string.char(i) end
for i = 0x30, 0x39 do KeyNames[i] = string.char(i) end
for i = 0x70, 0x7B do KeyNames[i] = "F" .. tostring(i - 0x6F) end

local function getKeyName(code)
    if typeof(code) == "EnumItem" then return tostring(code.Name) end
    return KeyNames[code] or ("0x" .. string.format("%X", code or 0))
end

-- Theme Palette
local Theme = {
    WindowBg = Color3.fromRGB(18, 18, 20),
    SidebarBg = Color3.fromRGB(22, 22, 25),
    CardBg = Color3.fromRGB(28, 28, 32),
    CardHover = Color3.fromRGB(34, 34, 38),
    Border = Color3.fromRGB(42, 42, 48),
    BorderSubtle = Color3.fromRGB(35, 35, 40),
    
    AccentA = Color3.fromRGB(80, 140, 245),
    AccentB = Color3.fromRGB(130, 110, 250),
    
    Text = Color3.fromRGB(240, 240, 243),
    TextDim = Color3.fromRGB(150, 150, 158),
    TextDark = Color3.fromRGB(90, 90, 98),
    
    -- macOS Traffic Lights
    Close = Color3.fromRGB(255, 95, 86),
    Minimize = Color3.fromRGB(255, 189, 46),
    Maximize = Color3.fromRGB(39, 201, 63),
    
    -- Controls
    SwitchOff = Color3.fromRGB(48, 48, 54),
    SwitchOn = Color3.fromRGB(240, 240, 243),
    KnobOn = Color3.fromRGB(20, 20, 22),
    KnobOff = Color3.fromRGB(180, 180, 185),
    
    SliderTrack = Color3.fromRGB(48, 48, 54),
    SliderFill = Color3.fromRGB(220, 220, 225),
    
    ValueBox = Color3.fromRGB(36, 36, 42),
    ActiveTab = Color3.fromRGB(32, 32, 36),
    PopupBg = Color3.fromRGB(24, 24, 28)
}

-- Color Math
local function rgbToHsv(color)
    local r, g, b = color.R, color.G, color.B
    local max, min = math.max(r, g, b), math.min(r, g, b)
    local h, s, v = 0, 0, max
    local d = max - min
    s = (max == 0 and 0 or d / max)
    if max == min then h = 0
    else
        if max == r then h = (g - b) / d + (g < b and 6 or 0)
        elseif max == g then h = (b - r) / d + 2
        elseif max == b then h = (r - g) / d + 4 end
        h = h / 6
    end
    return h, s, v
end

local function hsvToRgb(h, s, v)
    local r, g, b
    local i = math.floor(h * 6)
    local f = h * 6 - i
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)
    local m = i % 6
    if m == 0 then r, g, b = v, t, p
    elseif m == 1 then r, g, b = q, v, p
    elseif m == 2 then r, g, b = p, v, t
    elseif m == 3 then r, g, b = p, q, v
    elseif m == 4 then r, g, b = t, p, v
    elseif m == 5 then r, g, b = v, p, q end
    return Color3.new(r or 0, g or 0, b or 0)
end

-- Pure Lua JSON Engine
local function jsonEncode(val)
    local t = type(val)
    if t == "table" then
        local isArray = true
        local n = #val
        for k, _ in pairs(val) do
            if type(k) ~= "number" or k < 1 or k > n or math.floor(k) ~= k then
                isArray = false
                break
            end
        end
        if isArray then
            local items = {}
            for i = 1, n do table.insert(items, jsonEncode(val[i])) end
            return "[" .. table.concat(items, ",") .. "]"
        else
            local items = {}
            for k, v in pairs(val) do
                table.insert(items, string.format("%q:%s", tostring(k), jsonEncode(v)))
            end
            return "{" .. table.concat(items, ",") .. "}"
        end
    elseif t == "string" then
        return string.format("%q", val)
    elseif t == "number" or t == "boolean" then
        return tostring(val)
    else
        return "null"
    end
end

local function jsonDecode(str)
    if not str or str == "" then return nil end
    local pos = 1
    local len = #str

    local function skipWhitespace()
        while pos <= len do
            local c = str:sub(pos, pos)
            if c == " " or c == "\t" or c == "\n" or c == "\r" then pos = pos + 1 else break end
        end
    end

    local parseValue

    local function parseString()
        pos = pos + 1
        local start = pos
        while pos <= len do
            local c = str:sub(pos, pos)
            if c == '"' and str:sub(pos - 1, pos - 1) ~= '\\' then
                local res = str:sub(start, pos - 1)
                pos = pos + 1
                return res:gsub('\\"', '"'):gsub('\\\\', '\\')
            end
            pos = pos + 1
        end
        return ""
    end

    local function parseNumber()
        local start = pos
        while pos <= len do
            local c = str:sub(pos, pos)
            if c:match("[%d%.%-%+eE]") then pos = pos + 1 else break end
        end
        return tonumber(str:sub(start, pos - 1))
    end

    local function parseArray()
        pos = pos + 1
        local arr = {}
        skipWhitespace()
        if str:sub(pos, pos) == "]" then pos = pos + 1 return arr end
        while pos <= len do
            table.insert(arr, parseValue())
            skipWhitespace()
            local c = str:sub(pos, pos)
            if c == "," then pos = pos + 1
            elseif c == "]" then pos = pos + 1 return arr
            else break end
        end
        return arr
    end

    local function parseObject()
        pos = pos + 1
        local obj = {}
        skipWhitespace()
        if str:sub(pos, pos) == "}" then pos = pos + 1 return obj end
        while pos <= len do
            skipWhitespace()
            if str:sub(pos, pos) == '"' then
                local key = parseString()
                skipWhitespace()
                if str:sub(pos, pos) == ":" then
                    pos = pos + 1
                    obj[key] = parseValue()
                end
            end
            skipWhitespace()
            local c = str:sub(pos, pos)
            if c == "," then pos = pos + 1
            elseif c == "}" then pos = pos + 1 return obj
            else break end
        end
        return obj
    end

    parseValue = function()
        skipWhitespace()
        local c = str:sub(pos, pos)
        if c == '"' then return parseString()
        elseif c == "{" then return parseObject()
        elseif c == "[" then return parseArray()
        elseif c == "t" and str:sub(pos, pos + 3) == "true" then pos = pos + 4 return true
        elseif c == "f" and str:sub(pos, pos + 4) == "false" then pos = pos + 5 return false
        elseif c == "n" and str:sub(pos, pos + 3) == "null" then pos = pos + 4 return nil
        else return parseNumber() end
    end

    local ok, res = pcall(parseValue)
    if ok then return res else return nil end
end

-- =========================================================================
-- OBJECT POOLING SYSTEM
-- =========================================================================
local DrawPool = {
    Squares = {},
    Texts = {},
    Lines = {},
    Circles = {},
    InUse = {}
}

local function getSquare()
    local item = table.remove(DrawPool.Squares)
    if not item then item = Drawing.new("Square") end
    table.insert(DrawPool.InUse, { "Square", item })
    return item
end

local function getText()
    local item = table.remove(DrawPool.Texts)
    if not item then item = Drawing.new("Text") end
    table.insert(DrawPool.InUse, { "Text", item })
    return item
end

local function getLine()
    local item = table.remove(DrawPool.Lines)
    if not item then item = Drawing.new("Line") end
    table.insert(DrawPool.InUse, { "Line", item })
    return item
end

local function getCircle()
    local item = table.remove(DrawPool.Circles)
    if not item then item = Drawing.new("Circle") end
    table.insert(DrawPool.InUse, { "Circle", item })
    return item
end

local function resetDrawPool()
    for _, record in ipairs(DrawPool.InUse) do
        local kind, obj = record[1], record[2]
        obj.Visible = false
        if kind == "Square" then table.insert(DrawPool.Squares, obj)
        elseif kind == "Text" then table.insert(DrawPool.Texts, obj)
        elseif kind == "Line" then table.insert(DrawPool.Lines, obj)
        elseif kind == "Circle" then table.insert(DrawPool.Circles, obj) end
    end
    DrawPool.InUse = {}
end

-- Draw Primitives
local function drawRect(x, y, w, h, color, filled, thickness, zIndex)
    local s = getSquare()
    s.Position = Vector2.new(x, y)
    s.Size = Vector2.new(w, h)
    s.Color = color
    s.Filled = (filled == nil and true or filled)
    s.Thickness = thickness or 1
    s.ZIndex = zIndex or 10
    s.Visible = true
    return s
end

local function drawCircle(x, y, radius, color, filled, zIndex)
    local c = getCircle()
    c.Position = Vector2.new(x, y)
    c.Radius = radius
    c.Color = color
    c.Filled = (filled == nil and true or filled)
    c.ZIndex = zIndex or 15
    c.Visible = true
    return c
end

local function drawText(x, y, text, color, size, center, outline, font, zIndex)
    local t = getText()
    t.Position = Vector2.new(x, y)
    t.Text = tostring(text or "")
    t.Color = color or Theme.Text
    t.Size = size or 13
    t.Center = center or false
    t.Outline = (outline == nil and true or outline)
    t.Font = font or Drawing.Fonts.System or 1
    t.ZIndex = zIndex or 20
    t.Visible = true
    return t
end

local function drawLine(fromX, fromY, toX, toY, color, thickness, zIndex)
    local l = getLine()
    l.From = Vector2.new(fromX, fromY)
    l.To = Vector2.new(toX, toY)
    l.Color = color or Theme.Border
    l.Thickness = thickness or 1
    l.ZIndex = zIndex or 15
    l.Visible = true
    return l
end

-- =========================================================================
-- INPUT SYSTEM & LISTENERS
-- =========================================================================
local Input = {
    MousePos = Vector2.new(0, 0),
    Mouse1Down = false,
    Mouse2Down = false,
    Mouse1Clicked = false,
    Mouse2Clicked = false,
    KeyListeningObj = nil,
    ActiveColorPicker = nil,
    ActiveKeybindMenu = nil,
    ActiveDropdown = nil,
    ActiveSlider = nil,
    ActiveRange = nil
}

local prevM1 = false
local prevM2 = false

local function updateInput()
    local m1 = ismouse1pressed and ismouse1pressed() or false
    local m2 = ismouse2pressed and ismouse2pressed() or false

    Input.Mouse1Clicked = (m1 and not prevM1)
    Input.Mouse2Clicked = (m2 and not prevM2)
    Input.Mouse1Down = m1
    Input.Mouse2Down = m2

    prevM1 = m1
    prevM2 = m2

    if LocalPlayer and LocalPlayer:GetMouse() then
        local mouse = LocalPlayer:GetMouse()
        Input.MousePos = Vector2.new(mouse.X, mouse.Y)
    end

    -- Keybind listening
    if Input.KeyListeningObj and iskeypressed then
        for vk = 0x01, 0xFE do
            if iskeypressed(vk) then
                if vk == 0x1B then -- Esc unbinds
                    Input.KeyListeningObj:SetKey(0x00)
                else
                    Input.KeyListeningObj:SetKey(vk)
                end
                Input.KeyListeningObj = nil
                break
            end
        end
    end
end

local function isHovering(x, y, w, h)
    local mx, my = Input.MousePos.X, Input.MousePos.Y
    return (mx >= x and mx <= x + w and my >= y and my <= y + h)
end

-- =========================================================================
-- NOTIFICATIONS TOAST SYSTEM
-- =========================================================================
local Notifications = {}

function Maclib:Notify(options)
    local notif = {
        Title = options.Title or "Maclib",
        Description = options.Description or "",
        Duration = options.Lifetime or options.Duration or 3.5,
        CreatedAt = tick()
    }
    table.insert(Notifications, notif)
end

local function renderNotifications()
    local vpX = Camera and Camera.ViewportSize.X or 1920
    local vpY = Camera and Camera.ViewportSize.Y or 1080
    local startY = vpY - 60
    local now = tick()

    local i = 1
    while i <= #Notifications do
        local n = Notifications[i]
        local elapsed = now - n.CreatedAt
        if elapsed >= n.Duration then
            table.remove(Notifications, i)
        else
            local remain = math.max(0, 1 - (elapsed / n.Duration))
            local w = 260
            local h = 52
            local x = vpX - w - 24
            local y = startY - ((i - 1) * (h + 10))

            drawRect(x, y, w, h, Theme.WindowBg, true, 1, 900)
            drawRect(x, y, w, h, Theme.Border, false, 1, 901)
            drawRect(x, y, 3, h, Theme.SwitchOn, true, 1, 902)

            drawText(x + 12, y + 8, n.Title, Theme.Text, 13, false, true, 1, 905)
            drawText(x + 12, y + 26, n.Description, Theme.TextDim, 12, false, true, 1, 905)
            drawRect(x + 3, y + h - 2, (w - 6) * remain, 2, Theme.SwitchOn, true, 1, 906)

            i = i + 1
        end
    end
end

-- =========================================================================
-- HOTKEYS OVERLAY (On-Screen Keybinds Display)
-- =========================================================================
local HotkeysWindow = {
    X = 30,
    Y = 400,
    Width = 190,
    Dragging = false,
    DragOffset = Vector2.new(0, 0)
}

local function renderHotkeysOverlay()
    if not Maclib.HotkeysEnabled then return end

    local activeBinds = {}
    for id, kb in pairs(Maclib.Keybinds) do
        if kb.Key and kb.Key ~= 0x00 and kb.ToggleRef and kb.ToggleRef.Value then
            local isPressed = iskeypressed and iskeypressed(kb.Key) or false
            local activeState = false

            if kb.Mode == "always" then activeState = true
            elseif kb.Mode == "hold" then activeState = isPressed
            elseif kb.Mode == "toggle" then activeState = kb.ToggleRef.Value
            elseif kb.Mode == "click" then activeState = isPressed end

            table.insert(activeBinds, {
                Label = kb.Label or kb.ToggleRef.Name,
                KeyStr = getKeyName(kb.Key),
                Active = activeState
            })
        end
    end

    if #activeBinds == 0 and not Maclib.Open then return end

    local hx, hy = HotkeysWindow.X, HotkeysWindow.Y
    local hw = HotkeysWindow.Width
    local hh = 28 + (math.max(1, #activeBinds) * 22) + 6

    if Input.Mouse1Clicked and isHovering(hx, hy, hw, 26) then
        HotkeysWindow.Dragging = true
        HotkeysWindow.DragOffset = Vector2.new(Input.MousePos.X - hx, Input.MousePos.Y - hy)
    end

    if HotkeysWindow.Dragging then
        if Input.Mouse1Down then
            HotkeysWindow.X = Input.MousePos.X - HotkeysWindow.DragOffset.X
            HotkeysWindow.Y = Input.MousePos.Y - HotkeysWindow.DragOffset.Y
            hx, hy = HotkeysWindow.X, HotkeysWindow.Y
        else
            HotkeysWindow.Dragging = false
        end
    end

    drawRect(hx, hy, hw, hh, Theme.WindowBg, true, 1, 700)
    drawRect(hx, hy, hw, hh, Theme.Border, false, 1, 701)
    drawRect(hx, hy, hw, 24, Theme.SidebarBg, true, 1, 702)
    drawLine(hx, hy + 24, hx + hw, hy + 24, Theme.Border, 1, 703)

    drawText(hx + 10, hy + 5, "Hotkeys", Theme.Text, 12, false, true, 1, 705)
    drawText(hx + hw - 20, hy + 5, "::", Theme.TextDark, 11, false, true, 1, 705)

    if #activeBinds == 0 then
        drawText(hx + 10, hy + 30, "No active hotkeys", Theme.TextDark, 11, false, true, 1, 706)
    else
        local bindY = hy + 30
        for _, b in ipairs(activeBinds) do
            drawText(hx + 10, bindY, b.Label, Theme.TextDim, 12, false, true, 1, 706)
            local statusStr = "[" .. b.KeyStr .. "]"
            drawText(hx + hw - 10 - (#statusStr * 7), bindY, statusStr, b.Active and Theme.Text or Theme.TextDark, 11, false, true, 1, 706)
            bindY = bindY + 22
        end
    end
end

-- =========================================================================
-- WATERMARK OVERLAY
-- =========================================================================
local function renderWatermark(title)
    if not Maclib.WatermarkEnabled then return end
    local ping = GetPingValue and GetPingValue() or 0
    local exec = identifyexecutor and identifyexecutor() or "Matcha"
    local gameName = getgamename and getgamename() or "Roblox"
    local txt = string.format("%s | %s | %s | %d ms", title or "Maclib", exec, gameName, math.floor(ping))

    local x, y = 20, 20
    local w = (#txt * 7.4) + 24
    local h = 24

    drawRect(x, y, w, h, Theme.WindowBg, true, 1, 800)
    drawRect(x, y, w, h, Theme.Border, false, 1, 801)
    drawRect(x, y, 2, h, Theme.SwitchOn, true, 1, 802)
    drawText(x + 10, y + 5, txt, Theme.Text, 12, false, true, 1, 805)
end

-- =========================================================================
-- CONFIG PERSISTENCE & SETTINGS
-- =========================================================================
function Maclib:PackConfig(window)
    local data = { Version = self.Version, SavedAt = tick(), Flags = {}, Keybinds = {}, Colors = {} }

    for id, val in pairs(self.Flags) do
        if type(val) == "number" or type(val) == "string" or type(val) == "boolean" or type(val) == "table" then
            data.Flags[id] = val
        elseif typeof(val) == "Color3" then
            data.Colors[id] = { val.R, val.G, val.B }
        end
    end

    for id, kb in pairs(self.Keybinds) do
        data.Keybinds[id] = { Key = kb.Key, Mode = kb.Mode }
    end

    return data
end

function Maclib:ApplyConfig(window, data)
    if not data or not data.Flags then return false end

    for id, val in pairs(data.Flags) do
        self.Flags[id] = val
        local el = self.Elements[id]
        if el and el.SetValue then el:SetValue(val) end
    end

    if data.Colors then
        for id, c in pairs(data.Colors) do
            if type(c) == "table" and #c >= 3 then
                local col = Color3.new(c[1], c[2], c[3])
                self.Flags[id] = col
                local el = self.Elements[id]
                if el and el.SetColor then el:SetColor(col) end
            end
        end
    end

    if data.Keybinds then
        for id, kb in pairs(data.Keybinds) do
            local bindObj = self.Keybinds[id]
            if bindObj then
                bindObj.Key = kb.Key
                bindObj.Mode = kb.Mode
            end
        end
    end

    return true
end

function Maclib:SaveConfig(window, configName)
    if not configName or configName == "" then return false end
    local folder = window.ConfigFolder or self.ConfigFolder
    if not isfolder(folder) then makefolder(folder) end

    local path = folder .. "/" .. configName .. ".json"
    local data = self:PackConfig(window)

    writefile(path, jsonEncode(data))
    self:Notify({ Title = "Config Saved", Description = "Saved config: " .. configName })
    return true
end

function Maclib:LoadConfig(window, configName)
    if not configName or configName == "" then return false end
    local folder = window.ConfigFolder or self.ConfigFolder
    local path = folder .. "/" .. configName .. ".json"

    if not isfile(path) then
        self:Notify({ Title = "Config Error", Description = "Not found: " .. configName })
        return false
    end

    local raw = readfile(path)
    local data = jsonDecode(raw)
    if not data then return false end

    self:ApplyConfig(window, data)
    self:Notify({ Title = "Config Loaded", Description = "Loaded config: " .. configName })
    return true
end

function Maclib:DeleteConfig(window, configName)
    local folder = window.ConfigFolder or self.ConfigFolder
    local path = folder .. "/" .. configName .. ".json"
    if isfile(path) then
        delfile(path)
        self:Notify({ Title = "Config Deleted", Description = "Deleted " .. configName })
        return true
    end
    return false
end

function Maclib:GetConfigs(window)
    local folder = window.ConfigFolder or self.ConfigFolder
    if not isfolder(folder) then makefolder(folder) end
    local files = listfiles(folder)
    local configs = {}
    for _, f in ipairs(files) do
        local name = f:match("([^\\/]+)%.json$")
        if name and name ~= "autoload" and name ~= "_autosave" then table.insert(configs, name) end
    end
    return configs
end

function Maclib:SetAutoload(window, configName)
    local folder = window.ConfigFolder or self.ConfigFolder
    if not isfolder(folder) then makefolder(folder) end
    writefile(folder .. "/autoload.json", jsonEncode({ Autoload = configName }))
    self:Notify({ Title = "Autoload Set", Description = "Autoload: " .. tostring(configName) })
end

function Maclib:GetAutoload(window)
    local folder = window.ConfigFolder or self.ConfigFolder
    local path = folder .. "/autoload.json"
    if isfile(path) then
        local raw = readfile(path)
        local data = jsonDecode(raw)
        if data and data.Autoload then return data.Autoload end
    end
    return nil
end

-- =========================================================================
-- MAIN WINDOW FACTORY (Pixel-Perfect 1:1 Maclib + Full INS-ui Features)
-- =========================================================================
function Maclib:Window(config)
    config = config or {}
    local win = {
        Title = config.Title or "Karpiware 6.1.0",
        Subtitle = config.Subtitle or "Build - Paid (Stable) | Universal",
        Username = config.Username or "a256",
        UserHandle = config.UserHandle or "@a256",
        ConfigFolder = config.ConfigFolder or Maclib.ConfigFolder,
        Watermark = (config.Watermark == nil and true or config.Watermark),
        ToggleKey = config.ToggleKey or 0x2D, -- Insert
        X = config.X or 180,
        Y = config.Y or 120,
        Width = config.Width or 840,
        Height = config.Height or 580,
        Tabs = {},
        ActiveTabIndex = 1,
        SearchQuery = "",
        Dragging = false,
        DragOffset = Vector2.new(0, 0),
        Active = true
    }

    Maclib.WatermarkEnabled = win.Watermark

    if not isfolder(win.ConfigFolder) then makefolder(win.ConfigFolder) end

    function win:Tab(tabConfig)
        tabConfig = tabConfig or {}
        local tabName = tabConfig.Name or ("Tab " .. tostring(#win.Tabs + 1))
        local tabObj = {
            Name = tabName,
            Icon = tabConfig.Icon or "[*]",
            Sections = {}
        }

        function tabObj:Section(secConfig)
            secConfig = secConfig or {}
            local secName = secConfig.Name or "Section"
            local side = secConfig.Side or "Left"

            local secObj = {
                Name = secName,
                Side = side,
                Elements = {}
            }

            -- =========================================================
            -- 1. TOGGLE (with Nested Keybind & Colorpicker Support)
            -- =========================================================
            function secObj:Toggle(tConfig)
                local id = tConfig.Id or (tabName .. "_" .. secName .. "_" .. (tConfig.Name or "Toggle"))
                local label = tConfig.Name or "Toggle"
                local default = tConfig.Default or false
                local callback = tConfig.Callback or function() end

                local toggleObj = {
                    Id = id,
                    Name = label,
                    Type = "Toggle",
                    Value = default,
                    Callback = callback,
                    SubElements = {}
                }

                Maclib.Flags[id] = default
                Maclib.Elements[id] = toggleObj

                function toggleObj:SetValue(val)
                    toggleObj.Value = val
                    Maclib.Flags[id] = val
                    callback(val)
                end

                function toggleObj:GetValue()
                    return toggleObj.Value
                end

                -- Nested Keybind Chip
                function toggleObj:Keybind(kbConfig)
                    local kbId = kbConfig.Id or (id .. "_kb")
                    local key = kbConfig.Default or 0x00
                    local mode = (kbConfig.Mode or "hold"):lower()

                    local kbObj = {
                        Id = kbId,
                        Type = "Keybind",
                        Key = key,
                        Mode = mode,
                        Label = kbConfig.HotkeyLabel or label,
                        ToggleRef = toggleObj
                    }

                    Maclib.Keybinds[kbId] = kbObj

                    function kbObj:SetKey(newKey)
                        kbObj.Key = newKey
                    end

                    function kbObj:SetMode(newMode)
                        kbObj.Mode = newMode:lower()
                    end

                    table.insert(toggleObj.SubElements, kbObj)
                    return kbObj
                end

                -- Nested Colorpicker
                function toggleObj:Colorpicker(cpConfig)
                    local cpId = cpConfig.Id or (id .. "_col")
                    local defCol = cpConfig.Default or Color3.fromRGB(255, 255, 255)
                    local cb = cpConfig.Callback or function() end
                    local h, s, v = rgbToHsv(defCol)

                    local cpObj = {
                        Id = cpId,
                        Type = "ColorPicker",
                        Color = defCol,
                        H = h, S = s, V = v,
                        Alpha = cpConfig.Alpha or 1.0,
                        Open = false
                    }

                    Maclib.Flags[cpId] = defCol
                    Maclib.Elements[cpId] = cpObj

                    function cpObj:SetColor(c, a)
                        cpObj.Color = c
                        if a ~= nil then cpObj.Alpha = a end
                        Maclib.Flags[cpId] = c
                        cb(c, cpObj.Alpha)
                    end

                    table.insert(toggleObj.SubElements, cpObj)
                    return cpObj
                end

                table.insert(secObj.Elements, toggleObj)
                return toggleObj
            end

            -- =========================================================
            -- 2. SLIDER (Single Handle)
            -- =========================================================
            function secObj:Slider(sConfig)
                local id = sConfig.Id or (tabName .. "_" .. secName .. "_" .. (sConfig.Name or "Slider"))
                local label = sConfig.Name or "Slider"
                local min = sConfig.Min or 0
                local max = sConfig.Max or 100
                local default = sConfig.Default or min
                local suffix = sConfig.Suffix or ""
                local isFloat = sConfig.IsFloat or false
                local callback = sConfig.Callback or function() end

                local sliderObj = {
                    Id = id,
                    Name = label,
                    Type = "Slider",
                    Min = min,
                    Max = max,
                    Value = default,
                    Suffix = suffix,
                    IsFloat = isFloat,
                    Callback = callback
                }

                Maclib.Flags[id] = default
                Maclib.Elements[id] = sliderObj

                function sliderObj:SetValue(val)
                    val = math.clamp(val, min, max)
                    sliderObj.Value = val
                    Maclib.Flags[id] = val
                    callback(val)
                end

                function sliderObj:GetValue()
                    return sliderObj.Value
                end

                table.insert(secObj.Elements, sliderObj)
                return sliderObj
            end

            -- =========================================================
            -- 3. RANGE SLIDER (Dual Handle Low & High)
            -- =========================================================
            function secObj:RangeSlider(rConfig)
                local id = rConfig.Id or (tabName .. "_" .. secName .. "_" .. (rConfig.Name or "Range"))
                local label = rConfig.Name or "Range Slider"
                local min = rConfig.Min or 0
                local max = rConfig.Max or 100
                local defLow = rConfig.DefaultLow or min
                local defHigh = rConfig.DefaultHigh or max
                local suffix = rConfig.Suffix or ""
                local callback = rConfig.Callback or function() end

                local rangeObj = {
                    Id = id,
                    Name = label,
                    Type = "RangeSlider",
                    Min = min,
                    Max = max,
                    Low = defLow,
                    High = defHigh,
                    Suffix = suffix,
                    ActiveKnob = nil,
                    Callback = callback
                }

                Maclib.Flags[id] = { defLow, defHigh }
                Maclib.Elements[id] = rangeObj

                function rangeObj:SetValue(low, high)
                    low = math.clamp(low, min, max)
                    high = math.clamp(high, min, max)
                    if low > high then low, high = high, low end
                    rangeObj.Low = low
                    rangeObj.High = high
                    Maclib.Flags[id] = { low, high }
                    callback(low, high)
                end

                table.insert(secObj.Elements, rangeObj)
                return rangeObj
            end

            -- =========================================================
            -- 4. DROPDOWN (Single & Multi-Select with Checkmarks)
            -- =========================================================
            function secObj:Dropdown(dConfig)
                local id = dConfig.Id or (tabName .. "_" .. secName .. "_" .. (dConfig.Name or "Dropdown"))
                local label = dConfig.Name or "Dropdown"
                local options = dConfig.Options or {}
                local multi = dConfig.Multi or false
                local default = dConfig.Default or (multi and {} or (options[1] or ""))
                local callback = dConfig.Callback or function() end

                local dropObj = {
                    Id = id,
                    Name = label,
                    Type = "Dropdown",
                    Options = options,
                    Multi = multi,
                    Value = default,
                    Open = false,
                    Callback = callback
                }

                Maclib.Flags[id] = default
                Maclib.Elements[id] = dropObj

                function dropObj:SetValue(val)
                    dropObj.Value = val
                    Maclib.Flags[id] = val
                    callback(val)
                end

                function dropObj:GetValue()
                    return dropObj.Value
                end

                function dropObj:Add(item)
                    table.insert(dropObj.Options, item)
                end

                function dropObj:Remove(item)
                    for idx, v in ipairs(dropObj.Options) do
                        if v == item then table.remove(dropObj.Options, idx) break end
                    end
                end

                function dropObj:Clear()
                    dropObj.Options = {}
                end

                table.insert(secObj.Elements, dropObj)
                return dropObj
            end

            -- =========================================================
            -- 5. BUTTON & INPUT & LABEL
            -- =========================================================
            function secObj:Button(bConfig)
                local label = bConfig.Name or "Button"
                local callback = bConfig.Callback or function() end
                local btnObj = { Name = label, Type = "Button", Callback = callback }
                table.insert(secObj.Elements, btnObj)
                return btnObj
            end

            function secObj:Input(iConfig)
                local id = iConfig.Id or (tabName .. "_" .. secName .. "_" .. (iConfig.Name or "Input"))
                local label = iConfig.Name or "Input"
                local default = iConfig.Default or ""
                local callback = iConfig.Callback or function() end

                local inputObj = {
                    Id = id,
                    Name = label,
                    Type = "Input",
                    Value = default,
                    Callback = callback
                }

                Maclib.Flags[id] = default
                Maclib.Elements[id] = inputObj

                function inputObj:SetValue(val)
                    inputObj.Value = val
                    Maclib.Flags[id] = val
                    callback(val)
                end

                table.insert(secObj.Elements, inputObj)
                return inputObj
            end

            function secObj:Label(text)
                local labelObj = { Name = text, Type = "Label" }
                table.insert(secObj.Elements, labelObj)
                return labelObj
            end

            table.insert(tabObj.Sections, secObj)
            return secObj
        end

        table.insert(win.Tabs, tabObj)
        return tabObj
    end

    -- Automatic Config Section Generator
    function win:BuildConfigSection(targetTab, targetSide)
        local sec = targetTab:Section({ Name = "Configuration", Side = targetSide or "Right" })
        local configsList = Maclib:GetConfigs(win)
        if #configsList == 0 then table.insert(configsList, "default") end

        local configInput = sec:Input({
            Name = "Config Name",
            Id = "cfg_name_input",
            Default = "default"
        })

        local configDropdown = sec:Dropdown({
            Name = "Active Config",
            Id = "cfg_select_drop",
            Options = configsList,
            Default = configsList[1]
        })

        sec:Button({
            Name = "Save Config",
            Callback = function()
                local name = configInput:GetValue()
                if name and name ~= "" then
                    Maclib:SaveConfig(win, name)
                    configDropdown.Options = Maclib:GetConfigs(win)
                end
            end
        })

        sec:Button({
            Name = "Load Config",
            Callback = function()
                local selected = configDropdown:GetValue()
                if selected then Maclib:LoadConfig(win, selected) end
            end
        })

        sec:Button({
            Name = "Set As Autoload",
            Callback = function()
                local selected = configDropdown:GetValue()
                if selected then Maclib:SetAutoload(win, selected) end
            end
        })

        sec:Button({
            Name = "Delete Config",
            Callback = function()
                local selected = configDropdown:GetValue()
                if selected and selected ~= "None" then
                    Maclib:DeleteConfig(win, selected)
                    local refreshed = Maclib:GetConfigs(win)
                    if #refreshed == 0 then table.insert(refreshed, "default") end
                    configDropdown.Options = refreshed
                end
            end
        })

        task.spawn(function()
            local auto = Maclib:GetAutoload(win)
            if auto then Maclib:LoadConfig(win, auto) end
        end)

        return sec
    end

    -- =========================================================================
    -- RENDERING LOOP (Pixel-Perfect macOS 1:1 + INS-ui Full Feature Set)
    -- =========================================================================
    local connection
    connection = RunService.Heartbeat:Connect(function()
        if not win.Active then
            connection:Disconnect()
            resetDrawPool()
            return
        end

        updateInput()
        resetDrawPool()

        renderWatermark(win.Title)
        renderNotifications()
        renderHotkeysOverlay()

        -- Window Toggle Key (Insert)
        if win.ToggleKey and iskeypressed and iskeypressed(win.ToggleKey) then
            if not win.ToggleDebounce then
                Maclib.Open = not Maclib.Open
                win.ToggleDebounce = true
            end
        else
            win.ToggleDebounce = false
        end

        if not Maclib.Open then return end

        local wx, wy = win.X, win.Y
        local ww, wh = win.Width, win.Height

        -- Window Dragging via Top Header
        local headerHeight = 70
        if Input.Mouse1Clicked and isHovering(wx, wy, ww, headerHeight) then
            if not isHovering(wx + 16, wy + 16, 60, 20) then
                win.Dragging = true
                win.DragOffset = Vector2.new(Input.MousePos.X - wx, Input.MousePos.Y - wy)
            end
        end

        if win.Dragging then
            if Input.Mouse1Down then
                win.X = Input.MousePos.X - win.DragOffset.X
                win.Y = Input.MousePos.Y - win.DragOffset.Y
                wx, wy = win.X, win.Y
            else
                win.Dragging = false
            end
        end

        -- 1. Base Window Container
        drawRect(wx, wy, ww, wh, Theme.WindowBg, true, 1, 10)
        drawRect(wx, wy, ww, wh, Theme.Border, false, 1, 11)

        -- 2. Traffic Light Dots
        drawCircle(wx + 22, wy + 20, 5.5, Theme.Close, true, 20)
        drawCircle(wx + 38, wy + 20, 5.5, Theme.Minimize, true, 20)
        drawCircle(wx + 54, wy + 20, 5.5, Theme.Maximize, true, 20)

        -- 3. Left Sidebar
        local sidebarW = 210
        drawRect(wx, wy + 40, sidebarW, wh - 40, Theme.SidebarBg, true, 1, 12)
        drawLine(wx + sidebarW, wy, wx + sidebarW, wy + wh, Theme.Border, 1, 13)

        drawText(wx + 20, wy + 44, win.Title, Theme.Text, 14, false, true, 1, 20)
        drawText(wx + 20, wy + 62, win.Subtitle, Theme.TextDim, 11, false, true, 1, 20)

        -- 4. Sidebar Tabs
        local tabStartY = wy + 96
        for idx, tab in ipairs(win.Tabs) do
            local isSelected = (idx == win.ActiveTabIndex)
            local itemY = tabStartY + ((idx - 1) * 40)
            local hover = isHovering(wx + 16, itemY, sidebarW - 32, 34)

            if isSelected then
                drawRect(wx + 16, itemY, sidebarW - 32, 34, Theme.ActiveTab, true, 1, 15)
                drawRect(wx + 16, itemY, sidebarW - 32, 34, Theme.Border, false, 1, 16)
                drawText(wx + 30, itemY + 10, tab.Icon, Theme.Text, 12, false, true, 1, 22)
                drawText(wx + 52, itemY + 9, tab.Name, Theme.Text, 13, false, true, 1, 22)
            else
                if hover then drawRect(wx + 16, itemY, sidebarW - 32, 34, Theme.CardBg, true, 1, 14) end
                drawText(wx + 30, itemY + 10, tab.Icon, Theme.TextDark, 12, false, true, 1, 20)
                drawText(wx + 52, itemY + 9, tab.Name, hover and Theme.Text or Theme.TextDim, 13, false, true, 1, 20)
            end

            if hover and Input.Mouse1Clicked then
                win.ActiveTabIndex = idx
            end
        end

        -- 5. User Profile Card
        local profileY = wy + wh - 60
        drawLine(wx + 14, profileY, wx + sidebarW - 14, profileY, Theme.BorderSubtle, 1, 14)
        drawCircle(wx + 36, profileY + 28, 14, Theme.CardBg, true, 18)
        drawCircle(wx + 36, profileY + 28, 14, Theme.Border, false, 19)
        drawText(wx + 36, profileY + 21, "a", Theme.Text, 13, true, true, 1, 20)
        drawText(wx + 58, profileY + 18, win.Username, Theme.Text, 12, false, true, 1, 20)
        drawText(wx + 58, profileY + 32, win.UserHandle, Theme.TextDark, 11, false, true, 1, 20)

        -- 6. Main Content Cards Grid
        local activeTab = win.Tabs[win.ActiveTabIndex]
        local contentX = wx + sidebarW + 24
        local contentY = wy + 20
        local contentW = ww - sidebarW - 48
        local colW = (contentW - 16) / 2

        if activeTab then
            drawText(contentX, contentY, activeTab.Name, Theme.TextDim, 13, false, true, 1, 20)
            drawText(wx + ww - 32, contentY, "[+]", Theme.TextDark, 12, false, true, 1, 20)

            local cardTopY = contentY + 26
            local leftY = cardTopY
            local rightY = cardTopY

            for _, sec in ipairs(activeTab.Sections) do
                local isLeft = (sec.Side == "Left")
                local secX = isLeft and contentX or (contentX + colW + 16)
                local curY = isLeft and leftY or rightY

                -- Calculate Height
                local secHeight = 16
                for _, el in ipairs(sec.Elements) do
                    if el.Type == "Toggle" then secHeight = secHeight + 36
                    elseif el.Type == "Slider" or el.Type == "RangeSlider" then secHeight = secHeight + 36
                    elseif el.Type == "Dropdown" then secHeight = secHeight + 38
                    elseif el.Type == "Button" or el.Type == "Input" then secHeight = secHeight + 36 end
                end

                drawRect(secX, curY, colW, secHeight, Theme.CardBg, true, 1, 14)
                drawRect(secX, curY, colW, secHeight, Theme.Border, false, 1, 15)

                local itemY = curY + 10
                for _, el in ipairs(sec.Elements) do
                    if el.Type == "Toggle" then
                        drawText(secX + 16, itemY + 5, el.Name, Theme.TextDim, 12, false, true, 1, 20)

                        -- macOS Switch
                        local swW, swH = 34, 18
                        local swX = secX + colW - 16 - swW
                        local swY = itemY + 4
                        local hover = isHovering(swX - 4, swY - 2, swW + 8, swH + 4)

                        drawRect(swX, swY, swW, swH, el.Value and Theme.SwitchOn or Theme.SwitchOff, true, 1, 22)
                        drawRect(swX, swY, swW, swH, Theme.Border, false, 1, 23)

                        local knobX = el.Value and (swX + swW - 14) or (swX + 4)
                        drawCircle(knobX + 5, swY + 9, 6, el.Value and Theme.KnobOn or Theme.KnobOff, true, 25)

                        if (hover or isHovering(secX + 16, itemY, colW - 32, 28)) and Input.Mouse1Clicked then
                            el:SetValue(not el.Value)
                        end

                        -- Render Nested Keybind Chip & Colorpicker
                        local extraOffset = swX - 8
                        for _, sub in ipairs(el.SubElements) do
                            if sub.Type == "Keybind" then
                                local kName = sub.Listening and "..." or getKeyName(sub.Key)
                                local kWidth = (#kName * 7) + 14
                                extraOffset = extraOffset - kWidth - 6
                                local kHover = isHovering(extraOffset, itemY + 3, kWidth, 20)

                                drawRect(extraOffset, itemY + 3, kWidth, 20, Theme.ValueBox, true, 1, 24)
                                drawRect(extraOffset, itemY + 3, kWidth, 20, kHover and Theme.Border or Theme.BorderSubtle, false, 1, 25)
                                drawText(extraOffset + (kWidth / 2), itemY + 6, kName, sub.Listening and Theme.Text or Theme.TextDim, 11, true, true, 1, 26)

                                if kHover and Input.Mouse1Clicked then
                                    sub.Listening = true
                                    Input.KeyListeningObj = sub
                                elseif kHover and Input.Mouse2Clicked then
                                    Input.ActiveKeybindMenu = { Keybind = sub, X = Input.MousePos.X, Y = Input.MousePos.Y }
                                end

                            elseif sub.Type == "ColorPicker" then
                                extraOffset = extraOffset - 22 - 6
                                local cHover = isHovering(extraOffset, itemY + 3, 22, 20)
                                drawRect(extraOffset, itemY + 3, 22, 20, sub.Color, true, 1, 24)
                                drawRect(extraOffset, itemY + 3, 22, 20, cHover and Color3.fromRGB(255,255,255) or Theme.Border, false, 1, 25)

                                if cHover and Input.Mouse1Clicked then
                                    Input.ActiveColorPicker = (Input.ActiveColorPicker == sub and nil or sub)
                                    sub.PopupPos = Vector2.new(extraOffset, itemY + 26)
                                end
                            end
                        end

                        itemY = itemY + 36

                    elseif el.Type == "Slider" then
                        drawText(secX + 16, itemY + 5, el.Name, Theme.TextDim, 12, false, true, 1, 20)

                        local valStr = tostring(el.Value) .. (el.Suffix or "")
                        local badgeW = 34
                        local badgeH = 20
                        local badgeX = secX + colW - 16 - badgeW
                        local badgeY = itemY + 2
                        drawRect(badgeX, badgeY, badgeW, badgeH, Theme.ValueBox, true, 1, 20)
                        drawRect(badgeX, badgeY, badgeW, badgeH, Theme.Border, false, 1, 21)
                        drawText(badgeX + (badgeW / 2), badgeY + 4, valStr, Theme.Text, 11, true, true, 1, 22)

                        local trackW = 75
                        local trackH = 3
                        local trackX = badgeX - trackW - 12
                        local trackY = itemY + 11

                        local ratio = math.clamp((el.Value - el.Min) / (el.Max - el.Min), 0, 1)
                        drawRect(trackX, trackY, trackW, trackH, Theme.SliderTrack, true, 1, 22)
                        drawRect(trackX, trackY, trackW * ratio, trackH, Theme.SliderFill, true, 1, 23)

                        local knobPosX = trackX + (trackW * ratio)
                        drawCircle(knobPosX, trackY + 1.5, 5, Color3.fromRGB(255, 255, 255), true, 26)

                        if Input.Mouse1Down and isHovering(trackX - 6, trackY - 8, trackW + 12, trackH + 16) then
                            local newRatio = math.clamp((Input.MousePos.X - trackX) / trackW, 0, 1)
                            local newVal = el.Min + ((el.Max - el.Min) * newRatio)
                            if not el.IsFloat then newVal = math.floor(newVal + 0.5) end
                            el:SetValue(newVal)
                        end

                        itemY = itemY + 36

                    elseif el.Type == "RangeSlider" then
                        drawText(secX + 16, itemY + 5, el.Name, Theme.TextDim, 12, false, true, 1, 20)

                        local rangeStr = string.format("%d-%d%s", el.Low, el.High, el.Suffix or "")
                        local badgeW = 46
                        local badgeH = 20
                        local badgeX = secX + colW - 16 - badgeW
                        local badgeY = itemY + 2
                        drawRect(badgeX, badgeY, badgeW, badgeH, Theme.ValueBox, true, 1, 20)
                        drawRect(badgeX, badgeY, badgeW, badgeH, Theme.Border, false, 1, 21)
                        drawText(badgeX + (badgeW / 2), badgeY + 4, rangeStr, Theme.Text, 10, true, true, 1, 22)

                        local trackW = 65
                        local trackH = 3
                        local trackX = badgeX - trackW - 12
                        local trackY = itemY + 11

                        local rLow = math.clamp((el.Low - el.Min) / (el.Max - el.Min), 0, 1)
                        local rHigh = math.clamp((el.High - el.Min) / (el.Max - el.Min), 0, 1)

                        drawRect(trackX, trackY, trackW, trackH, Theme.SliderTrack, true, 1, 22)
                        drawRect(trackX + (trackW * rLow), trackY, trackW * (rHigh - rLow), trackH, Theme.SliderFill, true, 1, 23)

                        drawCircle(trackX + (trackW * rLow), trackY + 1.5, 4.5, Color3.fromRGB(255, 255, 255), true, 26)
                        drawCircle(trackX + (trackW * rHigh), trackY + 1.5, 4.5, Color3.fromRGB(255, 255, 255), true, 26)

                        if Input.Mouse1Down and isHovering(trackX - 6, trackY - 8, trackW + 12, trackH + 16) then
                            local newRatio = math.clamp((Input.MousePos.X - trackX) / trackW, 0, 1)
                            local val = math.floor(el.Min + ((el.Max - el.Min) * newRatio) + 0.5)
                            if math.abs(val - el.Low) < math.abs(val - el.High) then
                                el:SetValue(val, el.High)
                            else
                                el:SetValue(el.Low, val)
                            end
                        end

                        itemY = itemY + 36

                    elseif el.Type == "Dropdown" then
                        local selW = colW - 32
                        local selH = 26
                        local selX = secX + 16
                        local selY = itemY + 2
                        local hover = isHovering(selX, selY, selW, selH)

                        drawRect(selX, selY, selW, selH, Theme.ValueBox, true, 1, 20)
                        drawRect(selX, selY, selW, selH, hover and Theme.Border or Theme.BorderSubtle, false, 1, 21)

                        local displayVal = el.Name
                        if el.Multi and type(el.Value) == "table" then
                            displayVal = tostring(#el.Value) .. " selected"
                        elseif el.Value and el.Value ~= "" then
                            displayVal = tostring(el.Value)
                        end

                        drawText(selX + 10, selY + 6, displayVal, Theme.TextDim, 12, false, true, 1, 22)
                        drawText(selX + selW - 18, selY + 6, ":::", Theme.TextDark, 11, false, true, 1, 22)

                        if hover and Input.Mouse1Clicked then
                            Input.ActiveDropdown = (Input.ActiveDropdown == el and nil or el)
                            el.PopupPos = Vector2.new(selX, selY + selH + 2)
                        end

                        itemY = itemY + 38

                    elseif el.Type == "Button" then
                        local btnW = colW - 32
                        local btnH = 26
                        local btnX = secX + 16
                        local btnY = itemY + 2
                        local hover = isHovering(btnX, btnY, btnW, btnH)

                        drawRect(btnX, btnY, btnW, btnH, hover and Theme.CardHover or Theme.ValueBox, true, 1, 20)
                        drawRect(btnX, btnY, btnW, btnH, hover and Theme.Border or Theme.BorderSubtle, false, 1, 21)
                        drawText(btnX + (btnW / 2), btnY + 6, el.Name, hover and Theme.Text or Theme.TextDim, 12, true, true, 1, 22)

                        if hover and Input.Mouse1Clicked then el.Callback() end
                        itemY = itemY + 36

                    elseif el.Type == "Input" then
                        local inW = colW - 32
                        local inH = 26
                        local inX = secX + 16
                        local inY = itemY + 2
                        local hover = isHovering(inX, inY, inW, inH)

                        drawRect(inX, inY, inW, inH, Theme.ValueBox, true, 1, 20)
                        drawRect(inX, inY, inW, inH, hover and Theme.Border or Theme.BorderSubtle, false, 1, 21)
                        drawText(inX + 10, inY + 6, el.Value ~= "" and el.Value or el.Name, el.Value ~= "" and Theme.Text or Theme.TextDark, 12, false, true, 1, 22)
                        itemY = itemY + 36
                    end
                end

                if isLeft then leftY = leftY + secHeight + 14
                else rightY = rightY + secHeight + 14 end
            end
        end

        -- =====================================================================
        -- POPUPS & MODALS RENDERING (High Z-Index Layer)
        -- =====================================================================

        -- 1. Dropdown Popup
        if Input.ActiveDropdown and Input.ActiveDropdown.PopupPos then
            local drop = Input.ActiveDropdown
            local px, py = drop.PopupPos.X, drop.PopupPos.Y
            local pw = colW - 32
            local ph = #drop.Options * 24 + 4

            drawRect(px, py, pw, ph, Theme.PopupBg, true, 1, 500)
            drawRect(px, py, pw, ph, Theme.Border, false, 1, 501)

            local optY = py + 2
            for _, opt in ipairs(drop.Options) do
                local optHover = isHovering(px, optY, pw, 24)
                if optHover then drawRect(px + 2, optY, pw - 4, 24, Theme.CardHover, true, 1, 502) end

                local isSelected = false
                if drop.Multi and type(drop.Value) == "table" then
                    for _, v in ipairs(drop.Value) do if v == opt then isSelected = true break end end
                else
                    isSelected = (drop.Value == opt)
                end

                if isSelected then
                    drawText(px + 8, optY + 5, "[x]", Theme.Text, 11, false, true, 1, 505)
                end

                drawText(px + (isSelected and 26 or 12), optY + 5, opt, isSelected and Theme.Text or Theme.TextDim, 12, false, true, 1, 505)

                if optHover and Input.Mouse1Clicked then
                    if drop.Multi then
                        local found = false
                        for idx, v in ipairs(drop.Value) do
                            if v == opt then table.remove(drop.Value, idx) found = true break end
                        end
                        if not found then table.insert(drop.Value, opt) end
                        drop:SetValue(drop.Value)
                    else
                        drop:SetValue(opt)
                        Input.ActiveDropdown = nil
                    end
                end

                optY = optY + 24
            end

            if Input.Mouse1Clicked and not isHovering(px, py - 30, pw, ph + 30) then
                Input.ActiveDropdown = nil
            end
        end

        -- 2. Keybind Mode Popup (Right-Click Context Menu)
        if Input.ActiveKeybindMenu then
            local kbMenu = Input.ActiveKeybindMenu
            local mx, my = kbMenu.X, kbMenu.Y
            local mw, mh = 90, 88
            local modes = { "Hold", "Toggle", "Always", "Click" }

            drawRect(mx, my, mw, mh, Theme.PopupBg, true, 1, 600)
            drawRect(mx, my, mw, mh, Theme.Border, false, 1, 601)

            local mY = my + 2
            for _, mode in ipairs(modes) do
                local mHover = isHovering(mx, mY, mw, 20)
                if mHover then drawRect(mx + 2, mY, mw - 4, 20, Theme.CardHover, true, 1, 602) end

                local isSel = (kbMenu.Keybind.Mode == mode:lower())
                drawText(mx + 8, mY + 3, mode, isSel and Theme.Text or Theme.TextDim, 11, false, true, 1, 605)

                if mHover and Input.Mouse1Clicked then
                    kbMenu.Keybind:SetMode(mode)
                    Input.ActiveKeybindMenu = nil
                end
                mY = mY + 21
            end

            if Input.Mouse1Clicked and not isHovering(mx, my, mw, mh) then
                Input.ActiveKeybindMenu = nil
            end
        end

        -- 3. HSV Color Picker Popup
        if Input.ActiveColorPicker and Input.ActiveColorPicker.PopupPos then
            local cp = Input.ActiveColorPicker
            local cx, cy = cp.PopupPos.X, cp.PopupPos.Y
            local cw, ch = 150, 140

            drawRect(cx, cy, cw, ch, Theme.PopupBg, true, 1, 600)
            drawRect(cx, cy, cw, ch, Theme.Border, false, 1, 601)

            -- 2D Saturation / Value Box
            local svX, svY, svW, svH = cx + 8, cy + 8, 105, 95
            drawRect(svX, svY, svW, svH, hsvToRgb(cp.H, 1, 1), true, 1, 602)
            drawRect(svX, svY, svW, svH, Theme.Border, false, 1, 603)

            -- Handle in SV Box
            local hx = svX + (cp.S * svW)
            local hy = svY + ((1 - cp.V) * svH)
            drawCircle(hx, hy, 4, Color3.fromRGB(255, 255, 255), true, 605)

            if Input.Mouse1Down and isHovering(svX, svY, svW, svH) then
                cp.S = math.clamp((Input.MousePos.X - svX) / svW, 0, 1)
                cp.V = 1 - math.clamp((Input.MousePos.Y - svY) / svH, 0, 1)
                cp:SetColor(hsvToRgb(cp.H, cp.S, cp.V), cp.Alpha)
            end

            -- Vertical Hue Bar
            local hueX, hueY, hueW, hueH = cx + 120, cy + 8, 20, 95
            for step = 0, hueH do
                local hRatio = step / hueH
                drawLine(hueX, hueY + step, hueX + hueW, hueY + step, hsvToRgb(hRatio, 1, 1), 1, 602)
            end
            drawRect(hueX, hueY, hueW, hueH, Theme.Border, false, 1, 603)
            drawLine(hueX - 2, hueY + (cp.H * hueH), hueX + hueW + 2, hueY + (cp.H * hueH), Color3.fromRGB(255, 255, 255), 2, 605)

            if Input.Mouse1Down and isHovering(hueX, hueY, hueW, hueH) then
                cp.H = math.clamp((Input.MousePos.Y - hueY) / hueH, 0, 1)
                cp:SetColor(hsvToRgb(cp.H, cp.S, cp.V), cp.Alpha)
            end

            -- Alpha Bar
            local aX, aY, aW, aH = cx + 8, cy + 112, 132, 16
            drawRect(aX, aY, aW, aH, Theme.SliderTrack, true, 1, 602)
            drawRect(aX, aY, aW * cp.Alpha, aH, cp.Color, true, 1, 603)
            drawRect(aX, aY, aW, aH, Theme.Border, false, 1, 604)

            if Input.Mouse1Down and isHovering(aX, aY, aW, aH) then
                cp.Alpha = math.clamp((Input.MousePos.X - aX) / aW, 0, 1)
                cp:SetColor(cp.Color, cp.Alpha)
            end

            if Input.Mouse1Clicked and not isHovering(cx - 20, cy - 30, cw + 30, ch + 40) then
                Input.ActiveColorPicker = nil
            end
        end
    end)

    function win:Destroy()
        win.Active = false
        if connection then connection:Disconnect() end
        resetDrawPool()
        Maclib:Notify({ Title = "Maclib", Description = "Window closed." })
    end

    _G.Maclib = Maclib
    return win
end

_G.Maclib = Maclib
return Maclib
