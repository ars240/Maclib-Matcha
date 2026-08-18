-- Maclib UI Library (Flicker-Free Persistent Drawing Engine)
-- Author: a256

-- Clean up any previous running instances
if _G.MaclibInstance then
    pcall(function() _G.MaclibInstance:Destroy() end)
    _G.MaclibInstance = nil
end

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local Maclib = {
    Version = "3.2.0",
    Flags = {},
    Elements = {},
    Keybinds = {},
    Colors = {},
    Open = true,
    ConfigFolder = "MaclibConfigs",
    HotkeysEnabled = false,
    WatermarkEnabled = true,
    Delta = 0.016
}

local function Approach(current, target, speed)
    return current + (target - current) * (1 - math.exp(-speed * Maclib.Delta))
end

local function Blend(c1, c2, alpha)
    return c1:lerp(c2, alpha)
end


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

-- =========================================================================
-- FLICKER-FREE PERSISTENT DRAWING POOL
-- =========================================================================
local Squares = {}
local Texts = {}
local Lines = {}
local Circles = {}
local Images = {}

local SqIdx = 0
local TxtIdx = 0
local LnIdx = 0
local CircIdx = 0
local ImgIdx = 0

local function beginFrame()
    SqIdx = 0
    TxtIdx = 0
    LnIdx = 0
    CircIdx = 0
    ImgIdx = 0
end

local function endFrame()
    for i = SqIdx + 1, #Squares do
        if Squares[i].Visible then Squares[i].Visible = false end
    end
    for i = TxtIdx + 1, #Texts do
        if Texts[i].Visible then Texts[i].Visible = false end
    end
    for i = LnIdx + 1, #Lines do
        if Lines[i].Visible then Lines[i].Visible = false end
    end
    for i = CircIdx + 1, #Circles do
        if Circles[i].Visible then Circles[i].Visible = false end
    end
    for i = ImgIdx + 1, #Images do
        if Images[i].Visible then Images[i].Visible = false end
    end
end

local function cleanupAllDrawings()
    for _, s in ipairs(Squares) do pcall(function() s:Remove() end) end
    for _, t in ipairs(Texts) do pcall(function() t:Remove() end) end
    for _, l in ipairs(Lines) do pcall(function() l:Remove() end) end
    for _, c in ipairs(Circles) do pcall(function() c:Remove() end) end
    for _, img in ipairs(Images) do pcall(function() img:Remove() end) end
    Squares = {}
    Texts = {}
    Lines = {}
    Circles = {}
    Images = {}
end

local function drawRect(x, y, w, h, color, filled, thickness, zIndex)
    SqIdx = SqIdx + 1
    local s = Squares[SqIdx]
    if not s then
        s = Drawing.new("Square")
        Squares[SqIdx] = s
    end
    s.Position = Vector2.new(x, y)
    s.Size = Vector2.new(w, h)
    s.Color = color
    s.Filled = (filled == nil and true or filled)
    s.Thickness = thickness or 1
    s.ZIndex = zIndex or 10
    if not s.Visible then s.Visible = true end
    return s
end

local function drawCircle(x, y, radius, color, filled, zIndex)
    CircIdx = CircIdx + 1
    local c = Circles[CircIdx]
    if not c then
        c = Drawing.new("Circle")
        Circles[CircIdx] = c
    end
    c.Position = Vector2.new(x, y)
    c.Radius = radius
    c.Color = color
    c.Filled = (filled == nil and true or filled)
    c.ZIndex = zIndex or 15
    if not c.Visible then c.Visible = true end
    return c
end

local function drawText(x, y, text, color, size, center, outline, font, zIndex)
    TxtIdx = TxtIdx + 1
    local t = Texts[TxtIdx]
    if not t then
        t = Drawing.new("Text")
        Texts[TxtIdx] = t
    end
    t.Position = Vector2.new(x, y)
    t.Text = tostring(text or "")
    t.Color = color or Theme.Text
    t.Size = size or 13
    t.Center = center or false
    t.Outline = (outline == nil and true or outline)
    t.Font = font or Drawing.Fonts.System or 1
    t.ZIndex = zIndex or 20
    if not t.Visible then t.Visible = true end
    return t
end

local function drawLine(fromX, fromY, toX, toY, color, thickness, zIndex)
    LnIdx = LnIdx + 1
    local l = Lines[LnIdx]
    if not l then
        l = Drawing.new("Line")
        Lines[LnIdx] = l
    end
    l.From = Vector2.new(fromX, fromY)
    l.To = Vector2.new(toX, toY)
    l.Color = color or Theme.Border
    l.Thickness = thickness or 1
    l.ZIndex = zIndex or 15
    if not l.Visible then l.Visible = true end
    return l
end

local function drawImage(x, y, w, h, data, zIndex, rounding)
    if not data then return end
    ImgIdx = ImgIdx + 1
    local img = Images[ImgIdx]
    if not img then
        img = Drawing.new("Image")
        Images[ImgIdx] = img
    end
    if img._storedData ~= data then
        img.Data = data
        img._storedData = data
    end
    img.Position = Vector2.new(x, y)
    img.Size = Vector2.new(w, h)
    pcall(function() img.Rounding = rounding or 0 end)
    img.ZIndex = zIndex or 15
    if not img.Visible then img.Visible = true end
    return img
end

local function drawIcon(name, cx, cy, size, color, z)
    if name == "Ragebot" then
        -- Crosshair
        drawCircle(cx, cy, size/2, color, false, z)
        drawLine(cx - size/2 - 2, cy, cx - 2, cy, color, 1, z)
        drawLine(cx + 2, cy, cx + size/2 + 2, cy, color, 1, z)
        drawLine(cx, cy - size/2 - 2, cx, cy - 2, color, 1, z)
        drawLine(cx, cy + 2, cx, cy + size/2 + 2, color, 1, z)
        drawCircle(cx, cy, 1, color, true, z)
    elseif name == "Anti Aim" then
        -- Shield
        drawLine(cx - size/2, cy - size/2 + 2, cx + size/2, cy - size/2 + 2, color, 1.5, z)
        drawLine(cx - size/2, cy - size/2 + 2, cx, cy + size/2, color, 1.5, z)
        drawLine(cx + size/2, cy - size/2 + 2, cx, cy + size/2, color, 1.5, z)
        drawCircle(cx, cy, 2, color, true, z)
    elseif name == "Visuals" then
        -- Eye
        drawLine(cx - size/2, cy, cx, cy - size/2 + 2, color, 1.5, z)
        drawLine(cx, cy - size/2 + 2, cx + size/2, cy, color, 1.5, z)
        drawLine(cx - size/2, cy, cx, cy + size/2 - 2, color, 1.5, z)
        drawLine(cx, cy + size/2 - 2, cx + size/2, cy, color, 1.5, z)
        drawCircle(cx, cy, 2, color, true, z)
    elseif name == "Skins" then
        -- Paintbrush/Drop
        drawCircle(cx, cy + size/4, size/3, color, false, z)
        drawLine(cx - size/3, cy + size/4, cx, cy - size/2, color, 1, z)
        drawLine(cx + size/3, cy + size/4, cx, cy - size/2, color, 1, z)
    elseif name == "Misc" then
        -- Gear
        drawCircle(cx, cy, size/3, color, false, z)
        drawCircle(cx, cy, 1, color, true, z)
        drawLine(cx, cy - size/2, cx, cy - size/3, color, 2, z)
        drawLine(cx, cy + size/3, cx, cy + size/2, color, 2, z)
        drawLine(cx - size/2, cy, cx - size/3, cy, color, 2, z)
        drawLine(cx + size/3, cy, cx + size/2, cy, color, 2, z)
    elseif name == "Configs" then
        -- Document
        drawLine(cx - size/2 + 2, cy - size/2, cx + size/2 - 2, cy - size/2, color, 1, z)
        drawLine(cx - size/2 + 2, cy + size/2, cx + size/2 - 2, cy + size/2, color, 1, z)
        drawLine(cx - size/2 + 2, cy - size/2, cx - size/2 + 2, cy + size/2, color, 1, z)
        drawLine(cx + size/2 - 2, cy - size/2, cx + size/2 - 2, cy + size/2, color, 1, z)
        drawLine(cx - size/2 + 4, cy - 2, cx + size/2 - 4, cy - 2, color, 1, z)
        drawLine(cx - size/2 + 4, cy + 2, cx + size/2 - 4, cy + 2, color, 1, z)
    elseif name == "Settings" then
        -- Slider icon
        drawLine(cx - size/2, cy - 3, cx + size/2, cy - 3, color, 1, z)
        drawLine(cx - size/2, cy + 3, cx + size/2, cy + 3, color, 1, z)
        drawCircle(cx - 2, cy - 3, 2, color, true, z)
        drawCircle(cx + 2, cy + 3, 2, color, true, z)
    else
        -- Fallback Square
        drawRect(cx - size/2, cy - size/2, size, size, color, false, 1, z)
    end
end

-- Input System
local Input = {
    MousePos = Vector2.new(0, 0),
    Mouse1Down = false,
    Mouse2Down = false,
    Mouse1Clicked = false,
    Mouse2Clicked = false,
    ActiveDropdown = nil,
    KeyListeningObj = nil
}

local prevM1 = false
local prevM2 = false

local function updateInput()
    local m1 = ismouse1pressed and ismouse1pressed() or false
    local m2 = ismouse2pressed and ismouse2pressed() or false

    Input.Mouse1Clicked = (m1 and not prevM1)
    Input.Mouse2Clicked = (m2 and not prevM2)
    Input.Mouse1Down = m1

    prevM1 = m1
    prevM2 = m2

    if LocalPlayer and LocalPlayer:GetMouse() then
        local mouse = LocalPlayer:GetMouse()
        Input.MousePos = Vector2.new(mouse.X, mouse.Y)
    end

    if Input.KeyListeningObj and iskeypressed then
        for vk = 0x01, 0xFE do
            if iskeypressed(vk) then
                if vk == 0x1B then Input.KeyListeningObj:SetKey(0x00)
                else Input.KeyListeningObj:SetKey(vk) end
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
-- NOTIFICATIONS
-- =========================================================================
local Notifications = {}

function Maclib:Notify(options)
    table.insert(Notifications, {
        Title = options.Title or "Maclib",
        Description = options.Description or "",
        Duration = options.Lifetime or options.Duration or 3.5,
        CreatedAt = tick()
    })
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
-- MAIN WINDOW FACTORY (100% Flicker-Free)
-- =========================================================================
function Maclib:Window(config)
    config = config or {}
    local win = {
        Title = config.Title or "Karpiware 6.1.0",
        Subtitle = config.Subtitle or "Build - Paid (Stable) | Universal",
        Username = config.Username or (LocalPlayer and LocalPlayer.Name) or "a256",
        UserHandle = config.UserHandle or (LocalPlayer and ("@" .. LocalPlayer.Name)) or "@a256",
        ConfigFolder = config.ConfigFolder or Maclib.ConfigFolder,
        ToggleKey = config.ToggleKey or 0x2D, -- Insert
        X = config.X or 180,
        Y = config.Y or 120,
        Width = config.Width or 840,
        Height = config.Height or 580,
        Tabs = {},
        ActiveTabIndex = 1,
        Dragging = false,
        DragOffset = Vector2.new(0, 0),
        Active = true,
        AvatarData = nil
    }

    if LocalPlayer and LocalPlayer.UserId > 0 then
        task.spawn(function()
            pcall(function()
                local HttpService = game:GetService("HttpService")
                local url = "https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=" .. tostring(LocalPlayer.UserId) .. "&size=150x150&format=Png&isCircular=false"
                local res = game:HttpGet(url)
                local data = HttpService:JSONDecode(res)
                if data and data.data and data.data[1] and data.data[1].imageUrl then
                    win.AvatarData = game:HttpGet(data.data[1].imageUrl)
                end
            end)
        end)
    end

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

            -- 1. Toggle
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

                function toggleObj:Keybind(kbConfig)
                    local kbId = kbConfig.Id or (id .. "_kb")
                    local key = kbConfig.Default or 0x00
                    local mode = (kbConfig.Mode or "hold"):lower()

                    local kbObj = {
                        Id = kbId,
                        Type = "Keybind",
                        Key = key,
                        Mode = mode,
                        Listening = false
                    }

                    function kbObj:SetKey(newKey)
                        kbObj.Key = newKey
                    end

                    table.insert(toggleObj.SubElements, kbObj)
                    return kbObj
                end

                function toggleObj:Colorpicker(cpConfig)
                    local cpId = cpConfig.Id or (id .. "_col")
                    local defCol = cpConfig.Default or Color3.fromRGB(80, 140, 245)

                    local cpObj = {
                        Id = cpId,
                        Type = "ColorPicker",
                        Color = defCol
                    }

                    table.insert(toggleObj.SubElements, cpObj)
                    return cpObj
                end

                table.insert(secObj.Elements, toggleObj)
                return toggleObj
            end

            -- 2. Slider
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

            -- 3. Range Slider
            function secObj:RangeSlider(rConfig)
                local id = rConfig.Id or (tabName .. "_" .. secName .. "_" .. (rConfig.Name or "Range"))
                local label = rConfig.Name or "Range"
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

            -- 4. Dropdown
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

                table.insert(secObj.Elements, dropObj)
                return dropObj
            end

            -- 5. Button
            function secObj:Button(bConfig)
                local label = bConfig.Name or "Button"
                local callback = bConfig.Callback or function() end
                local btnObj = { Name = label, Type = "Button", Callback = callback }
                table.insert(secObj.Elements, btnObj)
                return btnObj
            end

            table.insert(tabObj.Sections, secObj)
            return secObj
        end

        table.insert(win.Tabs, tabObj)
        return tabObj
    end

    function win:BuildConfigSection(targetTab, targetSide)
        local sec = targetTab:Section({ Name = "Configuration", Side = targetSide or "Right" })
        sec:Button({
            Name = "Save Config",
            Callback = function() Maclib:Notify({ Title = "Config", Description = "Config Saved!" }) end
        })
        sec:Button({
            Name = "Load Config",
            Callback = function() Maclib:Notify({ Title = "Config", Description = "Config Loaded!" }) end
        })
        return sec
    end

    -- =========================================================================
    -- RENDERING LOOP
    -- =========================================================================
    local connection
    local lastTick = tick()
    connection = RunService.Heartbeat:Connect(function()
        local currentTick = tick()
        Maclib.Delta = math.min(currentTick - lastTick, 1/15)
        lastTick = currentTick
        
        if not win.Active then
            connection:Disconnect()
            cleanupAllDrawings()
            return
        end

        updateInput()
        beginFrame()

        renderNotifications()

        if win.ToggleKey and iskeypressed and iskeypressed(win.ToggleKey) then
            if not win.ToggleDebounce then
                Maclib.Open = not Maclib.Open
                win.ToggleDebounce = true
            end
        else
            win.ToggleDebounce = false
        end

        if not Maclib.Open then
            endFrame()
            return
        end

        local wx, wy = win.X, win.Y
        local ww, wh = win.Width, win.Height

        -- Window Dragging
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

        -- Draw Geometric Logo for Maclib
        local logoSize = 16
        local logoX = wx + 26
        local logoY = wy + 54
        local accColor = Color3.fromRGB(122, 134, 255)
        local accDark = Color3.fromRGB(189, 130, 255)
        -- diamond
        drawLine(logoX, logoY - logoSize/2, logoX + logoSize/2, logoY, accColor, 2, 20)
        drawLine(logoX + logoSize/2, logoY, logoX, logoY + logoSize/2, accDark, 2, 20)
        drawLine(logoX, logoY + logoSize/2, logoX - logoSize/2, logoY, accDark, 2, 20)
        drawLine(logoX - logoSize/2, logoY, logoX, logoY - logoSize/2, accColor, 2, 20)
        -- inner cross
        drawLine(logoX, logoY - logoSize/2, logoX, logoY + logoSize/2, Theme.TextDim, 1, 20)
        drawLine(logoX - logoSize/2, logoY, logoX + logoSize/2, logoY, Theme.TextDim, 1, 20)

        drawText(wx + 44, wy + 44, win.Title, Theme.Text, 14, false, true, 1, 20)
        drawText(wx + 44, wy + 62, win.Subtitle, Theme.TextDim, 11, false, true, 1, 20)

        -- 4. Sidebar Tabs
        local tabStartY = wy + 96
        for idx, tab in ipairs(win.Tabs) do
            local isSelected = (idx == win.ActiveTabIndex)
            local itemY = tabStartY + ((idx - 1) * 40)
            local hover = isHovering(wx + 16, itemY, sidebarW - 32, 34)

            if isSelected then
                drawRect(wx + 16, itemY, sidebarW - 32, 34, Theme.ActiveTab, true, 1, 15)
                drawRect(wx + 16, itemY, sidebarW - 32, 34, Theme.Border, false, 1, 16)
                drawIcon(tab.Name, wx + 30, itemY + 17, 14, Theme.Text, 22)
                drawText(wx + 44, itemY + 9, tab.Name, Theme.Text, 13, false, true, 1, 22)
            else
                if hover then drawRect(wx + 16, itemY, sidebarW - 32, 34, Theme.CardBg, true, 1, 14) end
                drawIcon(tab.Name, wx + 30, itemY + 17, 14, Theme.TextDark, 20)
                drawText(wx + 44, itemY + 9, tab.Name, hover and Theme.Text or Theme.TextDim, 13, false, true, 1, 20)
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

        if win.AvatarData then
            drawImage(wx + 22, profileY + 14, 28, 28, win.AvatarData, 20, 14)
        else
            local initial = string.sub(win.Username, 1, 1):upper()
            drawText(wx + 36, profileY + 21, initial, Theme.Text, 13, true, true, 1, 20)
        end

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

                local secHeight = 16
                for _, el in ipairs(sec.Elements) do
                    if el.Type == "Toggle" then secHeight = secHeight + 36
                    elseif el.Type == "Slider" or el.Type == "RangeSlider" then secHeight = secHeight + 36
                    elseif el.Type == "Dropdown" then secHeight = secHeight + 38
                    elseif el.Type == "Button" then secHeight = secHeight + 36 end
                end

                drawRect(secX, curY, colW, secHeight, Theme.CardBg, true, 1, 14)
                drawRect(secX, curY, colW, secHeight, Theme.Border, false, 1, 15)

                local itemY = curY + 10
                for _, el in ipairs(sec.Elements) do
                    if el.Type == "Toggle" then
                        drawText(secX + 16, itemY + 5, el.Name, Theme.TextDim, 12, false, true, 1, 20)

                        local swW, swH = 34, 18
                        local swX = secX + colW - 16 - swW
                        local swY = itemY + 4
                        local hover = isHovering(swX - 4, swY - 2, swW + 8, swH + 4)

                        el.TogglePos = Approach(el.TogglePos or (el.Value and 1 or 0), el.Value and 1 or 0, 20)
                        local swColor = Blend(Theme.SwitchOff, Theme.SwitchOn, el.TogglePos)
                        local knobColor = Blend(Theme.KnobOff, Theme.KnobOn, el.TogglePos)
                        
                        drawRect(swX, swY, swW, swH, swColor, true, 1, 22)
                        drawRect(swX, swY, swW, swH, Theme.Border, false, 1, 23)

                        local knobX = swX + 4 + (el.TogglePos * (swW - 18))
                        drawCircle(knobX + 5, swY + 9, 6, knobColor, true, 25)

                        if (hover or isHovering(secX + 16, itemY, colW - 32, 28)) and Input.Mouse1Clicked then
                            el:SetValue(not el.Value)
                        end

                        -- Render Nested Keybind Chip
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
                    end
                end

                if isLeft then leftY = leftY + secHeight + 14
                else rightY = rightY + secHeight + 14 end
            end
        end

        -- Dropdown Popup
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

        endFrame()
    end)

    function win:Destroy()
        win.Active = false
        if connection then connection:Disconnect() end
        cleanupAllDrawings()
    end

    _G.MaclibInstance = win
    _G.Maclib = Maclib
    return win
end

_G.Maclib = Maclib
return Maclib
