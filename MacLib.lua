-- Maclib UI Library for Matcha
-- Author: a256

local Maclib = {
    Version = "1.0.0",
    Flags = {},
    Elements = {},
    Windows = {},
    ConfigFolder = "MaclibConfigs"
}

local function parseKey(key)
    if key == nil then return 0 end
    return key
end

-- =========================================================================
-- PURE LUA JSON SERIALIZER
-- =========================================================================
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
            for i = 1, n do
                table.insert(items, jsonEncode(val[i]))
            end
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
            if c == " " or c == "\t" or c == "\n" or c == "\r" then
                pos = pos + 1
            else
                break
            end
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
                res = res:gsub('\\"', '"'):gsub('\\\\', '\\')
                return res
            end
            pos = pos + 1
        end
        return ""
    end

    local function parseNumber()
        local start = pos
        while pos <= len do
            local c = str:sub(pos, pos)
            if c:match("[%d%.%-%+eE]") then
                pos = pos + 1
            else
                break
            end
        end
        return tonumber(str:sub(start, pos - 1))
    end

    local function parseArray()
        pos = pos + 1
        local arr = {}
        skipWhitespace()
        if str:sub(pos, pos) == "]" then
            pos = pos + 1
            return arr
        end
        while pos <= len do
            local val = parseValue()
            table.insert(arr, val)
            skipWhitespace()
            local c = str:sub(pos, pos)
            if c == "," then
                pos = pos + 1
            elseif c == "]" then
                pos = pos + 1
                return arr
            else
                break
            end
        end
        return arr
    end

    local function parseObject()
        pos = pos + 1
        local obj = {}
        skipWhitespace()
        if str:sub(pos, pos) == "}" then
            pos = pos + 1
            return obj
        end
        while pos <= len do
            skipWhitespace()
            if str:sub(pos, pos) == '"' then
                local key = parseString()
                skipWhitespace()
                if str:sub(pos, pos) == ":" then
                    pos = pos + 1
                    local val = parseValue()
                    obj[key] = val
                end
            end
            skipWhitespace()
            local c = str:sub(pos, pos)
            if c == "," then
                pos = pos + 1
            elseif c == "}" then
                pos = pos + 1
                return obj
            else
                break
            end
        end
        return obj
    end

    parseValue = function()
        skipWhitespace()
        local c = str:sub(pos, pos)
        if c == '"' then
            return parseString()
        elseif c == "{" then
            return parseObject()
        elseif c == "[" then
            return parseArray()
        elseif c == "t" and str:sub(pos, pos + 3) == "true" then
            pos = pos + 4
            return true
        elseif c == "f" and str:sub(pos, pos + 4) == "false" then
            pos = pos + 5
            return false
        elseif c == "n" and str:sub(pos, pos + 3) == "null" then
            pos = pos + 4
            return nil
        else
            return parseNumber()
        end
    end

    local ok, res = pcall(parseValue)
    if ok then return res else return nil end
end

function Maclib:Notify(options)
    local title = options.Title or "Maclib"
    local description = options.Description or options.Content or ""
    local duration = options.Lifetime or options.Duration or 3
    if notify then
        notify(description, title, duration)
    else
        print(string.format("[%s] %s", title, description))
    end
end

-- =========================================================================
-- CONFIG & SETTINGS MANAGER
-- =========================================================================

function Maclib:PackConfig(window)
    local data = {
        Version = self.Version,
        SavedAt = tick(),
        Flags = {},
        Colors = {}
    }

    for id, el in pairs(self.Elements) do
        if el.Type == "Toggle" or el.Type == "Slider" or el.Type == "Input" or el.Type == "Dropdown" then
            local val = el:GetValue()
            data.Flags[id] = val
        end
    end

    for flagId, val in pairs(self.Flags) do
        if data.Flags[flagId] == nil then
            if type(val) == "number" or type(val) == "string" or type(val) == "boolean" or type(val) == "table" then
                data.Flags[flagId] = val
            elseif typeof(val) == "Color3" then
                data.Colors[flagId] = { val.R, val.G, val.B }
            end
        end
    end

    return data
end

function Maclib:ApplyConfig(window, data)
    if not data or not data.Flags then return false end

    for flagId, val in pairs(data.Flags) do
        self.Flags[flagId] = val
        UI.SetValue(flagId, val)
        local el = self.Elements[flagId]
        if el and el.Callback then
            pcall(function() el.Callback(val) end)
        end
    end

    if data.Colors then
        for colId, colData in pairs(data.Colors) do
            if type(colData) == "table" and #colData >= 3 then
                local col = Color3.new(colData[1], colData[2], colData[3])
                self.Flags[colId] = col
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
    self:Notify({
        Title = "Config Saved",
        Description = "Saved " .. configName,
        Lifetime = 3
    })
    return true
end

function Maclib:LoadConfig(window, configName)
    if not configName or configName == "" then return false end
    local folder = window.ConfigFolder or self.ConfigFolder
    local path = folder .. "/" .. configName .. ".json"

    if not isfile(path) then
        self:Notify({
            Title = "Config Error",
            Description = "File not found: " .. configName,
            Lifetime = 3
        })
        return false
    end

    local raw = readfile(path)
    local data = jsonDecode(raw)
    if not data then return false end

    self:ApplyConfig(window, data)

    self:Notify({
        Title = "Config Loaded",
        Description = "Loaded " .. configName,
        Lifetime = 3
    })
    return true
end

function Maclib:DeleteConfig(window, configName)
    local folder = window.ConfigFolder or self.ConfigFolder
    local path = folder .. "/" .. configName .. ".json"
    if isfile(path) then
        delfile(path)
        self:Notify({
            Title = "Config Deleted",
            Description = "Deleted " .. configName,
            Lifetime = 3
        })
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
        if name and name ~= "autoload" then
            table.insert(configs, name)
        end
    end
    return configs
end

function Maclib:SetAutoload(window, configName)
    local folder = window.ConfigFolder or self.ConfigFolder
    if not isfolder(folder) then makefolder(folder) end
    writefile(folder .. "/autoload.json", jsonEncode({ Autoload = configName }))
    self:Notify({
        Title = "Autoload Set",
        Description = "Set autoload to " .. tostring(configName),
        Lifetime = 3
    })
end

function Maclib:GetAutoload(window)
    local folder = window.ConfigFolder or self.ConfigFolder
    local path = folder .. "/autoload.json"
    if isfile(path) then
        local raw = readfile(path)
        local data = jsonDecode(raw)
        if data and data.Autoload then
            return data.Autoload
        end
    end
    return nil
end

-- =========================================================================
-- WINDOW CLASS
-- =========================================================================

function Maclib:Window(config)
    config = config or {}
    local window = {
        Title = config.Title or "Maclib",
        Subtitle = config.Subtitle or "",
        ConfigFolder = config.ConfigFolder or Maclib.ConfigFolder,
        Watermark = config.Watermark or false,
        Active = true,
        Tabs = {}
    }

    if not isfolder(window.ConfigFolder) then
        makefolder(window.ConfigFolder)
    end

    if window.Watermark then
        local watermarkBg = Drawing.new("Square")
        watermarkBg.Filled = true
        watermarkBg.Color = Color3.fromRGB(15, 15, 15)
        watermarkBg.Transparency = 0.85
        watermarkBg.Visible = true
        watermarkBg.Position = Vector2.new(16, 16)
        watermarkBg.Size = Vector2.new(220, 24)
        watermarkBg.ZIndex = 100

        local watermarkText = Drawing.new("Text")
        watermarkText.Color = Color3.fromRGB(240, 240, 240)
        watermarkText.Font = Drawing.Fonts.System or 1
        watermarkText.Size = 13
        watermarkText.Outline = true
        watermarkText.Visible = true
        watermarkText.Position = Vector2.new(22, 20)
        watermarkText.ZIndex = 101

        task.spawn(function()
            local fps = 60
            local lastTick = tick()
            local frames = 0
            while window.Active do
                frames = frames + 1
                local curTick = tick()
                if curTick - lastTick >= 1.0 then
                    fps = frames / (curTick - lastTick)
                    frames = 0
                    lastTick = curTick
                end

                local ping = GetPingValue and GetPingValue() or 0
                local exec = identifyexecutor and identifyexecutor() or "Matcha"
                local txt = string.format("%s | %s | %d FPS | %d ms", window.Title, exec, math.floor(fps), math.floor(ping))
                watermarkText.Text = txt
                watermarkBg.Size = Vector2.new(#txt * 7.2 + 16, 22)
                wait(0.25)
            end
            watermarkBg:Remove()
            watermarkText:Remove()
        end)
    end

    function window:Tab(tabConfig)
        tabConfig = tabConfig or {}
        local tabName = tabConfig.Name or ("Tab " .. tostring(#window.Tabs + 1))
        local tabObj = {
            Name = tabName,
            Sections = {},
            RenderQueue = {}
        }

        UI.AddTab(tabName, function(nativeTab)
            for _, renderFn in ipairs(tabObj.RenderQueue) do
                renderFn(nativeTab)
            end
        end)

        function tabObj:Section(secConfig)
            secConfig = secConfig or {}
            local secName = secConfig.Name or "Section"
            local side = secConfig.Side or "Left"
            local pages = secConfig.Pages or nil
            local maxHeight = secConfig.MaxHeight or nil

            local secObj = {
                Name = secName,
                Side = side,
                Pages = pages,
                Page = 0,
                Elements = {}
            }

            local function sectionRenderer(nativeTab)
                local nativeSec
                if pages and maxHeight then
                    nativeSec = nativeTab:Section(secName, side, pages, maxHeight)
                elseif pages then
                    nativeSec = nativeTab:Section(secName, side, pages)
                else
                    nativeSec = nativeTab:Section(secName, side)
                end

                secObj.Page = nativeSec.page or 0

                for _, el in ipairs(secObj.Elements) do
                    if el.Page == nil or el.Page == secObj.Page then
                        el.Render(nativeSec)
                    end
                end
            end

            table.insert(tabObj.RenderQueue, sectionRenderer)

            function secObj:Toggle(tConfig)
                local id = tConfig.Id or tConfig.Flag or (tabName .. "_" .. secName .. "_" .. (tConfig.Name or "Toggle"))
                local label = tConfig.Name or "Toggle"
                local default = tConfig.Default or false
                local callback = tConfig.Callback or function() end

                local toggleObj = {
                    Id = id,
                    Type = "Toggle",
                    Value = default,
                    Page = tConfig.Page,
                    Callback = callback,
                    SubElements = {}
                }

                Maclib.Flags[id] = default
                Maclib.Elements[id] = toggleObj

                toggleObj.Render = function(nativeSec)
                    local widget = nativeSec:Toggle(id, label, default, function(state)
                        toggleObj.Value = state
                        Maclib.Flags[id] = state
                        callback(state)
                    end)
                    toggleObj.Widget = widget
                    toggleObj.Value = widget.value

                    for _, sub in ipairs(toggleObj.SubElements) do
                        sub.Render(nativeSec)
                    end
                end

                function toggleObj:SetValue(val)
                    UI.SetValue(id, val)
                    toggleObj.Value = val
                    Maclib.Flags[id] = val
                end

                function toggleObj:GetValue()
                    return UI.GetValue(id)
                end

                function toggleObj:Keybind(kbConfig)
                    local kbId = kbConfig.Id or kbConfig.Flag or (id .. "_kb")
                    local key = parseKey(kbConfig.Default)
                    local mode = (kbConfig.Mode or "hold"):lower()
                    local label = kbConfig.HotkeyLabel or tConfig.Name

                    local kbObj = {
                        Id = kbId,
                        Type = "Keybind"
                    }

                    kbObj.Render = function(nativeSec)
                        local kbWidget = nativeSec:Keybind(kbId, key, mode)
                        kbObj.Widget = kbWidget
                        if kbConfig.HotkeyLabel then
                            kbWidget:AddToHotkey(label, id)
                        end
                    end

                    function kbObj:IsEnabled()
                        return kbObj.Widget and kbObj.Widget:IsEnabled() or false
                    end

                    function kbObj:SetKey(newKey)
                        if kbObj.Widget then kbObj.Widget:SetKey(parseKey(newKey)) end
                    end

                    function kbObj:SetType(newMode)
                        if kbObj.Widget then kbObj.Widget:SetType(newMode:lower()) end
                    end

                    table.insert(toggleObj.SubElements, kbObj)
                    return kbObj
                end

                function toggleObj:Colorpicker(cpConfig)
                    local cpId = cpConfig.Id or cpConfig.Flag or (id .. "_col")
                    local defCol = cpConfig.Default or Color3.fromRGB(255, 255, 255)
                    local defAlpha = cpConfig.Alpha or 1.0
                    local cb = cpConfig.Callback or function() end

                    local cpObj = {
                        Id = cpId,
                        Type = "ColorPicker",
                        Color = defCol,
                        Alpha = defAlpha
                    }

                    Maclib.Flags[cpId] = defCol

                    cpObj.Render = function(nativeSec)
                        local w = nativeSec:ColorPicker(cpId, defCol.R, defCol.G, defCol.B, defAlpha, function(c, a)
                            cpObj.Color = c
                            cpObj.Alpha = a
                            Maclib.Flags[cpId] = c
                            cb(c, a)
                        end)
                        cpObj.Widget = w
                    end

                    table.insert(toggleObj.SubElements, cpObj)
                    return cpObj
                end

                function toggleObj:Colorpicker2(cpConfig)
                    local id1 = cpConfig.Id1 or (id .. "_col1")
                    local id2 = cpConfig.Id2 or (id .. "_col2")
                    local col1 = cpConfig.Default1 or Color3.fromRGB(0, 255, 0)
                    local col2 = cpConfig.Default2 or Color3.fromRGB(255, 0, 0)
                    local a1 = cpConfig.Alpha1 or 1.0
                    local a2 = cpConfig.Alpha2 or 1.0
                    local cb = cpConfig.Callback or function() end

                    local cpObj = {
                        Type = "ColorPicker2",
                        Id1 = id1,
                        Id2 = id2
                    }

                    cpObj.Render = function(nativeSec)
                        nativeSec:ColorPicker2(id1, {col1.R, col1.G, col1.B, a1}, id2, {col2.R, col2.G, col2.B, a2}, function(c1, alpha1, c2, alpha2)
                            Maclib.Flags[id1] = c1
                            Maclib.Flags[id2] = c2
                            cb(c1, alpha1, c2, alpha2)
                        end)
                    end

                    table.insert(toggleObj.SubElements, cpObj)
                    return cpObj
                end

                table.insert(secObj.Elements, toggleObj)
                return toggleObj
            end

            function secObj:Slider(sConfig)
                local id = sConfig.Id or sConfig.Flag or (tabName .. "_" .. secName .. "_" .. (sConfig.Name or "Slider"))
                local label = sConfig.Name or "Slider"
                local min = sConfig.Min or 0
                local max = sConfig.Max or 100
                local default = sConfig.Default or min
                local isFloat = sConfig.IsFloat or (sConfig.Precision and sConfig.Precision > 0) or false
                local format = sConfig.Format or (isFloat and "%.1f" or "%d")
                local callback = sConfig.Callback or function() end

                local sliderObj = {
                    Id = id,
                    Type = "Slider",
                    Value = default,
                    Page = sConfig.Page,
                    Callback = callback
                }

                Maclib.Flags[id] = default
                Maclib.Elements[id] = sliderObj

                sliderObj.Render = function(nativeSec)
                    local w
                    if isFloat then
                        w = nativeSec:SliderFloat(id, label, min, max, default, format, function(val)
                            sliderObj.Value = val
                            Maclib.Flags[id] = val
                            callback(val)
                        end)
                    else
                        w = nativeSec:SliderInt(id, label, min, max, default, function(val)
                            sliderObj.Value = val
                            Maclib.Flags[id] = val
                            callback(val)
                        end)
                    end
                    sliderObj.Widget = w
                end

                function sliderObj:SetValue(val)
                    UI.SetValue(id, val)
                    sliderObj.Value = val
                    Maclib.Flags[id] = val
                end

                function sliderObj:GetValue()
                    return UI.GetValue(id)
                end

                table.insert(secObj.Elements, sliderObj)
                return sliderObj
            end

            function secObj:Dropdown(dConfig)
                local id = dConfig.Id or dConfig.Flag or (tabName .. "_" .. secName .. "_" .. (dConfig.Name or "Dropdown"))
                local label = dConfig.Name or "Dropdown"
                local options = dConfig.Options or {}
                local defaultIdx = 0

                if type(dConfig.Default) == "number" then
                    defaultIdx = math.max(0, dConfig.Default - 1)
                elseif type(dConfig.Default) == "string" then
                    for i, opt in ipairs(options) do
                        if opt == dConfig.Default then
                            defaultIdx = i - 1
                            break
                        end
                    end
                end

                local callback = dConfig.Callback or function() end

                local dropObj = {
                    Id = id,
                    Type = "Dropdown",
                    Options = options,
                    Value = options[defaultIdx + 1] or "",
                    Page = dConfig.Page,
                    Callback = callback
                }

                Maclib.Flags[id] = dropObj.Value
                Maclib.Elements[id] = dropObj

                dropObj.Render = function(nativeSec)
                    local w = nativeSec:Combo(id, label, options, defaultIdx, function(idx, text)
                        dropObj.Value = text
                        Maclib.Flags[id] = text
                        callback(text, idx)
                    end)
                    dropObj.Widget = w
                end

                function dropObj:Add(item)
                    if dropObj.Widget then dropObj.Widget:Add(item) end
                    table.insert(dropObj.Options, item)
                end

                function dropObj:Remove(item)
                    if dropObj.Widget then dropObj.Widget:Remove(item) end
                    for i, v in ipairs(dropObj.Options) do
                        if v == item then table.remove(dropObj.Options, i) break end
                    end
                end

                function dropObj:Clear()
                    if dropObj.Widget then dropObj.Widget:Clear() end
                    dropObj.Options = {}
                end

                function dropObj:GetItems()
                    return dropObj.Widget and dropObj.Widget:GetItems() or dropObj.Options
                end

                function dropObj:GetText()
                    return dropObj.Widget and dropObj.Widget:GetText() or dropObj.Value
                end

                function dropObj:GetValue()
                    return dropObj:GetText()
                end

                function dropObj:SetValue(index)
                    local zeroBased = type(index) == "number" and math.max(0, index - 1) or 0
                    if dropObj.Widget then dropObj.Widget:SetValue(zeroBased) end
                end

                table.insert(secObj.Elements, dropObj)
                return dropObj
            end

            function secObj:Input(iConfig)
                local id = iConfig.Id or iConfig.Flag or (tabName .. "_" .. secName .. "_" .. (iConfig.Name or "Input"))
                local label = iConfig.Name or "Input"
                local default = iConfig.Default or ""
                local callback = iConfig.Callback or function() end

                local inputObj = {
                    Id = id,
                    Type = "Input",
                    Value = default,
                    Page = iConfig.Page,
                    Callback = callback
                }

                Maclib.Flags[id] = default
                Maclib.Elements[id] = inputObj

                inputObj.Render = function(nativeSec)
                    local w = nativeSec:InputText(id, label, default, function(text)
                        inputObj.Value = text
                        Maclib.Flags[id] = text
                        callback(text)
                    end)
                    inputObj.Widget = w
                end

                function inputObj:SetValue(text)
                    UI.SetValue(id, text)
                    inputObj.Value = text
                    Maclib.Flags[id] = text
                end

                function inputObj:GetValue()
                    return UI.GetValue(id)
                end

                table.insert(secObj.Elements, inputObj)
                return inputObj
            end

            function secObj:Button(bConfig)
                local label = bConfig.Name or "Button"
                local callback = bConfig.Callback or function() end
                local width = bConfig.Width
                local height = bConfig.Height

                local btnObj = {
                    Type = "Button",
                    Page = bConfig.Page
                }

                btnObj.Render = function(nativeSec)
                    if width and height then
                        nativeSec:Button(label, width, height, callback)
                    else
                        nativeSec:Button(label, callback)
                    end
                end

                table.insert(secObj.Elements, btnObj)
                return btnObj
            end

            function secObj:Label(text, page)
                local labelObj = { Type = "Label", Page = page }
                labelObj.Render = function(nativeSec)
                    nativeSec:Text(text)
                end
                table.insert(secObj.Elements, labelObj)
                return labelObj
            end

            function secObj:Tip(text, page)
                local tipObj = { Type = "Tip", Page = page }
                tipObj.Render = function(nativeSec)
                    nativeSec:Tip(text)
                end
                table.insert(secObj.Elements, tipObj)
                return tipObj
            end

            function secObj:Divider(page)
                local divObj = { Type = "Divider", Page = page }
                divObj.Render = function(nativeSec)
                    nativeSec:Spacing()
                end
                table.insert(secObj.Elements, divObj)
                return divObj
            end

            table.insert(tabObj.Sections, secObj)
            return secObj
        end

        table.insert(window.Tabs, tabObj)
        return tabObj
    end

    function window:BuildConfigSection(targetTab, targetSide)
        local sec = targetTab:Section({
            Name = "Configuration",
            Side = targetSide or "Right"
        })

        local configInput = sec:Input({
            Name = "Config Name",
            Id = "cfg_name_input",
            Default = "default"
        })

        local configsList = Maclib:GetConfigs(window)
        if #configsList == 0 then table.insert(configsList, "None") end

        local configDropdown = sec:Dropdown({
            Name = "Select Config",
            Id = "cfg_select_drop",
            Options = configsList,
            Default = 1
        })

        sec:Button({
            Name = "Save Config",
            Callback = function()
                local name = configInput:GetValue()
                if name and name ~= "" then
                    Maclib:SaveConfig(window, name)
                    local refreshed = Maclib:GetConfigs(window)
                    configDropdown:Clear()
                    for _, c in ipairs(refreshed) do configDropdown:Add(c) end
                end
            end
        })

        sec:Button({
            Name = "Load Config",
            Callback = function()
                local selected = configDropdown:GetText()
                if selected and selected ~= "None" then
                    Maclib:LoadConfig(window, selected)
                end
            end
        })

        sec:Button({
            Name = "Set As Autoload",
            Callback = function()
                local selected = configDropdown:GetText()
                if selected and selected ~= "None" then
                    Maclib:SetAutoload(window, selected)
                end
            end
        })

        sec:Button({
            Name = "Delete Config",
            Callback = function()
                local selected = configDropdown:GetText()
                if selected and selected ~= "None" then
                    Maclib:DeleteConfig(window, selected)
                    local refreshed = Maclib:GetConfigs(window)
                    configDropdown:Clear()
                    if #refreshed == 0 then table.insert(refreshed, "None") end
                    for _, c in ipairs(refreshed) do configDropdown:Add(c) end
                end
            end
        })

        sec:Button({
            Name = "Refresh List",
            Callback = function()
                local refreshed = Maclib:GetConfigs(window)
                configDropdown:Clear()
                if #refreshed == 0 then table.insert(refreshed, "None") end
                for _, c in ipairs(refreshed) do configDropdown:Add(c) end
                Maclib:Notify({ Title = "Refreshed", Description = "Config list updated." })
            end
        })

        task.spawn(function()
            local auto = Maclib:GetAutoload(window)
            if auto then
                Maclib:LoadConfig(window, auto)
            end
        end)

        return sec
    end

    function window:Destroy()
        window.Active = false
        for _, tab in ipairs(window.Tabs) do
            UI.RemoveTab(tab.Name)
        end
        Maclib:Notify({ Title = "Maclib", Description = "Unloaded." })
    end

    table.insert(Maclib.Windows, window)
    return window
end

_G.Maclib = Maclib
return Maclib
