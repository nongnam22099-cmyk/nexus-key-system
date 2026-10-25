--[[
    ╔═══════════════════════════════════════════════════════════╗
    ║                     NEXUS HUB LOADER                      ║
    ║               Official Key System & License               ║
    ╚═══════════════════════════════════════════════════════════╝
]]

local API_URL = "http://localhost:3000" -- เปลี่ยนเป็น Domain/URL เซิร์ฟเวอร์จริงเมื่อนำขึ้นเว็บ
local SESSION_ID = HttpService:GenerateGUID(false)
local KEY_FILE = "nexus_key.txt"
local DISCORD_INVITE = "https://discord.gg/your-discord"

local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Get HWID safely across different executors
local function getClientHWID()
    if typeof(gethwid) == "function" then
        local ok, id = pcall(gethwid)
        if ok and id then return tostring(id) end
    end
    if typeof(get_hwid) == "function" then
        local ok, id = pcall(get_hwid)
        if ok and id then return tostring(id) end
    end
    local ok, clientId = pcall(function()
        return game:GetService("RbxAnalyticsService"):GetClientId()
    end)
    if ok and clientId then return tostring(clientId) end
    return tostring(LocalPlayer.UserId) .. "_DEVICE"
end

-- HTTP Request wrapper (compatible with all major executors)
local function sendHttpRequest(url, method, body)
    method = method or "GET"
    local requestFunc = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
    
    if requestFunc then
        local reqOptions = {
            Url = url,
            Method = method,
            Headers = {
                ["Content-Type"] = "application/json"
            }
        }
        if body then
            reqOptions.Body = HttpService:JSONEncode(body)
        end
        local ok, response = pcall(function()
            return requestFunc(reqOptions)
        end)
        if ok and response then
            local decoded = nil
            pcall(function() decoded = HttpService:JSONDecode(response.Body) end)
            return decoded or { success = false, message = response.Body }
        end
    else
        -- Fallback to HttpGet
        local ok, res = pcall(function()
            return game:HttpGet(url)
        end)
        if ok and res then
            local decoded = nil
            pcall(function() decoded = HttpService:JSONDecode(res) end)
            return decoded or { success = false, message = res }
        end
    end
    return { success = false, message = "ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ระบบคีย์ได้ (Cannot connect to Key API)" }
end

-- Load and execute the main Nexus Hub script
local function executeMainScript(key)
    -- Check local file first
    if typeof(readfile) == "function" and typeof(isfile) == "function" and isfile("nexus_hub.lua") then
        local fn, err = loadstring(readfile("nexus_hub.lua"))
        if fn then
            fn()
            return
        end
    end

    -- Download from Key Server API
    local hwid = getClientHWID()
    local username = LocalPlayer and LocalPlayer.Name or "Unknown"
    local userId = LocalPlayer and tostring(LocalPlayer.UserId) or "0"
    local fetchUrl = API_URL .. "/api/get-script?key=" .. HttpService:UrlEncode(key) .. "&hwid=" .. HttpService:UrlEncode(hwid) .. "&username=" .. HttpService:UrlEncode(username) .. "&userId=" .. HttpService:UrlEncode(userId)
        .. "&sessionId=" .. HttpService:UrlEncode(SESSION_ID)
    local ok, scriptContent = pcall(function()
        return game:HttpGet(fetchUrl)
    end)

    if ok and scriptContent then
        local fn, err = loadstring(scriptContent)
        if fn then
            fn()
        else
            warn("[Nexus Hub] Compile error:", err)
        end
    end
end

-- Background Heartbeat & Polling loop (Maintenance + Announcement + Active Player)
local function startHeartbeatLoop(validatedKey)
    task.spawn(function()
        local lastAnnouncementId = 0
        while task.wait(15) do
            local hwid = getClientHWID()
            local username = LocalPlayer and LocalPlayer.Name or "Unknown"
            local displayName = LocalPlayer and LocalPlayer.DisplayName or username
            local userId = LocalPlayer and tostring(LocalPlayer.UserId) or "0"
            local jobId = tostring(game.JobId or "SinglePlayer")

            local heartbeatUrl = API_URL .. "/api/heartbeat?key=" .. HttpService:UrlEncode(validatedKey or "")
                .. "&hwid=" .. HttpService:UrlEncode(hwid)
                .. "&username=" .. HttpService:UrlEncode(username)
                .. "&displayName=" .. HttpService:UrlEncode(displayName)
                .. "&userId=" .. HttpService:UrlEncode(userId)
                .. "&jobId=" .. HttpService:UrlEncode(jobId)
                .. "&sessionId=" .. HttpService:UrlEncode(SESSION_ID)

            local res = sendHttpRequest(heartbeatUrl, "GET")
            if res and typeof(res) == "table" then
                -- Check Screen Limit / Kicked by Admin
                if res.screenLimitExceeded or res.kicked then
                    pcall(function()
                        game:GetService("StarterGui"):SetCore("SendNotification", {
                            Title = "🚫 เกินจำนวนจอที่อนุญาต",
                            Text = res.reason or "คีย์นี้เปิดใช้งานเกินจำนวนจอที่กำหนด",
                            Duration = 10
                        })
                    end)
                    print("[Nexus Hub] Session disconnected: " .. tostring(res.reason))
                    return -- Stop heartbeat
                end

                -- Check Kill Switch / Maintenance
                if res.maintenance then
                    pcall(function()
                        game:GetService("StarterGui"):SetCore("SendNotification", {
                            Title = "⚠️ ปิดปรับปรุงฉุกเฉิน",
                            Text = res.maintenanceReason or "ระบบปิดปรับปรุงชั่วคราวเพื่อความปลอดภัย",
                            Duration = 8
                        })
                    end)
                end

                -- Check Blacklist
                if res.blacklisted then
                    pcall(function()
                        game:GetService("StarterGui"):SetCore("SendNotification", {
                            Title = "🚫 ถูกระงับสิทธิ์ถาวร",
                            Text = tostring(res.reason or "คุณถูกแบนจากการใช้งาน Nexus Hub"),
                            Duration = 10
                        })
                    end)
                end

                -- Check Remote Game Settings from Web Dashboard
                if res.gameSettings and typeof(res.gameSettings) == "table" then
                    getgenv().NexusSettings = res.gameSettings
                end

                -- Check Live In-Game Announcement
                if res.announcement and res.announcement.id and res.announcement.id ~= lastAnnouncementId then
                    lastAnnouncementId = res.announcement.id
                    pcall(function()
                        game:GetService("StarterGui"):SetCore("SendNotification", {
                            Title = "📢 " .. tostring(res.announcement.title or "ประกาศ"),
                            Text = tostring(res.announcement.message or ""),
                            Duration = 8
                        })
                    end)
                end
            end
        end
    end)
end

-- Verification function
local function verifyKey(key)
    local hwid = getClientHWID()
    local username = LocalPlayer and LocalPlayer.Name or "Unknown"
    local displayName = LocalPlayer and LocalPlayer.DisplayName or username
    local userId = LocalPlayer and tostring(LocalPlayer.UserId) or "0"

    local verifyUrl = API_URL .. "/api/verify?key=" .. HttpService:UrlEncode(key) 
        .. "&hwid=" .. HttpService:UrlEncode(hwid)
        .. "&username=" .. HttpService:UrlEncode(username)
        .. "&displayName=" .. HttpService:UrlEncode(displayName)
        .. "&userId=" .. HttpService:UrlEncode(userId)

    return sendHttpRequest(verifyUrl, "GET")
end

-- ==========================================
-- 1. Check getgenv().NexusKey or getgenv().Key
-- ==========================================
local globalKey = getgenv().NexusKey or getgenv().Key
if globalKey and type(globalKey) == "string" and #globalKey:gsub("%s+", "") > 3 then
    local cleanKey = globalKey:gsub("%s+", "")
    local res = verifyKey(cleanKey)
    if res and res.success then
        getgenv().NexusTier = res.tier or "VIP"
        print("[Nexus Hub] Key validated successfully from getgenv()! Tier: " .. tostring(getgenv().NexusTier))
        pcall(function()
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "Nexus Hub [" .. tostring(getgenv().NexusTier) .. "]",
                Text = "ยินดีต้อนรับ! ยืนยันคีย์สำเร็จ",
                Duration = 4
            })
        end)
        if typeof(writefile) == "function" then
            pcall(function() writefile(KEY_FILE, cleanKey) end)
        end
        startHeartbeatLoop(cleanKey)
        executeMainScript(cleanKey)
        return
    else
        warn("[Nexus Hub] Key Verification Failed: " .. tostring(res and res.message or "Invalid Key"))
        pcall(function()
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "Nexus Hub | Error",
                Text = tostring(res and res.message or "คีย์ไม่ถูกต้องหรือหมดอายุ"),
                Duration = 6
            })
        end)
    end
end

-- ==========================================
-- 2. Auto-Login check if key is saved locally
-- ==========================================
if typeof(isfile) == "function" and isfile(KEY_FILE) then
    local savedKey = readfile(KEY_FILE)
    if savedKey and #savedKey > 3 then
        local cleanSaved = savedKey:gsub("%s+", "")
        local res = verifyKey(cleanSaved)
        if res and res.success then
            getgenv().NexusTier = res.tier or "VIP"
            print("[Nexus Hub] Key validated automatically from saved file! Tier: " .. tostring(getgenv().NexusTier))
            startHeartbeatLoop(cleanSaved)
            executeMainScript(cleanSaved)
            return
        end
    end
end

-- ==========================================
-- Create Key System UI
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "NexusKeySystemUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

pcall(function()
    if gethui then
        ScreenGui.Parent = gethui()
    elseif syn and syn.protect_gui then
        syn.protect_gui(ScreenGui)
        ScreenGui.Parent = CoreGui
    else
        ScreenGui.Parent = CoreGui
    end
end)

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 420, 0, 270)
MainFrame.Position = UDim2.new(0.5, -210, 0.5, -135)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 20, 32)
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 14)
UICorner.Parent = MainFrame

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(0, 229, 255)
UIStroke.Thickness = 1.2
UIStroke.Transparency = 0.4
UIStroke.Parent = MainFrame

-- Top Accent Bar
local AccentBar = Instance.new("Frame")
AccentBar.Size = UDim2.new(1, 0, 0, 3)
AccentBar.BackgroundColor3 = Color3.fromRGB(0, 229, 255)
AccentBar.BorderSizePixel = 0
AccentBar.Parent = MainFrame

local AccentGradient = Instance.new("UIGradient")
AccentGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 229, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(121, 40, 202))
})
AccentGradient.Parent = AccentBar

-- Title
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Text = "NEXUS HUB | KEY SYSTEM"
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 16
TitleLabel.TextColor3 = Color3.fromRGB(0, 229, 255)
TitleLabel.Size = UDim2.new(1, -60, 0, 35)
TitleLabel.Position = UDim2.new(0, 18, 0, 10)
TitleLabel.BackgroundTransparency = 1
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = MainFrame

-- Subtitle
local SubtitleLabel = Instance.new("TextLabel")
SubtitleLabel.Text = "Enter your license key to unlock Nexus Hub"
SubtitleLabel.Font = Enum.Font.Gotham
SubtitleLabel.TextSize = 12
SubtitleLabel.TextColor3 = Color3.fromRGB(160, 175, 200)
SubtitleLabel.Size = UDim2.new(1, -36, 0, 20)
SubtitleLabel.Position = UDim2.new(0, 18, 0, 42)
SubtitleLabel.BackgroundTransparency = 1
SubtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
SubtitleLabel.Parent = MainFrame

-- Close Button
local CloseButton = Instance.new("TextButton")
CloseButton.Text = "X"
CloseButton.Font = Enum.Font.GothamBold
CloseButton.TextSize = 14
CloseButton.TextColor3 = Color3.fromRGB(180, 180, 180)
CloseButton.Size = UDim2.new(0, 28, 0, 28)
CloseButton.Position = UDim2.new(1, -38, 0, 10)
CloseButton.BackgroundColor3 = Color3.fromRGB(25, 32, 50)
CloseButton.BorderSizePixel = 0
CloseButton.Parent = MainFrame

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = CloseButton

CloseButton.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- Key Input Box
local InputFrame = Instance.new("Frame")
InputFrame.Size = UDim2.new(1, -36, 0, 42)
InputFrame.Position = UDim2.new(0, 18, 0, 75)
InputFrame.BackgroundColor3 = Color3.fromRGB(10, 14, 24)
InputFrame.BorderSizePixel = 0
InputFrame.Parent = MainFrame

local InputCorner = Instance.new("UICorner")
InputCorner.CornerRadius = UDim.new(0, 8)
InputCorner.Parent = InputFrame

local InputStroke = Instance.new("UIStroke")
InputStroke.Color = Color3.fromRGB(40, 55, 80)
InputStroke.Thickness = 1
InputStroke.Parent = InputFrame

local KeyInput = Instance.new("TextBox")
KeyInput.Size = UDim2.new(1, -20, 1, 0)
KeyInput.Position = UDim2.new(0, 10, 0, 0)
KeyInput.BackgroundTransparency = 1
KeyInput.Font = Enum.Font.Code
KeyInput.TextSize = 13
KeyInput.TextColor3 = Color3.fromRGB(240, 240, 240)
KeyInput.PlaceholderText = "Paste your key here (e.g. NEXUS-XXXX-XXXX)..."
KeyInput.PlaceholderColor3 = Color3.fromRGB(100, 115, 135)
KeyInput.ClearTextOnFocus = false
KeyInput.Parent = InputFrame

-- Status Label
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Text = ""
StatusLabel.Font = Enum.Font.GothamMedium
StatusLabel.TextSize = 12
StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
StatusLabel.Size = UDim2.new(1, -36, 0, 24)
StatusLabel.Position = UDim2.new(0, 18, 0, 122)
StatusLabel.BackgroundTransparency = 1
StatusLabel.TextXAlignment = Enum.TextXAlignment.Center
StatusLabel.Parent = MainFrame

-- Submit Button
local SubmitButton = Instance.new("TextButton")
SubmitButton.Text = "SUBMIT KEY"
SubmitButton.Font = Enum.Font.GothamBold
SubmitButton.TextSize = 13
SubmitButton.TextColor3 = Color3.fromRGB(10, 15, 25)
SubmitButton.Size = UDim2.new(1, -36, 0, 40)
SubmitButton.Position = UDim2.new(0, 18, 0, 152)
SubmitButton.BackgroundColor3 = Color3.fromRGB(0, 229, 255)
SubmitButton.BorderSizePixel = 0
SubmitButton.Parent = MainFrame

local SubmitCorner = Instance.new("UICorner")
SubmitCorner.CornerRadius = UDim.new(0, 8)
SubmitCorner.Parent = SubmitButton

-- Bottom Buttons Row (Get Key & Discord)
local GetKeyButton = Instance.new("TextButton")
GetKeyButton.Text = "Get Key (Copy URL)"
GetKeyButton.Font = Enum.Font.Gotham
GetKeyButton.TextSize = 11
GetKeyButton.TextColor3 = Color3.fromRGB(160, 180, 210)
GetKeyButton.Size = UDim2.new(0.5, -22, 0, 32)
GetKeyButton.Position = UDim2.new(0, 18, 0, 202)
GetKeyButton.BackgroundColor3 = Color3.fromRGB(20, 26, 42)
GetKeyButton.BorderSizePixel = 0
GetKeyButton.Parent = MainFrame

local GetKeyCorner = Instance.new("UICorner")
GetKeyCorner.CornerRadius = UDim.new(0, 6)
GetKeyCorner.Parent = GetKeyButton

local DiscordButton = Instance.new("TextButton")
DiscordButton.Text = "Join Discord"
DiscordButton.Font = Enum.Font.Gotham
DiscordButton.TextSize = 11
DiscordButton.TextColor3 = Color3.fromRGB(160, 180, 210)
DiscordButton.Size = UDim2.new(0.5, -22, 0, 32)
DiscordButton.Position = UDim2.new(0.5, 4, 0, 202)
DiscordButton.BackgroundColor3 = Color3.fromRGB(20, 26, 42)
DiscordButton.BorderSizePixel = 0
DiscordButton.Parent = MainFrame

local DiscordCorner = Instance.new("UICorner")
DiscordCorner.CornerRadius = UDim.new(0, 6)
DiscordCorner.Parent = DiscordButton

-- Button Actions
GetKeyButton.MouseButton1Click:Connect(function()
    if setclipboard then
        setclipboard(API_URL)
        StatusLabel.TextColor3 = Color3.fromRGB(0, 229, 255)
        StatusLabel.Text = "Copied website link to clipboard!"
    end
end)

DiscordButton.MouseButton1Click:Connect(function()
    if setclipboard then
        setclipboard(DISCORD_INVITE)
        StatusLabel.TextColor3 = Color3.fromRGB(121, 40, 202)
        StatusLabel.Text = "Copied Discord invite to clipboard!"
    end
end)

-- Submit logic
local isChecking = false
SubmitButton.MouseButton1Click:Connect(function()
    if isChecking then return end
    local key = KeyInput.Text:gsub("%s+", "")
    if #key == 0 then
        StatusLabel.TextColor3 = Color3.fromRGB(255, 71, 87)
        StatusLabel.Text = "Please enter a key first!"
        return
    end

    isChecking = true
    SubmitButton.Text = "CHECKING..."
    StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
    StatusLabel.Text = "Validating key with server..."

    task.spawn(function()
        local res = verifyKey(key)
        if res and res.success then
            StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 136)
            StatusLabel.Text = "Key Verified! Loading Nexus Hub..."
            
            -- Save key locally
            if typeof(writefile) == "function" then
                pcall(function() writefile(KEY_FILE, key) end)
            end

            task.wait(1)
            -- Fade out UI
            local tween = TweenService:Create(MainFrame, TweenInfo.new(0.4), {
                Position = UDim2.new(0.5, -210, 0.5, -115),
                BackgroundTransparency = 1
            })
            tween:Play()
            tween.Completed:Connect(function()
                ScreenGui:Destroy()
            end)

            getgenv().NexusTier = res.tier or "VIP"
            startHeartbeatLoop(key)
            executeMainScript(key)
        else
            StatusLabel.TextColor3 = Color3.fromRGB(255, 71, 87)
            StatusLabel.Text = (res and res.message) or "Invalid key or server offline!"
            SubmitButton.Text = "SUBMIT KEY"
            isChecking = false
        end
    end)
end)

-- Make draggable
local dragging, dragInput, dragStart, startPos
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

MainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

print("[Nexus Hub] Key System UI Initialized!")
