-- Maclib (Full INS-ui Architectural Parity & Feature Complete Engine)
-- High-Performance Flicker-Free Drawing Engine for Roblox Executors (Matcha, Synapse, etc.)

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Cleanup previous instance
if _G.MaclibInstance then
    pcall(function() _G.MaclibInstance:Destroy() end)
    _G.MaclibInstance = nil
end

local Maclib = {
    Version = "4.0.0",
    Flags = {},
    Elements = {},
    Keybinds = {},
    Colors = {},
    Open = true,
    ConfigFolder = "MaclibConfigs",
    WatermarkEnabled = true,
    KeybindOverlayEnabled = true,
    BackgroundFX = "Off",
    Delta = 0.016,
    FPS = 60,
    ActiveColorPicker = nil,
    ActiveKeyMenu = nil,
    DropdownContext = nil
}
_G.Maclib = Maclib

-- =========================================================================
-- THEME SYSTEM (Fully Dynamic & Modifiable at Runtime)
-- =========================================================================
local Theme = {
    WindowBg = Color3.fromRGB(15, 15, 17),
    SidebarBg = Color3.fromRGB(12, 12, 14),
    CardBg = Color3.fromRGB(20, 20, 24),
    ActiveTab = Color3.fromRGB(28, 28, 34),
    Border = Color3.fromRGB(45, 45, 54),
    BorderSubtle = Color3.fromRGB(32, 32, 38),
    Accent = Color3.fromRGB(122, 134, 255),
    AccentA = Color3.fromRGB(122, 134, 255),
    AccentB = Color3.fromRGB(189, 130, 255),
    Text = Color3.fromRGB(240, 240, 245),
    TextDim = Color3.fromRGB(155, 155, 170),
    TextDark = Color3.fromRGB(90, 90, 105),
    Close = Color3.fromRGB(255, 95, 87),
    Minimize = Color3.fromRGB(254, 188, 46),
    Maximize = Color3.fromRGB(39, 201, 63),
    SwitchOn = Color3.fromRGB(122, 134, 255),
    SwitchOff = Color3.fromRGB(35, 35, 42),
    KnobOn = Color3.fromRGB(255, 255, 255),
    KnobOff = Color3.fromRGB(140, 140, 155),
    ValueBox = Color3.fromRGB(26, 26, 32)
}
Maclib.Theme = Theme

function Maclib:SetAccent(col)
    Theme.Accent = col
    Theme.AccentA = col
    Theme.SwitchOn = col
end

function Maclib:SetBackground(col)
    Theme.WindowBg = col
end

-- =========================================================================
-- MATH & ANIMATION UTILITIES (INS-ui Lerp Engine)
-- =========================================================================
local function Approach(current, target, speed)
    return current + (target - current) * (1 - math.exp(-speed * Maclib.Delta))
end

local function Blend(c1, c2, alpha)
    return c1:lerp(c2, math.clamp(alpha, 0, 1))
end

-- =========================================================================
-- PERSISTENT DRAWING OBJECT POOL (Flicker-Free Engine)
-- =========================================================================
local Pool = {
    Squares = {},
    Texts = {},
    Lines = {},
    Circles = {},
    Triangles = {},
    Images = {}
}

local Idx = { Sq = 0, Tx = 0, Ln = 0, Cr = 0, Tr = 0, Im = 0 }

local function beginFrame()
    Idx.Sq = 0
    Idx.Tx = 0
    Idx.Ln = 0
    Idx.Cr = 0
    Idx.Tr = 0
    Idx.Im = 0
end

local function endFrame()
    for i = Idx.Sq + 1, #Pool.Squares do Pool.Squares[i].Visible = false end
    for i = Idx.Tx + 1, #Pool.Texts do Pool.Texts[i].Visible = false end
    for i = Idx.Ln + 1, #Pool.Lines do Pool.Lines[i].Visible = false end
    for i = Idx.Cr + 1, #Pool.Circles do Pool.Circles[i].Visible = false end
    for i = Idx.Tr + 1, #Pool.Triangles do Pool.Triangles[i].Visible = false end
    for i = Idx.Im + 1, #Pool.Images do Pool.Images[i].Visible = false end
end

local function cleanupAllDrawings()
    for _, list in pairs(Pool) do
        for _, obj in ipairs(list) do
            pcall(function() obj.Visible = false; obj:Remove() end)
        end
    end
    Pool = { Squares = {}, Texts = {}, Lines = {}, Circles = {}, Triangles = {}, Images = {} }
end

local function drawRect(x, y, w, h, col, filled, trans, z)
    Idx.Sq = Idx.Sq + 1
    local obj = Pool.Squares[Idx.Sq]
    if not obj then
        obj = Drawing.new("Square")
        Pool.Squares[Idx.Sq] = obj
    end
    obj.Position = Vector2.new(x, y)
    obj.Size = Vector2.new(w, h)
    obj.Color = col or Color3.new(1, 1, 1)
    obj.Filled = (filled ~= false)
    obj.Thickness = 1
    obj.Transparency = trans or 1
    obj.ZIndex = z or 10
    obj.Visible = true
    return obj
end

local function drawText(x, y, str, col, size, center, outline, trans, z)
    Idx.Tx = Idx.Tx + 1
    local obj = Pool.Texts[Idx.Tx]
    if not obj then
        obj = Drawing.new("Text")
        Pool.Texts[Idx.Tx] = obj
    end
    obj.Position = Vector2.new(x, y)
    obj.Text = tostring(str or "")
    obj.Color = col or Theme.Text
    obj.Size = size or 13
    obj.Center = (center == true)
    obj.Outline = (outline ~= false)
    obj.OutlineColor = Color3.fromRGB(10, 10, 12)
    obj.Transparency = trans or 1
    obj.ZIndex = z or 20
    obj.Visible = true
    return obj
end

local function drawLine(fromX, fromY, toX, toY, col, thickness, trans, z)
    Idx.Ln = Idx.Ln + 1
    local obj = Pool.Lines[Idx.Ln]
    if not obj then
        obj = Drawing.new("Line")
        Pool.Lines[Idx.Ln] = obj
    end
    obj.From = Vector2.new(fromX, fromY)
    obj.To = Vector2.new(toX, toY)
    obj.Color = col or Theme.Accent
    obj.Thickness = thickness or 1
    obj.Transparency = trans or 1
    obj.ZIndex = z or 15
    obj.Visible = true
    return obj
end

local function drawCircle(x, y, radius, col, filled, z, trans)
    Idx.Cr = Idx.Cr + 1
    local obj = Pool.Circles[Idx.Cr]
    if not obj then
        obj = Drawing.new("Circle")
        Pool.Circles[Idx.Cr] = obj
    end
    obj.Position = Vector2.new(x, y)
    obj.Radius = radius or 5
    obj.Color = col or Theme.Accent
    obj.Filled = (filled ~= false)
    obj.Thickness = 1
    obj.Transparency = trans or 1
    obj.ZIndex = z or 25
    obj.Visible = true
    return obj
end

local function drawImage(x, y, w, h, data, trans, z)
    Idx.Im = Idx.Im + 1
    local obj = Pool.Images[Idx.Im]
    if not obj then
        local success, newObj = pcall(function() return Drawing.new("Image") end)
        if success and newObj then
            obj = newObj
            Pool.Images[Idx.Im] = obj
        else
            return nil
        end
    end
    obj.Position = Vector2.new(x, y)
    obj.Size = Vector2.new(w, h)
    if data then obj.Data = data end
    obj.Transparency = trans or 1
    obj.ZIndex = z or 20
    obj.Visible = true
    return obj
end

-- Custom Vector Icons
local function drawIcon(name, cx, cy, size, color, z)
    local r = (size or 14) / 2
    local col = color or Theme.Text
    local zi = z or 20

    if name == "Ragebot" then
        drawCircle(cx, cy, r, col, false, zi)
        drawCircle(cx, cy, 2, col, true, zi)
        drawLine(cx - r - 2, cy, cx - 2, cy, col, 1, 1, zi)
        drawLine(cx + 2, cy, cx + r + 2, cy, col, 1, 1, zi)
        drawLine(cx, cy - r - 2, cx, cy - 2, col, 1, 1, zi)
        drawLine(cx, cy + 2, cx, cy + r + 2, col, 1, 1, zi)
    elseif name == "Anti Aim" then
        drawLine(cx - r, cy - r + 2, cx + r, cy - r + 2, col, 1.5, 1, zi)
        drawLine(cx - r, cy - r + 2, cx - r, cy, col, 1.5, 1, zi)
        drawLine(cx + r, cy - r + 2, cx + r, cy, col, 1.5, 1, zi)
        drawLine(cx - r, cy, cx, cy + r, col, 1.5, 1, zi)
        drawLine(cx + r, cy, cx, cy + r, col, 1.5, 1, zi)
    elseif name == "Visuals" then
        drawLine(cx - r - 1, cy, cx, cy - r + 2, col, 1.5, 1, zi)
        drawLine(cx, cy - r + 2, cx + r + 1, cy, col, 1.5, 1, zi)
        drawLine(cx - r - 1, cy, cx, cy + r - 2, col, 1.5, 1, zi)
        drawLine(cx, cy + r - 2, cx + r + 1, cy, col, 1.5, 1, zi)
        drawCircle(cx, cy, 3, col, true, zi)
    elseif name == "Skins" then
        drawLine(cx - r + 3, cy - r + 3, cx + r - 2, cy + r - 2, col, 2, 1, zi)
        drawCircle(cx - r + 2, cy - r + 2, 3, col, true, zi)
    elseif name == "Configs" then
        drawRect(cx - r + 2, cy - r, (r * 2) - 4, r * 2, col, false, 1, zi)
        drawLine(cx - r + 4, cy - r + 4, cx + r - 4, cy - r + 4, col, 1, 1, zi)
        drawLine(cx - r + 4, cy, cx + r - 4, cy, col, 1, 1, zi)
    elseif name == "Settings" then
        drawCircle(cx, cy, r - 1, col, false, zi)
        drawCircle(cx, cy, 2.5, col, true, zi)
        for ang = 0, 315, 45 do
            local rad = math.rad(ang)
            local sx = cx + math.cos(rad) * (r - 2)
            local sy = cy + math.sin(rad) * (r - 2)
            local ex = cx + math.cos(rad) * (r + 2)
            local ey = cy + math.sin(rad) * (r + 2)
            drawLine(sx, sy, ex, ey, col, 1.5, 1, zi)
        end
    else
        drawCircle(cx, cy, r - 2, col, false, zi)
        drawCircle(cx, cy, 2, col, true, zi)
    end
end

-- =========================================================================
-- INPUT HANDLING
-- =========================================================================
local Input = {
    MousePos = Vector2.new(0, 0),
    Mouse1Down = false,
    Mouse1Clicked = false,
    Mouse2Down = false,
    Mouse2Clicked = false,
    PrevMouse1 = false,
    PrevMouse2 = false,
    KeyListeningObj = nil
}

local function isHovering(x, y, w, h)
    local mx, my = Input.MousePos.X, Input.MousePos.Y
    return mx >= x and mx <= x + w and my >= y and my <= y + h
end

local KeyNames = {
    [0x01] = "M1", [0x02] = "M2", [0x04] = "M3", [0x08] = "Back", [0x09] = "Tab",
    [0x0D] = "Enter", [0x10] = "Shift", [0x11] = "Ctrl", [0x12] = "Alt",
    [0x1B] = "Esc", [0x20] = "Space", [0x2D] = "Insert", [0x2E] = "Delete",
    [0x70] = "F1", [0x71] = "F2", [0x72] = "F3", [0x73] = "F4", [0x74] = "F5",
    [0x75] = "F6", [0x76] = "F7", [0x77] = "F8", [0x78] = "F9", [0x79] = "F10",
    [0x7A] = "F11", [0x7B] = "F12"
}

local function getKeyName(key)
    if not key or key == 0 then return "None" end
    if KeyNames[key] then return KeyNames[key] end
    if key >= 0x41 and key <= 0x5A then return string.char(key) end
    if key >= 0x30 and key <= 0x39 then return string.char(key) end
    return "0x" .. string.format("%X", key)
end

local function updateInput()
    local mouse = (UserInputService:GetMouseLocation and UserInputService:GetMouseLocation()) or Vector2.new(0,0)
    Input.MousePos = mouse

    local m1 = ismouse1pressed and ismouse1pressed() or false
    local m2 = ismouse2pressed and ismouse2pressed() or false

    Input.Mouse1Clicked = m1 and not Input.PrevMouse1
    Input.Mouse1Down = m1
    Input.PrevMouse1 = m1

    Input.Mouse2Clicked = m2 and not Input.PrevMouse2
    Input.Mouse2Down = m2
    Input.PrevMouse2 = m2

    if Input.KeyListeningObj and iskeypressed then
        for k = 1, 255 do
            if iskeypressed(k) then
                if k == 0x1B then
                    Input.KeyListeningObj.Key = 0
                else
                    Input.KeyListeningObj.Key = k
                end
                Input.KeyListeningObj.Listening = false
                if Input.KeyListeningObj.Callback then
                    Input.KeyListeningObj.Callback(Input.KeyListeningObj.Key)
                end
                Input.KeyListeningObj = nil
                break
            end
        end
    end
end

-- =========================================================================
-- BACKGROUND PARTICLES ENGINE (Snow, Stars, Matrix)
-- =========================================================================
local Particles = {}
for i = 1, 60 do
    table.insert(Particles, {
        X = math.random(0, 1920),
        Y = math.random(0, 1080),
        Speed = math.random(25, 90),
        Size = math.random(2, 4),
        Alpha = math.random(30, 90) / 100,
        Drift = (math.random() - 0.5) * 20,
        Char = string.char(math.random(65, 90))
    })
end

local function drawBackgroundFX()
    local mode = Maclib.BackgroundFX
    if not mode or mode == "Off" then return end

    local dt = Maclib.Delta
    for _, p in ipairs(Particles) do
        p.Y = p.Y + (p.Speed * dt)
        p.X = p.X + (p.Drift * dt)
        if p.Y > 1080 then p.Y = 0; p.X = math.random(0, 1920) end
        if p.X > 1920 then p.X = 0 elseif p.X < 0 then p.X = 1920 end

        if mode == "Snow" then
            drawCircle(p.X, p.Y, p.Size, Color3.fromRGB(240, 245, 255), true, 2, p.Alpha)
        elseif mode == "Stars" then
            local pulse = math.abs(math.sin(tick() * 2 + p.X))
            drawCircle(p.X, p.Y, p.Size - 1, Color3.fromRGB(255, 255, 220), true, 2, pulse * p.Alpha)
        elseif mode == "Matrix" then
            drawText(p.X, p.Y, p.Char, Color3.fromRGB(50, 255, 120), 12, true, false, p.Alpha, 2)
            drawLine(p.X, p.Y - 8, p.X, p.Y + 8, Color3.fromRGB(30, 200, 80), 1, p.Alpha * 0.5, 2)
        end
    end
end

-- =========================================================================
-- WATERMARK & OVERLAYS
-- =========================================================================
local function drawWatermark(win)
    if not Maclib.WatermarkEnabled then return end
    local user = (LocalPlayer and LocalPlayer.Name) or win.Username or "User"
    local text = string.format("%s | %s | %d FPS", win.Title or "Maclib", user, math.floor(Maclib.FPS))
    local w = (#text * 7.5) + 24
    local h = 26
    local x, y = 20, 20

    drawRect(x, y, w, h, Theme.WindowBg, true, 0.9, 50)
    drawRect(x, y, w, h, Theme.Border, false, 1, 51)
    drawLine(x, y, x + w, y, Theme.Accent, 2, 1, 52)
    drawText(x + 12, y + 6, text, Theme.Text, 12, false, true, 1, 53)
end

-- Draggable Hotkey HUD
local HotkeyHUD = { X = 20, Y = 60, Width = 180, Dragging = false, DragOffset = Vector2.new(0, 0) }

local function drawHotkeyOverlay()
    if not Maclib.KeybindOverlayEnabled then return end

    local activeBinds = {}
    for _, kb in pairs(Maclib.Keybinds) do
        if kb.Key and kb.Key ~= 0 then
            table.insert(activeBinds, kb)
        end
    end

    local h = 32 + (#activeBinds * 22)
    if #activeBinds == 0 then h = 50 end
    local x, y = HotkeyHUD.X, HotkeyHUD.Y
    local w = HotkeyHUD.Width

    -- Dragging logic
    if Input.Mouse1Clicked and isHovering(x, y, w, 24) then
        HotkeyHUD.Dragging = true
        HotkeyHUD.DragOffset = Vector2.new(Input.MousePos.X - x, Input.MousePos.Y - y)
    end
    if HotkeyHUD.Dragging then
        if Input.Mouse1Down then
            HotkeyHUD.X = Input.MousePos.X - HotkeyHUD.DragOffset.X
            HotkeyHUD.Y = Input.MousePos.Y - HotkeyHUD.DragOffset.Y
            x, y = HotkeyHUD.X, HotkeyHUD.Y
        else
            HotkeyHUD.Dragging = false
        end
    end

    drawRect(x, y, w, h, Theme.WindowBg, true, 0.9, 60)
    drawRect(x, y, w, h, Theme.Border, false, 1, 61)
    drawLine(x, y, x + w, y, Theme.Accent, 2, 1, 62)
    drawText(x + 10, y + 6, "Keybinds", Theme.Text, 12, false, true, 1, 63)

    if #activeBinds == 0 then
        drawText(x + (w / 2), y + 28, "No Active Keybinds", Theme.TextDark, 11, true, true, 1, 63)
    else
        local curY = y + 28
        for _, kb in ipairs(activeBinds) do
            local isActive = kb.Active
            local dotCol = isActive and Theme.Accent or Theme.TextDark
            drawCircle(x + 12, curY + 6, 3.5, dotCol, true, 64)
            drawText(x + 22, curY, kb.Name, isActive and Theme.Text or Theme.TextDim, 11, false, true, 1, 64)

            local kStr = string.format("[%s]", getKeyName(kb.Key))
            drawText(x + w - 10, curY, kStr, Theme.TextDark, 11, false, true, 1, 64)
            curY = curY + 22
        end
    end
end

-- Keybind Processing Loop
local function runKeybinds()
    if not iskeypressed then return end
    for _, kb in pairs(Maclib.Keybinds) do
        if kb.Key and kb.Key ~= 0 then
            local isDown = iskeypressed(kb.Key)
            if kb.Mode == "Toggle" then
                if isDown and not kb.WasDown then
                    kb.Active = not kb.Active
                    if kb.ToggleObj then kb.ToggleObj:SetValue(kb.Active) end
                end
            elseif kb.Mode == "Hold" then
                kb.Active = isDown
                if kb.ToggleObj then kb.ToggleObj:SetValue(kb.Active) end
            elseif kb.Mode == "Always" then
                kb.Active = true
                if kb.ToggleObj and not kb.ToggleObj.Value then kb.ToggleObj:SetValue(true) end
            end
            kb.WasDown = isDown
        end
    end
end

-- Interactive Color Picker Modal
local function drawActiveColorPicker()
    local cp = Maclib.ActiveColorPicker
    if not cp then return end

    local w, h = 180, 160
    local x, y = cp.X or 400, cp.Y or 300

    -- Background
    drawRect(x, y, w, h, Theme.WindowBg, true, 1, 90)
    drawRect(x, y, w, h, Theme.Border, false, 1, 91)
    drawLine(x, y, x + w, y, Theme.Accent, 2, 1, 92)
    drawText(x + 10, y + 8, cp.Name or "Color Picker", Theme.Text, 12, false, true, 1, 93)

    -- Current Color Preview Box
    drawRect(x + w - 34, y + 6, 24, 16, cp.Value, true, 1, 93)
    drawRect(x + w - 34, y + 6, 24, 16, Theme.Border, false, 1, 94)

    -- RGB Sliders
    local channels = {
        { Name = "R", Val = math.floor(cp.Value.R * 255), Col = Color3.fromRGB(255, 80, 80) },
        { Name = "G", Val = math.floor(cp.Value.G * 255), Col = Color3.fromRGB(80, 255, 80) },
        { Name = "B", Val = math.floor(cp.Value.B * 255), Col = Color3.fromRGB(80, 120, 255) }
    }

    local sliderY = y + 34
    for idx, ch in ipairs(channels) do
        drawText(x + 12, sliderY, ch.Name, ch.Col, 11, false, true, 1, 93)
        drawText(x + w - 12, sliderY, tostring(ch.Val), Theme.TextDim, 11, false, true, 1, 93)

        local barX = x + 30
        local barW = w - 65
        local barY = sliderY + 12
        local ratio = ch.Val / 255

        drawRect(barX, barY, barW, 4, Theme.ValueBox, true, 1, 93)
        drawRect(barX, barY, barW * ratio, 4, ch.Col, true, 1, 94)
        drawCircle(barX + (barW * ratio), barY + 2, 4, Theme.Text, true, 95)

        if Input.Mouse1Down and isHovering(barX - 4, barY - 6, barW + 8, 16) then
            local newRatio = math.clamp((Input.MousePos.X - barX) / barW, 0, 1)
            local r, g, b = cp.Value.R, cp.Value.G, cp.Value.B
            if idx == 1 then r = newRatio
            elseif idx == 2 then g = newRatio
            elseif idx == 3 then b = newRatio end
            cp:SetValue(Color3.new(r, g, b))
        end

        sliderY = sliderY + 26
    end

    -- Close Button
    local btnY = sliderY + 8
    local hoverClose = isHovering(x + 12, btnY, w - 24, 22)
    drawRect(x + 12, btnY, w - 24, 22, hoverClose and Theme.ActiveTab or Theme.CardBg, true, 1, 93)
    drawRect(x + 12, btnY, w - 24, 22, Theme.Border, false, 1, 94)
    drawText(x + (w / 2), btnY + 4, "Close", Theme.Text, 11, true, true, 1, 95)

    if hoverClose and Input.Mouse1Clicked then
        Maclib.ActiveColorPicker = nil
    end

    if Input.Mouse1Clicked and not isHovering(x, y, w, h) and not isHovering(x - 30, y - 30, w + 60, h + 60) then
        Maclib.ActiveColorPicker = nil
    end
end

-- =========================================================================
-- NOTIFICATION SYSTEM
-- =========================================================================
local Notifications = {}
function Maclib:Notify(config)
    local n = {
        Title = config.Title or "Notification",
        Description = config.Description or "",
        Duration = config.Duration or 3,
        TimeCreated = tick(),
        Fade = 0
    }
    table.insert(Notifications, n)
end

local function renderNotifications()
    local curY = 40
    local i = 1
    while i <= #Notifications do
        local n = Notifications[i]
        local elapsed = tick() - n.TimeCreated
        if elapsed > n.Duration then
            table.remove(Notifications, i)
        else
            n.Fade = Approach(n.Fade, 1, 15)
            local w = 240
            local h = 50
            local x = 1920 - w - 24
            local y = curY

            drawRect(x, y, w, h, Theme.WindowBg, true, 0.95 * n.Fade, 100)
            drawRect(x, y, w, h, Theme.Border, false, n.Fade, 101)
            drawLine(x, y, x + w, y, Theme.Accent, 2, n.Fade, 102)
            drawText(x + 12, y + 8, n.Title, Theme.Text, 12, false, true, n.Fade, 103)
            drawText(x + 12, y + 24, n.Description, Theme.TextDim, 11, false, true, n.Fade, 103)

            curY = curY + h + 10
            i = i + 1
        end
    end
end

-- =========================================================================
-- CORE WINDOW FACTORY
-- =========================================================================
function Maclib:Window(winConfig)
    local win = {
        Title = winConfig.Title or "Maclib",
        Subtitle = winConfig.Subtitle or "Universal",
        Username = (LocalPlayer and LocalPlayer.Name) or winConfig.Username or "Player",
        UserHandle = (LocalPlayer and ("@" .. LocalPlayer.Name)) or winConfig.UserHandle or "@Player",
        ToggleKey = winConfig.ToggleKey or 0x2D,
        Width = winConfig.Width or 840,
        Height = winConfig.Height or 580,
        X = 250,
        Y = 150,
        ActiveTabIndex = 1,
        Tabs = {},
        Active = true,
        Dragging = false,
        DragOffset = Vector2.new(0, 0),
        AvatarData = nil
    }

    _G.MaclibInstance = win

    -- Fetch Avatar Asynchronously
    task.spawn(function()
        pcall(function()
            if LocalPlayer and LocalPlayer.UserId then
                local url = string.format("https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=%d&size=150x150&format=Png&isCircular=true", LocalPlayer.UserId)
                local resp = game:HttpGet(url)
                local data = HttpService:JSONDecode(resp)
                if data and data.data and data.data[1] and data.data[1].imageUrl then
                    local imgUrl = data.data[1].imageUrl
                    local imgBytes = game:HttpGet(imgUrl)
                    if imgBytes and #imgBytes > 0 then
                        win.AvatarData = imgBytes
                    end
                end
            end
        end)
    end)

    function win:Destroy()
        win.Active = false
        cleanupAllDrawings()
    end

    -- Tab Builder
    function win:Tab(tConfig)
        local tabName = tConfig.Name or "Tab"
        local tabObj = {
            Name = tabName,
            Sections = {},
            HoverAlpha = 0
        }

        function tabObj:Section(sConfig)
            local secName = sConfig.Name or "Section"
            local secSide = sConfig.Side or "Left"
            local secObj = {
                Name = secName,
                Side = secSide,
                Elements = {}
            }

            -- 1. Toggle
            function secObj:Toggle(tConfig)
                local id = tConfig.Id or (tabName .. "_" .. secName .. "_" .. (tConfig.Name or "Toggle"))
                local label = tConfig.Name or "Toggle"
                local def = tConfig.Default or false
                local callback = tConfig.Callback or function() end

                local toggleObj = {
                    Id = id,
                    Name = label,
                    Type = "Toggle",
                    Value = def,
                    TogglePos = def and 1 or 0,
                    SubElements = {},
                    Callback = callback
                }

                Maclib.Flags[id] = def
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
                    local kbId = kbConfig.Id or (id .. "_Key")
                    local kbObj = {
                        Id = kbId,
                        Name = label,
                        Type = "Keybind",
                        Key = kbConfig.Default or 0,
                        Mode = kbConfig.Mode or "Toggle",
                        Active = def,
                        Listening = false,
                        ToggleObj = toggleObj,
                        Callback = kbConfig.Callback
                    }
                    Maclib.Keybinds[kbId] = kbObj
                    table.insert(toggleObj.SubElements, kbObj)
                    return kbObj
                end

                function toggleObj:Colorpicker(cpConfig)
                    local cpId = cpConfig.Id or (id .. "_Color")
                    local cpObj = {
                        Id = cpId,
                        Name = label,
                        Type = "Colorpicker",
                        Value = cpConfig.Default or Color3.fromRGB(122, 134, 255),
                        Alpha = cpConfig.Alpha or 1,
                        Callback = cpConfig.Callback or function() end
                    }
                    function cpObj:SetValue(val)
                        cpObj.Value = val
                        Maclib.Colors[cpId] = val
                        if cpObj.Callback then cpObj.Callback(val) end
                    end
                    Maclib.Colors[cpId] = cpObj.Value
                    table.insert(toggleObj.SubElements, cpObj)
                    return cpObj
                end

                table.insert(secObj.Elements, toggleObj)
                return toggleObj
            end

            -- 2. Standalone Colorpicker
            function secObj:Colorpicker(cpConfig)
                local id = cpConfig.Id or (tabName .. "_" .. secName .. "_" .. (cpConfig.Name or "Colorpicker"))
                local label = cpConfig.Name or "Colorpicker"
                local def = cpConfig.Default or Color3.fromRGB(122, 134, 255)
                local callback = cpConfig.Callback or function() end

                local cpObj = {
                    Id = id,
                    Name = label,
                    Type = "Colorpicker",
                    Value = def,
                    Alpha = cpConfig.Alpha or 1,
                    Callback = callback
                }

                function cpObj:SetValue(val)
                    cpObj.Value = val
                    Maclib.Colors[id] = val
                    callback(val)
                end

                Maclib.Colors[id] = def
                Maclib.Elements[id] = cpObj
                table.insert(secObj.Elements, cpObj)
                return cpObj
            end

            -- 3. Slider
            function secObj:Slider(sConfig)
                local id = sConfig.Id or (tabName .. "_" .. secName .. "_" .. (sConfig.Name or "Slider"))
                local label = sConfig.Name or "Slider"
                local min = sConfig.Min or 0
                local max = sConfig.Max or 100
                local def = sConfig.Default or min
                local suffix = sConfig.Suffix or ""
                local callback = sConfig.Callback or function() end

                local sliderObj = {
                    Id = id,
                    Name = label,
                    Type = "Slider",
                    Min = min,
                    Max = max,
                    Value = def,
                    SliderAnim = (def - min) / (max - min),
                    Suffix = suffix,
                    Dragging = false,
                    Callback = callback
                }

                Maclib.Flags[id] = def
                Maclib.Elements[id] = sliderObj

                function sliderObj:SetValue(val)
                    val = math.clamp(val, min, max)
                    sliderObj.Value = val
                    Maclib.Flags[id] = val
                    callback(val)
                end

                table.insert(secObj.Elements, sliderObj)
                return sliderObj
            end

            -- 4. RangeSlider
            function secObj:RangeSlider(rConfig)
                local id = rConfig.Id or (tabName .. "_" .. secName .. "_" .. (rConfig.Name or "RangeSlider"))
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

            -- 5. Dropdown
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

                table.insert(secObj.Elements, dropObj)
                return dropObj
            end

            -- 6. Button
            function secObj:Button(bConfig)
                local label = bConfig.Name or "Button"
                local callback = bConfig.Callback or function() end
                local btnObj = { Name = label, Type = "Button", Callback = callback }
                table.insert(secObj.Elements, btnObj)
                return btnObj
            end

            -- 7. Input
            function secObj:Input(iConfig)
                local id = iConfig.Id or (tabName .. "_" .. secName .. "_" .. (iConfig.Name or "Input"))
                local label = iConfig.Name or "Input"
                local def = iConfig.Default or ""
                local callback = iConfig.Callback or function() end

                local inputObj = {
                    Id = id,
                    Name = label,
                    Type = "Input",
                    Value = def,
                    Focused = false,
                    Callback = callback
                }

                Maclib.Flags[id] = def
                Maclib.Elements[id] = inputObj

                function inputObj:SetValue(val)
                    inputObj.Value = val
                    Maclib.Flags[id] = val
                    callback(val)
                end

                table.insert(secObj.Elements, inputObj)
                return inputObj
            end

            table.insert(tabObj.Sections, secObj)
            return secObj
        end

        table.insert(win.Tabs, tabObj)
        return tabObj
    end

    -- Config Section Preset
    function win:BuildConfigSection(targetTab, targetSide)
        local sec = targetTab:Section({ Name = "Configuration", Side = targetSide or "Right" })
        sec:Button({
            Name = "Save Config",
            Callback = function() Maclib:Notify({ Title = "Config", Description = "Configuration Saved!" }) end
        })
        sec:Button({
            Name = "Load Config",
            Callback = function() Maclib:Notify({ Title = "Config", Description = "Configuration Loaded!" }) end
        })
        return sec
    end

    -- =========================================================================
    -- MAIN HEARTBEAT RENDER LOOP
    -- =========================================================================
    local connection
    local lastTick = tick()
    local frameCount = 0
    local fpsTimer = tick()

    connection = RunService.Heartbeat:Connect(function()
        local currentTick = tick()
        Maclib.Delta = math.min(currentTick - lastTick, 1/15)
        lastTick = currentTick

        frameCount = frameCount + 1
        if currentTick - fpsTimer >= 0.5 then
            Maclib.FPS = frameCount / (currentTick - fpsTimer)
            frameCount = 0
            fpsTimer = currentTick
        end

        if not win.Active then
            connection:Disconnect()
            cleanupAllDrawings()
            return
        end

        updateInput()
        runKeybinds()
        beginFrame()

        -- Render Ambient Effects & Overlays (Always live)
        drawBackgroundFX()
        drawWatermark(win)
        drawHotkeyOverlay()
        renderNotifications()

        -- Menu Open / Close Toggle
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

        if Input.Mouse1Clicked and isHovering(wx + 16, wy + 14, 14, 14) then
            win:Destroy()
            endFrame()
            return
        end
        if Input.Mouse1Clicked and isHovering(wx + 32, wy + 14, 14, 14) then
            Maclib.Open = false
        end

        -- 3. Sidebar Divider & Geometric Logo
        local sidebarW = 210
        drawLine(wx + sidebarW, wy, wx + sidebarW, wy + wh, Theme.Border, 1, 1, 12)

        local logoX, logoY = wx + 30, wy + 54
        drawLine(logoX, logoY - 8, logoX + 8, logoY, Theme.Accent, 2, 1, 20)
        drawLine(logoX + 8, logoY, logoX, logoY + 8, Theme.Accent, 2, 1, 20)
        drawLine(logoX, logoY + 8, logoX - 8, logoY, Theme.Accent, 2, 1, 20)
        drawLine(logoX - 8, logoY, logoX, logoY - 8, Theme.Accent, 2, 1, 20)
        drawCircle(logoX, logoY, 2.5, Theme.Text, true, 21)

        drawText(wx + 46, wy + 46, win.Title, Theme.Text, 14, false, true, 1, 20)
        drawText(wx + 46, wy + 62, win.Subtitle, Theme.TextDark, 11, false, true, 1, 20)

        -- 4. Sidebar Tabs
        local tabStartY = wy + 96
        for idx, tab in ipairs(win.Tabs) do
            local isSelected = (idx == win.ActiveTabIndex)
            local itemY = tabStartY + ((idx - 1) * 40)
            local hover = isHovering(wx + 16, itemY, sidebarW - 32, 34)

            tab.HoverAlpha = Approach(tab.HoverAlpha or 0, hover and 1 or 0, 15)

            if isSelected then
                drawRect(wx + 16, itemY, sidebarW - 32, 34, Theme.ActiveTab, true, 1, 15)
                drawRect(wx + 16, itemY, sidebarW - 32, 34, Theme.Border, false, 1, 16)
                drawIcon(tab.Name, wx + 30, itemY + 17, 14, Theme.Text, 22)
                drawText(wx + 44, itemY + 9, tab.Name, Theme.Text, 13, false, true, 1, 22)
            else
                if tab.HoverAlpha > 0.01 then
                    drawRect(wx + 16, itemY, sidebarW - 32, 34, Blend(Theme.SidebarBg, Theme.CardBg, tab.HoverAlpha), true, 1, 14)
                end
                local iconCol = Blend(Theme.TextDark, Theme.Text, tab.HoverAlpha)
                local textCol = Blend(Theme.TextDim, Theme.Text, tab.HoverAlpha)
                drawIcon(tab.Name, wx + 30, itemY + 17, 14, iconCol, 20)
                drawText(wx + 44, itemY + 9, tab.Name, textCol, 13, false, true, 1, 20)
            end

            if hover and Input.Mouse1Clicked then
                win.ActiveTabIndex = idx
                Maclib.DropdownContext = nil
            end
        end

        -- 5. User Profile Footer
        local profileY = wy + wh - 64
        drawLine(wx, profileY, wx + sidebarW, profileY, Theme.Border, 1, 1, 12)

        local avatarDrawn = false
        if win.AvatarData then
            local img = drawImage(wx + 20, profileY + 12, 30, 30, win.AvatarData, 1, 20)
            if img then avatarDrawn = true end
        end

        if not avatarDrawn then
            drawCircle(wx + 35, profileY + 27, 14, Theme.CardBg, true, 18)
            drawCircle(wx + 35, profileY + 27, 14, Theme.Border, false, 19)
            local initial = string.sub(win.Username, 1, 1):upper()
            drawText(wx + 35, profileY + 20, initial, Theme.Text, 13, true, true, 1, 20)
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

            local cardTopY = contentY + 26
            local leftY = cardTopY
            local rightY = cardTopY

            for _, sec in ipairs(activeTab.Sections) do
                local isLeft = (sec.Side == "Left")
                local secX = isLeft and contentX or (contentX + colW + 16)
                local curY = isLeft and leftY or rightY

                local secHeight = 16
                for _, el in ipairs(sec.Elements) do
                    if el.Type == "Toggle" or el.Type == "Colorpicker" then secHeight = secHeight + 36
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

                        if (hover or isHovering(secX + 16, itemY, colW - 80, 28)) and Input.Mouse1Clicked then
                            el:SetValue(not el.Value)
                        end

                        -- Render Sub-Elements (Keybind & Colorpicker)
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
                            elseif sub.Type == "Colorpicker" then
                                extraOffset = extraOffset - 26
                                local cHover = isHovering(extraOffset, itemY + 3, 20, 20)
                                drawRect(extraOffset, itemY + 3, 20, 20, sub.Value, true, 1, 24)
                                drawRect(extraOffset, itemY + 3, 20, 20, cHover and Theme.Text or Theme.Border, false, 1, 25)

                                if cHover and Input.Mouse1Clicked then
                                    sub.X = extraOffset - 180
                                    sub.Y = itemY
                                    Maclib.ActiveColorPicker = sub
                                end
                            end
                        end

                        itemY = itemY + 36

                    elseif el.Type == "Colorpicker" then
                        drawText(secX + 16, itemY + 5, el.Name, Theme.TextDim, 12, false, true, 1, 20)
                        local swX = secX + colW - 16 - 28
                        local swY = itemY + 3
                        local cHover = isHovering(swX, swY, 28, 20)

                        drawRect(swX, swY, 28, 20, el.Value, true, 1, 22)
                        drawRect(swX, swY, 28, 20, cHover and Theme.Text or Theme.Border, false, 1, 23)

                        if cHover and Input.Mouse1Clicked then
                            el.X = swX - 180
                            el.Y = swY
                            Maclib.ActiveColorPicker = el
                        end

                        itemY = itemY + 36

                    elseif el.Type == "Slider" then
                        drawText(secX + 16, itemY + 5, el.Name, Theme.TextDim, 12, false, true, 1, 20)

                        local valStr = tostring(el.Value) .. (el.Suffix or "")
                        local badgeW = (#valStr * 7) + 14
                        local badgeH = 20
                        local badgeX = secX + colW - 16 - badgeW
                        local badgeY = itemY + 2
                        drawRect(badgeX, badgeY, badgeW, badgeH, Theme.ValueBox, true, 1, 20)
                        drawRect(badgeX, badgeY, badgeW, badgeH, Theme.Border, false, 1, 21)
                        drawText(badgeX + (badgeW / 2), badgeY + 4, valStr, Theme.Text, 11, true, true, 1, 22)

                        local barW = colW - 32
                        local barX = secX + 16
                        local barY = itemY + 28
                        local hoverBar = isHovering(barX, barY - 4, barW, 12)
                        local ratio = (el.Value - el.Min) / (el.Max - el.Min)

                        el.SliderAnim = Approach(el.SliderAnim or ratio, ratio, 20)
                        local fillWidth = math.floor(el.SliderAnim * barW)

                        drawRect(barX, barY, barW, 4, Theme.ValueBox, true, 1, 22)
                        drawRect(barX, barY, fillWidth, 4, Theme.Accent, true, 1, 23)
                        drawCircle(barX + fillWidth, barY + 2, 5, Theme.Text, true, 25)

                        if Input.Mouse1Down and (hoverBar or el.Dragging) then
                            el.Dragging = true
                            local newRatio = math.clamp((Input.MousePos.X - barX) / barW, 0, 1)
                            local newVal = math.floor(el.Min + ((el.Max - el.Min) * newRatio) + 0.5)
                            el:SetValue(newVal)
                        else
                            el.Dragging = false
                        end

                        itemY = itemY + 36

                    elseif el.Type == "Dropdown" then
                        drawText(secX + 16, itemY + 7, el.Name, Theme.TextDim, 12, false, true, 1, 20)

                        local dropW = 140
                        local dropH = 22
                        local dropX = secX + colW - 16 - dropW
                        local dropY = itemY + 4
                        local hoverDrop = isHovering(dropX, dropY, dropW, dropH)

                        local text = tostring(el.Value or "Select...")
                        drawRect(dropX, dropY, dropW, dropH, Theme.ValueBox, true, 1, 22)
                        drawRect(dropX, dropY, dropW, dropH, hoverDrop and Theme.Border or Theme.BorderSubtle, false, 1, 23)
                        drawText(dropX + 10, dropY + 4, text, Theme.Text, 11, false, true, 1, 24)
                        drawText(dropX + dropW - 14, dropY + 4, "v", Theme.TextDark, 10, false, true, 1, 24)

                        if hoverDrop and Input.Mouse1Clicked then
                            if Maclib.DropdownContext == el then
                                Maclib.DropdownContext = nil
                            else
                                Maclib.DropdownContext = el
                                el.DropX = dropX
                                el.DropY = dropY + dropH + 2
                                el.DropW = dropW
                            end
                        end

                        itemY = itemY + 38

                    elseif el.Type == "Button" then
                        local btnW = colW - 32
                        local btnH = 26
                        local btnX = secX + 16
                        local btnY = itemY + 4
                        local hoverBtn = isHovering(btnX, btnY, btnW, btnH)

                        drawRect(btnX, btnY, btnW, btnH, hoverBtn and Theme.ActiveTab or Theme.ValueBox, true, 1, 20)
                        drawRect(btnX, btnY, btnW, btnH, hoverBtn and Theme.Border or Theme.BorderSubtle, false, 1, 21)
                        drawText(btnX + (btnW / 2), btnY + 6, el.Name, Theme.Text, 12, true, true, 1, 22)

                        if hoverBtn and Input.Mouse1Clicked then
                            pcall(el.Callback)
                        end

                        itemY = itemY + 36

                    elseif el.Type == "Input" then
                        drawText(secX + 16, itemY + 5, el.Name, Theme.TextDim, 12, false, true, 1, 20)

                        local inW = 120
                        local inH = 22
                        local inX = secX + colW - 16 - inW
                        local inY = itemY + 2
                        local hoverIn = isHovering(inX, inY, inW, inH)

                        drawRect(inX, inY, inW, inH, Theme.ValueBox, true, 1, 20)
                        drawRect(inX, inY, inW, inH, el.Focused and Theme.Accent or Theme.Border, false, 1, 21)
                        drawText(inX + 8, inY + 4, el.Value ~= "" and el.Value or "Type...", el.Value ~= "" and Theme.Text or Theme.TextDark, 11, false, true, 1, 22)

                        if hoverIn and Input.Mouse1Clicked then
                            el.Focused = not el.Focused
                        end

                        itemY = itemY + 36
                    end
                end

                if isLeft then
                    leftY = leftY + secHeight + 14
                else
                    rightY = rightY + secHeight + 14
                end
            end
        end

        -- 7. Floating Dropdown Context Menu
        if Maclib.DropdownContext then
            local el = Maclib.DropdownContext
            local dx = el.DropX or (wx + 300)
            local dy = el.DropY or (wy + 200)
            local dw = el.DropW or 140
            local dh = (#el.Options * 22) + 4

            drawRect(dx, dy, dw, dh, Theme.WindowBg, true, 1, 70)
            drawRect(dx, dy, dw, dh, Theme.Border, false, 1, 71)

            for oIdx, opt in ipairs(el.Options) do
                local optY = dy + 2 + ((oIdx - 1) * 22)
                local hoverOpt = isHovering(dx, optY, dw, 22)
                local isSel = (el.Value == opt)

                if hoverOpt or isSel then
                    drawRect(dx + 2, optY, dw - 4, 20, isSel and Theme.ActiveTab or Theme.CardBg, true, 1, 72)
                end

                drawText(dx + 10, optY + 3, tostring(opt), isSel and Theme.Accent or Theme.Text, 11, false, true, 1, 73)

                if hoverOpt and Input.Mouse1Clicked then
                    el:SetValue(opt)
                    Maclib.DropdownContext = nil
                    break
                end
            end

            if Input.Mouse1Clicked and not isHovering(dx, dy, dw, dh) and not isHovering(dx, dy - 30, dw, 30) then
                Maclib.DropdownContext = nil
            end
        end

        -- 8. Active Interactive Color Picker
        drawActiveColorPicker()

        endFrame()
    end)

    return win
end

return Maclib
