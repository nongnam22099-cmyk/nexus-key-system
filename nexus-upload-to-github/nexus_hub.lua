local success, err = pcall(function()
    if not game:IsLoaded() then
        game.Loaded:Wait()
    end
    local Players = game:GetService("Players")
    while not Players.LocalPlayer do
        task.wait(0.1)
    end
    local TweenService = game:GetService("TweenService")
    local UserInputService = game:GetService("UserInputService")
    local RunService = game:GetService("RunService")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")

    local LocalPlayer = Players.LocalPlayer
    local parentGui = (LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")) or (pcall(function() return gethui() end) and gethui()) or game:GetService("CoreGui") or (LocalPlayer and LocalPlayer:WaitForChild("PlayerGui", 5))

    if parentGui:FindFirstChild("ModernGamingUI") then
        parentGui.ModernGamingUI:Destroy()
    end
    if parentGui:FindFirstChild("NexusHub_GUI") then
        parentGui.NexusHub_GUI:Destroy()
    end

    -- Cancel previous script background loops and disconnect all active connections
    if _G.NexusHubToken then
        _G.NexusHubToken.running = false
    end
    local myToken = { running = true }
    _G.NexusHubToken = myToken

    if _G.NexusConnections then
        for _, c in ipairs(_G.NexusConnections) do
            pcall(function() c:Disconnect() end)
        end
    end
    _G.NexusConnections = {}

    -- Disconnect any lingering rogue platform watchdog connections from previous unmanaged runs
    pcall(function()
        local function cleanSignals(sig)
            local cons = getconnections and getconnections(sig)
            if not cons then return end
            for _, c in ipairs(cons) do
                local fn = c.Function
                if fn and type(fn) == "function" then
                    local ups = getupvalues and getupvalues(fn) or {}
                    local consts = getconstants and getconstants(fn) or {}
                    local matched = false
                    for _, u in pairs(ups) do
                        if u == workspace:FindFirstChild("Nexus_Platform") or (type(u) == "string" and u:find("Nexus_Platform")) then
                            matched = true break
                        end
                    end
                    if not matched then
                        for _, k in pairs(consts) do
                            if type(k) == "string" and (k:find("Nexus_Platform") or k:find("safePlatform") or k:find("_LocalFarmPig")) then
                                matched = true break
                            end
                        end
                    end
                    if matched then
                        pcall(function() c:Disconnect() end)
                    end
                end
            end
        end
        cleanSignals(RunService.Heartbeat)
        cleanSignals(RunService.Stepped)
        cleanSignals(RunService.RenderStepped)
    end)

    -- =========================================================================
    -- [ WHITE CIRCLE REMOVAL & CLEAN SAFE EXECUTION (NO HOOKS - 100% SAFE) ]
    -- =========================================================================
    -- ลบวงกลมสีขาว (Mic / Voice Range Circle) ใต้เท้าตัวละครออกอย่างสมบูรณ์
    local function removeWhiteCircle(char)
        pcall(function()
            char = char or LocalPlayer.Character
            if not char then return end
            local mic = char:FindFirstChild("Mic")
            if mic then
                mic:Destroy()
            end
            for _, obj in ipairs(char:GetDescendants()) do
                if obj.Name == "Mic" or obj.Name == "Circle" then
                    pcall(function() obj:Destroy() end)
                end
            end
        end)
    end

    removeWhiteCircle()
    table.insert(_G.NexusConnections, LocalPlayer.CharacterAdded:Connect(function(char)
        task.wait(0.2)
        removeWhiteCircle(char)
        char.ChildAdded:Connect(function(child)
            if child.Name == "Mic" or child.Name == "Circle" or child.Name:lower():find("circle") then
                pcall(function() child:Destroy() end)
            end
        end)
    end))

    if LocalPlayer.Character then
        LocalPlayer.Character.ChildAdded:Connect(function(child)
            if child.Name == "Mic" or child.Name == "Circle" or child.Name:lower():find("circle") then
                pcall(function() child:Destroy() end)
            end
        end)
    end

    -- =========================================================================
    -- [ AUTO-UNLOCK "พร้อมแล้ว" (ANTIFALL READY) WATCHDOG ]
    -- =========================================================================
    task.spawn(function()
        local function checkAndUnlock()
            pcall(function()
                local pGui = LocalPlayer:FindFirstChild("PlayerGui")
                local af = pGui and pGui:FindFirstChild("Antifall")
                if af and af.Enabled then
                    local cg = af:FindFirstChild("CanvasGroup")
                    local main = cg and cg:FindFirstChild("Main")
                    local btn = main and main:FindFirstChild("Button")
                    if btn and firesignal then
                        firesignal(btn.Activated)
                        firesignal(btn.MouseButton1Click)
                    end
                    if Remotes and Remotes.Fire then
                        Remotes.Fire("_request", "AntifallReady")
                    end
                    af.Enabled = false
                end

                local char = LocalPlayer.Character
                if char and char:GetAttribute("AntifallActive") == true then
                    if Remotes and Remotes.Fire then
                        Remotes.Fire("_request", "AntifallReady")
                    end
                end
            end)
        end

        checkAndUnlock()
        table.insert(_G.NexusConnections, LocalPlayer.CharacterAdded:Connect(function()
            task.wait(0.3)
            checkAndUnlock()
        end))
        while myToken.running do
            checkAndUnlock()
            task.wait(1.5)
        end
    end)


    -- THEME: LIGHT CYAN (Strictly Zero Emojis)
    local accent = Color3.fromRGB(120, 225, 255)
    local bg = Color3.fromRGB(13, 25, 37)
    local panel = Color3.fromRGB(22, 42, 57)
    local white = Color3.fromRGB(235, 250, 255)
    local muted = Color3.fromRGB(165, 205, 220)
    local borderColor = Color3.fromRGB(55, 105, 130)

    -- Remotes
    local Remotes = nil
    pcall(function()
        Remotes = require(ReplicatedStorage.Systems.Modules.Core.Remotes)
    end)

    -- Safe Anti-Fall Platform (แผ่นพื้นสีฟ้ากันตกโลกใต้ดิน - แสดงเฉพาะเวลาฟาร์มเท่านั้น)
    local safePlatform = workspace:FindFirstChild("Nexus_Platform")
    if not safePlatform then
        safePlatform = Instance.new("Part")
        safePlatform.Name = "Nexus_Platform"
        safePlatform.Parent = workspace
    end
    safePlatform.Size = Vector3.new(35, 1.5, 35)
    safePlatform.Anchored = true
    safePlatform.CanCollide = false
    safePlatform.Color = Color3.fromRGB(0, 170, 255)
    safePlatform.Material = Enum.Material.Neon
    safePlatform.Transparency = 1
    safePlatform.Position = Vector3.new(0, -9999, 0)
    safePlatform.CastShadow = false

    -- STAND HEIGHT OFFSET:
    -- Character HipHeight (~2.26) + HRP half-height (~1.13) = 3.39 studs from HRP to soles of feet
    -- Platform Size.Y (1.5) / 2 = 0.75 studs from center to top surface
    -- Center of platform must be at HRP.Y - (3.39 + 0.75) = HRP.Y - 4.14 studs so feet stand directly on top
    local PLATFORM_OFFSET_Y = 4.14

    local function updateSafePlatform(targetPos, isFarming)
        if not safePlatform then return end
        if isFarming and targetPos then
            safePlatform.Transparency = 1
            safePlatform.CanCollide = true
            safePlatform.Size = Vector3.new(35, 1.5, 35)
            safePlatform.CFrame = CFrame.new(targetPos.X, targetPos.Y - PLATFORM_OFFSET_Y, targetPos.Z)
        else
            safePlatform.Transparency = 1
            safePlatform.CanCollide = false
            safePlatform.CFrame = CFrame.new(0, -9999, 0)
        end
    end

    -- Raycast parameters excluding player and platform
    local rayParams = RaycastParams.new()
    pcall(function() rayParams.FilterType = Enum.RaycastFilterType.Exclude end)
    if not rayParams.FilterType then rayParams.FilterType = Enum.RaycastFilterType.Blacklist end
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character, safePlatform}

    -- Ground detection helper function (strictly filters for collidable solid surfaces)
    local function getGroundAt(x, z, hintY)
        local baseFilter = {safePlatform}
        if LocalPlayer.Character then
            table.insert(baseFilter, LocalPlayer.Character)
        end

        local function castCollidable(origin, dir)
            local filter = table.clone(baseFilter)
            local curOrigin = origin
            local remainingDist = dir.Magnitude
            local rayDir = dir.Unit
            for _ = 1, 6 do
                local params = RaycastParams.new()
                params.FilterType = Enum.RaycastFilterType.Exclude
                params.FilterDescendantsInstances = filter
                local hit = workspace:Raycast(curOrigin, rayDir * remainingDist, params)
                if not hit then return nil, nil end
                if hit.Instance.CanCollide then
                    return hit.Position.Y, hit.Instance
                end
                table.insert(filter, hit.Instance)
                local stepDist = (hit.Position - curOrigin).Magnitude + 0.05
                remainingDist = remainingDist - stepDist
                if remainingDist <= 0.1 then break end
                curOrigin = hit.Position + (rayDir * 0.05)
            end
            return nil, nil
        end

        -- 1. Try casting from just above hintY (accurately hits room floors without striking ceilings)
        if hintY then
            local gY, inst = castCollidable(Vector3.new(x, hintY + 4, z), Vector3.new(0, -70, 0))
            if gY then
                return gY, inst
            end
        end

        -- 2. Fallback: cast from above
        local originHigh = Vector3.new(x, math.max((hintY or 30) + 40, 60), z)
        local gY, inst = castCollidable(originHigh, Vector3.new(0, -350, 0))
        if gY then
            return gY, inst
        end
        return nil, nil
    end

    -- Check if game's native auto-farm session is currently active
    local function isFarmingActive()
        local autoFarmGui = LocalPlayer.PlayerGui:FindFirstChild("Auto Farm")
        local grp = autoFarmGui and autoFarmGui:FindFirstChild("Group")
        return grp and (grp.Visible == true and grp.GroupTransparency < 0.5)
    end

    local LOBBY_PLACE_ID = 73746968849439
    local MAIN_PLACE_ID = 119554426329370

    -- ระบบตรวจจับสถานะหน้าเลือกเซิร์ฟเวอร์ (Server Selection Screen / Lobby / Loading)
    local function isAtServerSelectionScreen()
        -- 1. ตรวจสอบ PlaceId: หากอยู่ใน Lobby (73746968849439) หรือไม่ใช่เซิร์ฟเวอร์หลัก (119554426329370)
        if game.PlaceId == LOBBY_PLACE_ID or game.PlaceId ~= MAIN_PLACE_ID then
            return true
        end

        -- 2. ตรวจสอบว่าระบบเกมในแมพโหลดเสร็จสมบูรณ์หรือยัง
        if not game:IsLoaded() then
            return true
        end

        -- 3. ตรวจสอบข้อมูลผู้เล่น (PlayerData)
        local hasPlayerData = LocalPlayer:FindFirstChild("PlayerData")
        if not hasPlayerData then
            return true
        end

        -- 4. ตรวจสอบตัวละครว่าเกิดและพร้อมใช้งานหรือยัง
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not char or not root or not hum or hum.Health <= 0 then
            return true
        end

        return false
    end

    -- Exact Map Coordinates (Tested and verified with live ProximityPrompts)
    local FARM_COORDS = {
        Bread = Vector3.new(-314.4, 30.5, 4879.0),       -- วงใหญ่ฟาร์มขนมปัง
        Catchup = Vector3.new(3472.2, 25.5, 3898.1),     -- วงใหญ่ฟาร์มซอสมะเขือเทศ
        Pig = Vector3.new(-3075.3, 24.5, 2931.4),         -- วงใหญ่ฟาร์มเนื้อหมู
        Mango = Vector3.new(-1058.9, 25.5, 924.4),        -- วงใหญ่ฟาร์มมะม่วง
        Rice = Vector3.new(-496.7, 25.5, -363.0),         -- วงใหญ่ฟาร์มข้าว
        Rock = Vector3.new(-1529.71, 21.25, 2498.93),     -- เหมืองหินตรงแท่นฟาร์มจริง 100%
        Svibranium = Vector3.new(-5831.49, 24.69, 4215.42),-- เหมืองไวเบรเนียมตรงแท่นฟาร์มจริง 100%
        ProcessRock = Vector3.new(-5693.72, 154.50, 3315.36),
        ProcessSvib = Vector3.new(-5668.62, 154.50, 3323.75),
        CraftFood = Vector3.new(2453.28, 24.59, 4658.14),
        CraftEquip = Vector3.new(-3266.5, 45.8, -1995.0),
        CraftWeapon = Vector3.new(-3278.3, 46.4, -2015.2),
        Sell = Vector3.new(677.10, 24.77, 3294.47),
        Shop = Vector3.new(1886.70, 23.39, 3093.92),
        Vault = Vector3.new(-3212.34, 31.86, -2012.73),
        Banana = Vector3.new(-2950.85, 26.59, 4956.26),   -- ฟาร์มกล้วยตรงแท่นฟาร์มจริง 100%
        ProcessBanana = Vector3.new(2447.23, 24.59, 4674.32),-- จุดแปรรูปห่อกล้วย (Banana Process / Banana2 โพกล้วย)
        Fish = Vector3.new(437.3, 30.6, -3004.0)            -- จุดตกปลาแม่น้ำหลัก
    }

    local state = {
        sandwich = false,
        mangoRice = false,
        bananaFarm = false,
        fishFarm = false,
        rockFarm = false,
        svibFarm = false,
        autoVaultOres = true, -- ฝากแร่และไวเบรเนียมในตู้เซฟอัตโนมัติเมื่อฟาร์ม/หลอมเสร็จ
        undergroundDepth = 15.0,
        moveSpeed = 160.0, -- ความเร็วเคลื่อนที่ใต้ดิน (studs/s) รวดเร็ว ว่องไว ปลอดภัย ตัวไม่โผล่
        walkInDistance = 100.0, -- ระยะโผล่นอกวงฟาร์มเพื่อเดินเท้าเข้าสู่เป้าหมาย (studs)
        isFlying = false,
        isManualAction = false,
        stopRequested = false,
        autoEat = true,
        autoDrink = true,
        eatThreshold = 50,
        drinkThreshold = 50,
        antiAfk = true, -- ระบบกันหลุด 24 ชม. (Anti-AFK)
        autoRejoin = true, -- ระบบรีจอยอัตโนมัติ
        autoLowestServer = false,
        autoSaveConfig = false,
        serverHopPlayerLimitEnabled = false, -- รีจอยอัตโนมัติเมื่อคนในเซิร์ฟเกินกำหนด
        maxPlayersLimit = 25,                -- จำนวนผู้เล่นสูงสุดที่ยอมรับได้
        antiLag = false,                     -- โหมดกันหน่วง/กราฟิกต่ำ (Low Graphics Anti-Lag)
        fpsCap = 60,                         -- ขีดจำกัด FPS (ลด FPS เพื่อประหยัด CPU/GPU)
        gpuSaver = false                     -- โหมดประหยัดการ์ดจอ (ปิดการเรนเดอร์ 3D)
    }

    -- =========================================================================
    -- [ CONFIGURATION MANAGER (PERSISTENT SAVE & LOAD) ]
    -- =========================================================================
    local CONFIG_FOLDER = "NexusHub"
    local CONFIG_PATH = "NexusHub/config.json"
    local HttpService = game:GetService("HttpService")

    local function ensureConfigFolder()
        pcall(function()
            if isfolder and makefolder then
                if not isfolder(CONFIG_FOLDER) then
                    makefolder(CONFIG_FOLDER)
                end
            end
        end)
    end

    local syncUIFromState = nil -- Forward declaration (assigned after UI creation)
    local StatusText = nil -- Forward declaration (assigned after UI creation)
    local RodStatusText = nil -- Forward declaration (assigned after UI creation)
    local FishCountText = nil -- Forward declaration (assigned after UI creation)
    local cancelGameFarm = nil -- Forward declaration (assigned below)

    local function saveConfig()
        local data = {
            sandwich = state.sandwich,
            mangoRice = state.mangoRice,
            bananaFarm = state.bananaFarm,
            fishFarm = state.fishFarm,
            rockFarm = state.rockFarm,
            svibFarm = state.svibFarm,
            autoVaultOres = state.autoVaultOres,
            undergroundDepth = state.undergroundDepth,
            moveSpeed = state.moveSpeed,
            walkInDistance = state.walkInDistance,
            autoEat = state.autoEat,
            autoDrink = state.autoDrink,
            eatThreshold = state.eatThreshold,
            drinkThreshold = state.drinkThreshold,
            antiAfk = state.antiAfk,
            autoRejoin = state.autoRejoin,
            autoLowestServer = state.autoLowestServer,
            autoSaveConfig = state.autoSaveConfig,
            serverHopPlayerLimitEnabled = state.serverHopPlayerLimitEnabled,
            maxPlayersLimit = state.maxPlayersLimit,
            antiLag = state.antiLag,
            fpsCap = state.fpsCap,
            gpuSaver = state.gpuSaver
        }

        local success, encoded = pcall(function()
            return HttpService:JSONEncode(data)
        end)

        if success and encoded then
            pcall(function()
                ensureConfigFolder()
                if writefile then
                    writefile(CONFIG_PATH, encoded)
                end
            end)
            return true
        end
        return false
    end

    local function loadConfig()
        local loaded = false
        pcall(function()
            ensureConfigFolder()
            if isfile and readfile and isfile(CONFIG_PATH) then
                local content = readfile(CONFIG_PATH)
                if content and #content > 0 then
                    local decoded = HttpService:JSONDecode(content)
                    if type(decoded) == "table" then
                        if decoded.sandwich ~= nil then state.sandwich = decoded.sandwich end
                        if decoded.mangoRice ~= nil then state.mangoRice = decoded.mangoRice end
                        if decoded.bananaFarm ~= nil then state.bananaFarm = decoded.bananaFarm end
                        if decoded.fishFarm ~= nil then state.fishFarm = decoded.fishFarm end
                        if decoded.rockFarm ~= nil then state.rockFarm = decoded.rockFarm end
                        if decoded.svibFarm ~= nil then state.svibFarm = decoded.svibFarm end
                        if decoded.autoVaultOres ~= nil then state.autoVaultOres = decoded.autoVaultOres end
                        if type(decoded.undergroundDepth) == "number" then
                            state.undergroundDepth = math.clamp(decoded.undergroundDepth, 10.0, 30.0)
                            if state.undergroundDepth < 12.0 then
                                state.undergroundDepth = 15.0
                            end
                        end
                        if type(decoded.moveSpeed) == "number" then
                            state.moveSpeed = math.clamp(decoded.moveSpeed, 30.0, 300.0)
                            if state.moveSpeed < 80.0 then
                                state.moveSpeed = 160.0
                            end
                        end
                        if type(decoded.walkInDistance) == "number" then
                            state.walkInDistance = math.clamp(decoded.walkInDistance, 10.0, 150.0)
                        end
                        if decoded.autoEat ~= nil then state.autoEat = decoded.autoEat end
                        if decoded.autoDrink ~= nil then state.autoDrink = decoded.autoDrink end
                        if type(decoded.eatThreshold) == "number" then state.eatThreshold = decoded.eatThreshold end
                        if type(decoded.drinkThreshold) == "number" then state.drinkThreshold = decoded.drinkThreshold end
                        if decoded.antiAfk ~= nil then state.antiAfk = decoded.antiAfk end
                        if decoded.autoRejoin ~= nil then state.autoRejoin = decoded.autoRejoin end
                        if decoded.autoLowestServer ~= nil then state.autoLowestServer = decoded.autoLowestServer end
                        state.autoSaveConfig = false -- manual save only
                        if decoded.serverHopPlayerLimitEnabled ~= nil then state.serverHopPlayerLimitEnabled = decoded.serverHopPlayerLimitEnabled end
                        if type(decoded.maxPlayersLimit) == "number" then state.maxPlayersLimit = math.clamp(decoded.maxPlayersLimit, 2, 60) end
                        if decoded.antiLag ~= nil then state.antiLag = decoded.antiLag end
                        if type(decoded.fpsCap) == "number" then state.fpsCap = math.clamp(decoded.fpsCap, 10, 240) end
                        if decoded.gpuSaver ~= nil then state.gpuSaver = decoded.gpuSaver end
                        loaded = true
                    end
                end
            end
        end)
        return loaded
    end

    -- Initial load on script boot
    loadConfig()

    -- AUTO EAT & DRINK IMPLEMENTATION
    local isConsuming = false
    local isRestocking = false
    local lastEatTime = 0
    local lastDrinkTime = 0
    local lastRestockTime = 0

    local function getVitalStats()
        local hunger = 100
        local brain = 100

        -- 1. Source of truth from LocalPlayer.Stats attributes
        local stats = LocalPlayer:FindFirstChild("Stats")
        if stats then
            local hAttr = stats:GetAttribute("Hunger")
            local bAttr = stats:GetAttribute("Brain")
            if typeof(hAttr) == "number" then hunger = hAttr end
            if typeof(bAttr) == "number" then brain = bAttr end
            return hunger, brain
        end

        -- 2. Fallback to HUD labels
        local hud = LocalPlayer.PlayerGui:FindFirstChild("HUD")
        if hud and hud:FindFirstChild("Health") then
            local hungerPart = hud.Health:FindFirstChild("Hunger")
            local brainPart = hud.Health:FindFirstChild("Brain")
            local hLbl = hungerPart and hungerPart:FindFirstChild("Percent", true) and hungerPart.Percent:FindFirstChild("Percent")
            local bLbl = brainPart and brainPart:FindFirstChild("Percent", true) and brainPart.Percent:FindFirstChild("Percent")
            if hLbl and tonumber(hLbl.Text) then hunger = tonumber(hLbl.Text) end
            if bLbl and tonumber(bLbl.Text) then brain = tonumber(bLbl.Text) end
        end

        return hunger, brain
    end

    local ensureSupplies = nil -- Forward declaration (implemented below flyUnderground)

    local function consumeFood()
        if isConsuming or isRestocking then return false end
        if os.clock() - lastEatTime < 6 then return false end

        local curHunger, _ = getVitalStats()
        if curHunger > state.eatThreshold then return false end

        local pData = LocalPlayer:FindFirstChild("PlayerData")
        local sushi = pData and (pData:GetAttribute("Sushi") or 0) or 0
        if sushi <= 0 then
            local money = pData and (pData:GetAttribute("Money") or 0) or 0
            if money >= 200 and ensureSupplies then
                ensureSupplies("Food")
                sushi = pData and (pData:GetAttribute("Sushi") or 0) or 0
            end
            if sushi <= 0 then return false end
        end

        isConsuming = true
        lastEatTime = os.clock()
        if StatusText then StatusText.Text = "ความหิวต่ำ! กำลังกินซูชิเพิ่มพลัง..." end

        local ok, err = pcall(function()
            -- If farming is active, cancel it first so food tool can be equipped
            if isFarmingActive and isFarmingActive() and cancelGameFarm then
                cancelGameFarm()
                local t0 = os.clock()
                while isFarmingActive() and os.clock() - t0 < 1.5 do
                    task.wait(0.1)
                end
            end

            pcall(function()
                Remotes.Fire("_inventory", "Use", "Sushi")
            end)

            -- Wait for Sushi tool to appear in Character or Backpack (up to 3.0s)
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local tool = nil
            local t0 = os.clock()
            while os.clock() - t0 < 3.0 do
                char = LocalPlayer.Character
                tool = char and (char:FindFirstChild("Sushi") or LocalPlayer.Backpack:FindFirstChild("Sushi"))
                if tool then break end
                task.wait(0.1)
            end

            if tool and char then
                hum = char:FindFirstChildOfClass("Humanoid")
                if hum then
                    if tool.Parent ~= char then
                        hum:EquipTool(tool)
                        task.wait(0.2)
                    end
                    tool:Activate()

                    -- Wait for hunger to replenish (Sushi takes ~5s)
                    local initialHunger = curHunger
                    local tEat = os.clock()
                    while os.clock() - tEat < 5.5 do
                        local hNow = getVitalStats()
                        if hNow > initialHunger + 20 then
                            break
                        end
                        task.wait(0.2)
                    end

                    pcall(function() hum:UnequipTools() end)
                end
            else
                task.wait(2.0)
                if hum then pcall(function() hum:UnequipTools() end) end
            end
        end)

        isConsuming = false
        return true
    end

    local function consumeDrink()
        if isConsuming or isRestocking then return false end
        if os.clock() - lastDrinkTime < 5 then return false end

        local _, curBrain = getVitalStats()
        if curBrain > state.drinkThreshold then return false end

        local pData = LocalPlayer:FindFirstChild("PlayerData")
        local cocoa = pData and (pData:GetAttribute("HotCocoa") or 0) or 0
        if cocoa <= 0 then
            local money = pData and (pData:GetAttribute("Money") or 0) or 0
            if money >= 200 and ensureSupplies then
                ensureSupplies("Drink")
                cocoa = pData and (pData:GetAttribute("HotCocoa") or 0) or 0
            end
            if cocoa <= 0 then return false end
        end

        isConsuming = true
        lastDrinkTime = os.clock()
        if StatusText then StatusText.Text = "ความกระหายต่ำ! กำลังดื่มโกโก้เพิ่มพลัง..." end

        local ok, err = pcall(function()
            -- If farming is active, cancel it first so drink tool can be equipped
            if isFarmingActive and isFarmingActive() and cancelGameFarm then
                cancelGameFarm()
                local t0 = os.clock()
                while isFarmingActive() and os.clock() - t0 < 1.5 do
                    task.wait(0.1)
                end
            end

            pcall(function()
                Remotes.Fire("_inventory", "Use", "HotCocoa")
            end)

            -- Wait for HotCocoa tool to appear in Character or Backpack (up to 3.0s)
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local tool = nil
            local t0 = os.clock()
            while os.clock() - t0 < 3.0 do
                char = LocalPlayer.Character
                tool = char and (char:FindFirstChild("HotCocoa") or LocalPlayer.Backpack:FindFirstChild("HotCocoa"))
                if tool then break end
                task.wait(0.1)
            end

            if tool and char then
                hum = char:FindFirstChildOfClass("Humanoid")
                if hum then
                    if tool.Parent ~= char then
                        hum:EquipTool(tool)
                        task.wait(0.2)
                    end
                    tool:Activate()

                    -- Wait for brain/thirst to replenish (HotCocoa takes ~3s)
                    local initialBrain = curBrain
                    local tDrink = os.clock()
                    while os.clock() - tDrink < 3.5 do
                        local _, bNow = getVitalStats()
                        if bNow > initialBrain + 20 then
                            break
                        end
                        task.wait(0.2)
                    end

                    pcall(function() hum:UnequipTools() end)
                end
            else
                task.wait(2.0)
                if hum then pcall(function() hum:UnequipTools() end) end
            end
        end)

        isConsuming = false
        return true
    end

    -- Autonomous Consumption & Auto-Restock Loop
    task.spawn(function()
        while myToken.running do
            if isAtServerSelectionScreen() then
                task.wait(2.0)
            else
                pcall(function()
                    -- Watchdog: Auto-reset stuck consumption or restock flags
                    if isConsuming and os.clock() - lastEatTime > 15 and os.clock() - lastDrinkTime > 15 then
                        isConsuming = false
                    end
                    if isRestocking and os.clock() - lastRestockTime > 30 then
                        isRestocking = false
                    end

                    if not isConsuming and not state.isFlying and not isRestocking then
                        local curHunger, curBrain = getVitalStats()
                        local pData = LocalPlayer:FindFirstChild("PlayerData")
                        local sushi = pData and (pData:GetAttribute("Sushi") or 0) or 0
                        local cocoa = pData and (pData:GetAttribute("HotCocoa") or 0) or 0
                        local money = pData and (pData:GetAttribute("Money") or 0) or 0

                        -- Proactive Restock: If hungry/thirsty and food/water is empty, warp to buy!
                        if ensureSupplies and money >= 200 then
                            if (state.autoEat and curHunger <= state.eatThreshold and sushi <= 0) or
                               (state.autoDrink and curBrain <= state.drinkThreshold and cocoa <= 0) then
                                ensureSupplies("Depleted")
                                sushi = pData and (pData:GetAttribute("Sushi") or 0) or 0
                                cocoa = pData and (pData:GetAttribute("HotCocoa") or 0) or 0
                            end
                        end

                        -- Only eat if hunger is less than or equal to threshold
                        if state.autoEat and curHunger <= state.eatThreshold and sushi > 0 then
                            consumeFood()
                        -- Only drink if brain is less than or equal to threshold
                        elseif state.autoDrink and curBrain <= state.drinkThreshold and cocoa > 0 then
                            consumeDrink()
                        end
                    end
                end)
                task.wait(1.5)
            end
        end
    end)

    -- GHOST WATCHDOG: Ensures _LocalFarmPig always stays on the ground surface
    table.insert(_G.NexusConnections, RunService.RenderStepped:Connect(function()
        local pig = workspace:FindFirstChild("_LocalFarmPig")
        if pig and pig.PrimaryPart then
            local pos = pig.PrimaryPart.Position
            local gY, _ = getGroundAt(pos.X, pos.Z, pos.Y)
            if gY and pos.Y < gY then
                pig.PrimaryPart.CFrame = CFrame.new(pos.X, gY + 1.2, pos.Z) * (pig.PrimaryPart.CFrame - pos)
            end
        end
    end))

    -- TRAVEL NOCLIP (Only active during rapid long-distance travel)
    table.insert(_G.NexusConnections, RunService.Stepped:Connect(function()
        local isTraveling = state.isFlying
        if not isTraveling then return end
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end))

    -- ACTIVE UNDERGROUND ANTI-VOID & ANTI-FALL WATCHDOG (ระบบกันตกโลกใต้ดิน 100%)
    table.insert(_G.NexusConnections, RunService.Heartbeat:Connect(function()
        if not myToken.running then return end
        if isAtServerSelectionScreen() then
            updateSafePlatform(nil, false)
            return
        end
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root or not safePlatform then return end

        local isUndergroundActive = state.isFlying or state.sandwich or state.mangoRice or state.bananaFarm or state.fishFarm or state.rockFarm or state.svibFarm or isRestocking or isConsuming

        if isUndergroundActive then
            -- Emergency Void Rescue: If character drops into the void below map ground level
            if root.Position.Y < 3.0 then
                root.AssemblyLinearVelocity = Vector3.zero
                root.AssemblyAngularVelocity = Vector3.zero
                root.CFrame = CFrame.new(root.Position.X, 25.0, root.Position.Z)
            end
        else
            -- Completely hide platform and disable collisions when not farming
            updateSafePlatform(nil, false)
        end
    end))

    -- Create Main UI
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "ModernGamingUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = parentGui

    local MainFrame = Instance.new("CanvasGroup")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 600, 0, 450)
    MainFrame.Position = UDim2.new(0.5, -300, 0.5, -225)
    MainFrame.BackgroundColor3 = bg
    MainFrame.BorderSizePixel = 0
    MainFrame.GroupTransparency = 0
    MainFrame.Parent = ScreenGui

    local MainScale = Instance.new("UIScale")
    MainScale.Scale = 1.0
    MainScale.Parent = MainFrame

    do
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 8)
        c.Parent = MainFrame

        local s = Instance.new("UIStroke")
        s.Color = borderColor
        s.Thickness = 1.5
        s.Parent = MainFrame
    end

    -- Smooth Open / Close Animation State
    local isUiOpen = true
    local isUiAnimating = false

    local function toggleUI(forceState)
        if isUiAnimating then return end
        local targetState = (forceState ~= nil and forceState) or (forceState == nil and not isUiOpen)
        if targetState == isUiOpen and MainFrame.Visible == isUiOpen then return end
        isUiOpen = targetState
        isUiAnimating = true

        local floatBtn = ScreenGui:FindFirstChild("NexusFloatingBtn")

        if isUiOpen then
            if floatBtn then floatBtn.Visible = false end
            MainFrame.Visible = true
            MainFrame.GroupTransparency = 1
            MainScale.Scale = 0.90
            TweenService:Create(MainFrame, TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {GroupTransparency = 0}):Play()
            local tw = TweenService:Create(MainScale, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1.0})
            tw:Play()
            tw.Completed:Connect(function()
                isUiAnimating = false
            end)
        else
            TweenService:Create(MainFrame, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {GroupTransparency = 1}):Play()
            local tw = TweenService:Create(MainScale, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Scale = 0.90})
            tw:Play()
            tw.Completed:Connect(function()
                MainFrame.Visible = false
                if floatBtn then floatBtn.Visible = true end
                isUiAnimating = false
            end)
        end
    end

    -- TopBar
    do
        local TopBar = Instance.new("Frame")
        TopBar.Name = "TopBar"
        TopBar.Size = UDim2.new(1, 0, 0, 44)
        TopBar.BackgroundColor3 = panel
        TopBar.BorderSizePixel = 0
        TopBar.Parent = MainFrame

        local Title = Instance.new("TextLabel")
        Title.Text = "NEXUS HUB | เซิร์ฟเวอร์หลัก"
        Title.Font = Enum.Font.GothamBold
        Title.TextSize = 14
        Title.TextColor3 = white
        Title.TextXAlignment = Enum.TextXAlignment.Left
        Title.Position = UDim2.new(0, 16, 0, 0)
        Title.Size = UDim2.new(1, -95, 1, 0)
        Title.BackgroundTransparency = 1
        Title.Parent = TopBar

        -- ปุ่มพับเมนู (Minimize / Fold Button)
        local MinBtn = Instance.new("TextButton")
        MinBtn.Name = "MinBtn"
        MinBtn.Text = "—"
        MinBtn.Font = Enum.Font.GothamBold
        MinBtn.TextSize = 13
        MinBtn.TextColor3 = white
        MinBtn.Size = UDim2.new(0, 30, 0, 30)
        MinBtn.Position = UDim2.new(1, -74, 0, 7)
        MinBtn.BackgroundColor3 = Color3.fromRGB(35, 60, 80)
        MinBtn.BorderSizePixel = 0
        MinBtn.Parent = TopBar
        local MinCorner = Instance.new("UICorner")
        MinCorner.CornerRadius = UDim.new(0, 6)
        MinCorner.Parent = MinBtn

        MinBtn.MouseEnter:Connect(function()
            TweenService:Create(MinBtn, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {BackgroundColor3 = Color3.fromRGB(0, 160, 220), TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
        end)
        MinBtn.MouseLeave:Connect(function()
            TweenService:Create(MinBtn, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {BackgroundColor3 = Color3.fromRGB(35, 60, 80), TextColor3 = white}):Play()
        end)
        MinBtn.MouseButton1Click:Connect(function()
            toggleUI(false)
        end)

        local CloseBtn = Instance.new("TextButton")
        CloseBtn.Text = "X"
        CloseBtn.Font = Enum.Font.GothamBold
        CloseBtn.TextSize = 13
        CloseBtn.TextColor3 = white
        CloseBtn.Size = UDim2.new(0, 30, 0, 30)
        CloseBtn.Position = UDim2.new(1, -38, 0, 7)
        CloseBtn.BackgroundColor3 = Color3.fromRGB(35, 60, 80)
        CloseBtn.BorderSizePixel = 0
        CloseBtn.Parent = TopBar
        local CloseCorner = Instance.new("UICorner")
        CloseCorner.CornerRadius = UDim.new(0, 6)
        CloseCorner.Parent = CloseBtn

        CloseBtn.MouseEnter:Connect(function()
            TweenService:Create(CloseBtn, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {BackgroundColor3 = Color3.fromRGB(220, 60, 60), TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
        end)
        CloseBtn.MouseLeave:Connect(function()
            TweenService:Create(CloseBtn, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {BackgroundColor3 = Color3.fromRGB(35, 60, 80), TextColor3 = white}):Play()
        end)
        CloseBtn.MouseButton1Click:Connect(function()
            toggleUI(false)
        end)

        -- Smooth Dragging for MainFrame (Constrained strictly to TopBar)
        local dragging = false
        local dragStart = nil
        local startPos = nil

        TopBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
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

        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - dragStart
                local targetPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
                TweenService:Create(MainFrame, TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = targetPos}):Play()
            end
        end)
    end

    -- Smooth Button Micro-Interactions Helper (Hover glow + physical click bounce)
    local function makeButtonSmooth(btn, normalBg, hoverBg, clickBg)
        if not btn or not btn:IsA("GuiButton") then return end
        local normalColor = normalBg or btn.BackgroundColor3
        local hoverColor = hoverBg or Color3.fromRGB(
            math.min(255, math.floor(normalColor.R * 255 + 24)),
            math.min(255, math.floor(normalColor.G * 255 + 24)),
            math.min(255, math.floor(normalColor.B * 255 + 24))
        )
        local clickColor = clickBg or Color3.fromRGB(
            math.max(0, math.floor(normalColor.R * 255 - 28)),
            math.max(0, math.floor(normalColor.G * 255 - 28)),
            math.max(0, math.floor(normalColor.B * 255 - 28))
        )

        local origSize = btn.Size

        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = hoverColor}):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = normalColor}):Play()
        end)
        btn.MouseButton1Down:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundColor3 = clickColor,
                Size = UDim2.new(origSize.X.Scale, math.max(0, origSize.X.Offset - 3), origSize.Y.Scale, math.max(0, origSize.Y.Offset - 2))
            }):Play()
        end)
        btn.MouseButton1Up:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                BackgroundColor3 = hoverColor,
                Size = origSize
            }):Play()
        end)
    end

    -- Smooth Toggle Button Helper
    local function animateButtonToggle(btn, isToggled, onText, offText, onBg, offBg)
        local targetBg = isToggled and (onBg or accent) or (offBg or Color3.fromRGB(45, 60, 75))
        local targetText = isToggled and Color3.fromRGB(10, 20, 30) or white
        btn.Text = isToggled and (onText or "เปิด") or (offText or "ปิด")
        TweenService:Create(btn, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundColor3 = targetBg,
            TextColor3 = targetText
        }):Play()
        local origSize = btn.Size
        btn.Size = UDim2.new(origSize.X.Scale, math.max(0, origSize.X.Offset - 3), origSize.Y.Scale, math.max(0, origSize.Y.Offset - 2))
        TweenService:Create(btn, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = origSize
        }):Play()
    end

    -- ปุ่มลอยรูปโลโก้เปิด/ปิดเมนู (Floating Toggle Button with Custom Nexus Hub Logo)
    local LOGO_B64 = "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"
    local logoAsset = nil
    pcall(function()
        local decode = base64_decode or (crypt and crypt.base64_decode)
        if decode and writefile then
            if not isfile or not isfile("NexusHub/nexus_logo.png") then
                if isfolder and not isfolder("NexusHub") then makefolder("NexusHub") end
                writefile("NexusHub/nexus_logo.png", decode(LOGO_B64))
            end
            if getcustomasset then
                logoAsset = getcustomasset("NexusHub/nexus_logo.png")
            end
        end
    end)

    do
        local FloatBtn = Instance.new("ImageButton")
        FloatBtn.Name = "NexusFloatingBtn"
        FloatBtn.Size = UDim2.new(0, 52, 0, 52)
        FloatBtn.Position = UDim2.new(0.015, 0, 0.25, 0)
        FloatBtn.BackgroundColor3 = Color3.fromRGB(15, 25, 35)
        FloatBtn.BorderSizePixel = 0
        FloatBtn.AutoButtonColor = true
        FloatBtn.Image = logoAsset or ""
        FloatBtn.ScaleType = Enum.ScaleType.Fit
        FloatBtn.ZIndex = 100
        FloatBtn.Visible = not isUiOpen
        FloatBtn.Parent = ScreenGui

        local FloatCorner = Instance.new("UICorner")
        FloatCorner.CornerRadius = UDim.new(0, 12)
        FloatCorner.Parent = FloatBtn

        local FloatStroke = Instance.new("UIStroke")
        FloatStroke.Color = accent
        FloatStroke.Thickness = 1.8
        FloatStroke.Parent = FloatBtn

        if not logoAsset or logoAsset == "" then
            local FallbackLabel = Instance.new("TextLabel")
            FallbackLabel.Name = "FallbackIcon"
            FallbackLabel.Size = UDim2.new(1, 0, 1, 0)
            FallbackLabel.BackgroundTransparency = 1
            FallbackLabel.Text = "⚡"
            FallbackLabel.TextSize = 24
            FallbackLabel.TextColor3 = accent
            FallbackLabel.Font = Enum.Font.GothamBold
            FallbackLabel.ZIndex = 101
            FallbackLabel.Parent = FloatBtn
        end

        FloatBtn.MouseButton1Click:Connect(function()
            toggleUI()
        end)

        -- Smooth Draggable Float Button
        local fDragging, fDragStart, fStartPos = false, nil, nil
        FloatBtn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                fDragging = true
                fDragStart = input.Position
                fStartPos = FloatBtn.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        fDragging = false
                    end
                end)
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if fDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - fDragStart
                local targetPos = UDim2.new(fStartPos.X.Scale, fStartPos.X.Offset + delta.X, fStartPos.Y.Scale, fStartPos.Y.Offset + delta.Y)
                TweenService:Create(FloatBtn, TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = targetPos}):Play()
            end
        end)

        FloatBtn.MouseEnter:Connect(function()
            TweenService:Create(FloatBtn, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0, 56, 0, 56)}):Play()
            TweenService:Create(FloatStroke, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {Color = Color3.fromRGB(180, 245, 255), Thickness = 2.2}):Play()
        end)
        FloatBtn.MouseLeave:Connect(function()
            TweenService:Create(FloatBtn, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0, 52, 0, 52)}):Play()
            TweenService:Create(FloatStroke, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {Color = accent, Thickness = 1.6}):Play()
        end)
    end

    -- คีย์ลัด Toggle เมนู (RightControl / LeftAlt / Insert)
    UserInputService.InputBegan:Connect(function(input, gp)
        if not gp and (input.KeyCode == Enum.KeyCode.RightControl or input.KeyCode == Enum.KeyCode.LeftAlt or input.KeyCode == Enum.KeyCode.Insert) then
            toggleUI()
        end
    end)

    -- Sidebar
    local Sidebar = Instance.new("Frame")
    Sidebar.Name = "Sidebar"
    Sidebar.Size = UDim2.new(0, 150, 1, -54)
    Sidebar.Position = UDim2.new(0, 10, 0, 49)
    Sidebar.BackgroundColor3 = panel
    Sidebar.BorderSizePixel = 0
    Sidebar.Parent = MainFrame
    do
        local SideCorner = Instance.new("UICorner")
        SideCorner.CornerRadius = UDim.new(0, 6)
        SideCorner.Parent = Sidebar

        local SideLayout = Instance.new("UIListLayout")
        SideLayout.Padding = UDim.new(0, 5)
        SideLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        SideLayout.Parent = Sidebar

        local SidePadding = Instance.new("UIPadding")
        SidePadding.PaddingTop = UDim.new(0, 8)
        SidePadding.Parent = Sidebar
    end

    -- Content Container
    local ContentContainer = Instance.new("Frame")
    ContentContainer.Name = "ContentContainer"
    ContentContainer.Size = UDim2.new(1, -180, 1, -54)
    ContentContainer.Position = UDim2.new(0, 170, 0, 49)
    ContentContainer.BackgroundTransparency = 1
    ContentContainer.Parent = MainFrame

    local tabs = {}
    local tabButtons = {}
    local currentTabName = "ฟาร์มอาหารอัตโนมัติ"

    local function createTab(tabName, isDefault)
        local tabBtn = Instance.new("TextButton")
        tabBtn.Text = tabName
        tabBtn.Font = Enum.Font.GothamMedium
        tabBtn.TextSize = 11
        tabBtn.Size = UDim2.new(1, -12, 0, 34)
        tabBtn.BorderSizePixel = 0
        tabBtn.BackgroundColor3 = isDefault and accent or Color3.fromRGB(18, 32, 45)
        tabBtn.TextColor3 = isDefault and Color3.fromRGB(10, 20, 30) or white
        tabBtn.Parent = Sidebar
        local tabCorner = Instance.new("UICorner")
        tabCorner.CornerRadius = UDim.new(0, 5)
        tabCorner.Parent = tabBtn

        local tabContent = Instance.new("ScrollingFrame")
        tabContent.Size = UDim2.new(1, 0, 1, 0)
        tabContent.Position = UDim2.new(0, 0, 0, 0)
        tabContent.BackgroundTransparency = 1
        tabContent.BorderSizePixel = 0
        tabContent.ScrollBarThickness = 4
        tabContent.ScrollBarImageColor3 = accent
        tabContent.ScrollBarImageTransparency = 0.2
        tabContent.ElasticBehavior = Enum.ElasticBehavior.Always
        tabContent.Visible = isDefault
        tabContent.CanvasSize = UDim2.new(0, 0, 0, 1200)
        pcall(function() tabContent.AutomaticCanvasSize = Enum.AutomaticSize.Y end)
        tabContent.Parent = ContentContainer

        local contentLayout = Instance.new("UIListLayout")
        contentLayout.Padding = UDim.new(0, 10)
        contentLayout.Parent = tabContent

        tabs[tabName] = tabContent
        tabButtons[tabName] = tabBtn

        -- Smooth tab hover
        tabBtn.MouseEnter:Connect(function()
            if currentTabName ~= tabName then
                TweenService:Create(tabBtn, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {BackgroundColor3 = Color3.fromRGB(28, 48, 65)}):Play()
            end
        end)
        tabBtn.MouseLeave:Connect(function()
            if currentTabName ~= tabName then
                TweenService:Create(tabBtn, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {BackgroundColor3 = Color3.fromRGB(18, 32, 45)}):Play()
            end
        end)

        tabBtn.MouseButton1Click:Connect(function()
            if currentTabName == tabName then return end
            currentTabName = tabName

            for name, t in pairs(tabs) do
                local b = tabButtons[name]
                if name == tabName then
                    t.Visible = true
                    t.Position = UDim2.new(0, 0, 0, 8)
                    TweenService:Create(t, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 0)}):Play()
                    TweenService:Create(b, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {BackgroundColor3 = accent, TextColor3 = Color3.fromRGB(10, 20, 30)}):Play()
                else
                    t.Visible = false
                    TweenService:Create(b, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {BackgroundColor3 = Color3.fromRGB(18, 32, 45), TextColor3 = white}):Play()
                end
            end
        end)

        return tabContent
    end

    local farmTab = createTab("ฟาร์มอาหาร & แปรรูป", true)
    local fishTab = createTab("ตกปลาอัตโนมัติ", false)
    local mineTab = createTab("ขุดแร่ & คราฟต์", false)
    local setTab = createTab("ตั้งค่าระบบ", false)

    local InvText = nil
    local InvText2 = nil
    local GhostText = nil
    local EatToggle = nil
    local EatVal = nil
    local DrinkToggle = nil
    local DrinkVal = nil
    local ValLabel = nil
    local WalkValLabel = nil

    -- Status Card
    do
        local StatusCard = Instance.new("Frame")
        StatusCard.Size = UDim2.new(1, -10, 0, 105)
        StatusCard.BackgroundColor3 = panel
        StatusCard.BorderSizePixel = 0
        StatusCard.Parent = farmTab
        local StatCorner = Instance.new("UICorner")
        StatCorner.CornerRadius = UDim.new(0, 6)
        StatCorner.Parent = StatusCard
        local StatStroke = Instance.new("UIStroke")
        StatStroke.Color = borderColor
        StatStroke.Parent = StatusCard

        local StatusTitle = Instance.new("TextLabel")
        StatusTitle.Text = "สถานะการทำงาน (ฟาร์มบนดินสมจริง + เคลื่อนที่ใต้ดิน + เข้าคิว)"
        StatusTitle.Font = Enum.Font.GothamBold
        StatusTitle.TextSize = 11
        StatusTitle.TextColor3 = accent
        StatusTitle.Position = UDim2.new(0, 12, 0, 8)
        StatusTitle.Size = UDim2.new(1, -24, 0, 16)
        StatusTitle.TextXAlignment = Enum.TextXAlignment.Left
        StatusTitle.BackgroundTransparency = 1
        StatusTitle.Parent = StatusCard

        local rawStatusText = Instance.new("TextLabel")
        rawStatusText.Name = "StatusText"
        rawStatusText.Text = "สถานะ: พร้อมทำงาน"
        rawStatusText.Font = Enum.Font.Gotham
        rawStatusText.TextSize = 10
        rawStatusText.TextColor3 = white
        rawStatusText.Position = UDim2.new(0, 12, 0, 28)
        rawStatusText.Size = UDim2.new(1, -24, 0, 16)
        rawStatusText.TextXAlignment = Enum.TextXAlignment.Left
        rawStatusText.BackgroundTransparency = 1
        rawStatusText.Parent = StatusCard

        StatusText = setmetatable({}, {
            __index = function(_, k)
                if rawStatusText and rawStatusText.Parent then
                    return rawStatusText[k]
                end
                return nil
            end,
            __newindex = function(_, k, v)
                if rawStatusText and rawStatusText.Parent then
                    pcall(function() rawStatusText[k] = v end)
                end
            end
        })

        InvText = Instance.new("TextLabel")
        InvText.Text = "ขนมปัง: 0/60 | ซอส: 0/60 | หมู: 0/60 | แซนด์วิช: 0"
        InvText.Font = Enum.Font.GothamMedium
        InvText.TextSize = 10
        InvText.TextColor3 = muted
        InvText.Position = UDim2.new(0, 12, 0, 48)
        InvText.Size = UDim2.new(1, -24, 0, 16)
        InvText.TextXAlignment = Enum.TextXAlignment.Left
        InvText.BackgroundTransparency = 1
        InvText.Parent = StatusCard

        InvText2 = Instance.new("TextLabel")
        InvText2.Text = "มะม่วง: 0/60 | ข้าว: 0/60 | กล้วย: 0/60 | ข้าวเหนียว: 0 | ห่อกล้วย: 0"
        InvText2.Font = Enum.Font.GothamMedium
        InvText2.TextSize = 10
        InvText2.TextColor3 = muted
        InvText2.Position = UDim2.new(0, 12, 0, 68)
        InvText2.Size = UDim2.new(1, -24, 0, 16)
        InvText2.TextXAlignment = Enum.TextXAlignment.Left
        InvText2.BackgroundTransparency = 1
        InvText2.Parent = StatusCard

        GhostText = Instance.new("TextLabel")
        GhostText.Text = "ระบบผี: รอเสาฟาร์ม"
        GhostText.Font = Enum.Font.Gotham
        GhostText.TextSize = 10
        GhostText.TextColor3 = accent
        GhostText.Position = UDim2.new(0, 12, 0, 88)
        GhostText.Size = UDim2.new(1, -24, 0, 14)
        GhostText.TextXAlignment = Enum.TextXAlignment.Left
        GhostText.BackgroundTransparency = 1
        GhostText.Parent = StatusCard
    end

    ------------------------------------------------------------------------
    -- AUTO EAT & DRINK CONTROL CARD
    do
        local EatCard = Instance.new("Frame")
        EatCard.Size = UDim2.new(1, -10, 0, 138)
        EatCard.BackgroundColor3 = panel
        EatCard.BorderSizePixel = 0
        EatCard.Parent = farmTab
        local EatCorner = Instance.new("UICorner")
        EatCorner.CornerRadius = UDim.new(0, 6)
        EatCorner.Parent = EatCard
        local EatStroke = Instance.new("UIStroke")
        EatStroke.Color = borderColor
        EatStroke.Parent = EatCard

        local EatTitle = Instance.new("TextLabel")
        EatTitle.Text = "ระบบกินข้าวกินน้ำอัตโนมัติ (Auto Eat & Drink)"
        EatTitle.Font = Enum.Font.GothamBold
        EatTitle.TextSize = 11
        EatTitle.TextColor3 = accent
        EatTitle.Position = UDim2.new(0, 12, 0, 8)
        EatTitle.Size = UDim2.new(1, -24, 0, 16)
        EatTitle.TextXAlignment = Enum.TextXAlignment.Left
        EatTitle.BackgroundTransparency = 1
        EatTitle.Parent = EatCard

        local VitalStatus = Instance.new("TextLabel")
        VitalStatus.Text = "ความหิว: 100% | ความกระหายน้ำ: 100% | ซูชิ: 0 | โกโก้ร้อน: 0"
        VitalStatus.Font = Enum.Font.GothamMedium
        VitalStatus.TextSize = 10
        VitalStatus.TextColor3 = white
        VitalStatus.Position = UDim2.new(0, 12, 0, 26)
        VitalStatus.Size = UDim2.new(1, -24, 0, 16)
        VitalStatus.TextXAlignment = Enum.TextXAlignment.Left
        VitalStatus.BackgroundTransparency = 1
        VitalStatus.Parent = EatCard

        -- Eat Controls Row
        local EatRow = Instance.new("Frame")
        EatRow.Size = UDim2.new(1, -20, 0, 36)
        EatRow.Position = UDim2.new(0, 10, 0, 48)
        EatRow.BackgroundColor3 = Color3.fromRGB(18, 34, 48)
        EatRow.BorderSizePixel = 0
        EatRow.Parent = EatCard
        local EatRowCorner = Instance.new("UICorner")
        EatRowCorner.CornerRadius = UDim.new(0, 4)
        EatRowCorner.Parent = EatRow

        local EatLbl = Instance.new("TextLabel")
        EatLbl.Text = "กินข้าวเมื่อต่ำกว่า:"
        EatLbl.Font = Enum.Font.GothamMedium
        EatLbl.TextSize = 10
        EatLbl.TextColor3 = white
        EatLbl.Position = UDim2.new(0, 10, 0, 0)
        EatLbl.Size = UDim2.new(0, 120, 1, 0)
        EatLbl.TextXAlignment = Enum.TextXAlignment.Left
        EatLbl.BackgroundTransparency = 1
        EatLbl.Parent = EatRow

        local EatDec = Instance.new("TextButton")
        EatDec.Text = "-"
        EatDec.Font = Enum.Font.GothamBold
        EatDec.TextSize = 12
        EatDec.TextColor3 = white
        EatDec.Size = UDim2.new(0, 24, 0, 24)
        EatDec.Position = UDim2.new(0, 130, 0.5, -12)
        EatDec.BackgroundColor3 = Color3.fromRGB(30, 52, 70)
        EatDec.BorderSizePixel = 0
        EatDec.Parent = EatRow
        local EatDecCorner = Instance.new("UICorner")
        EatDecCorner.CornerRadius = UDim.new(0, 4)
        EatDecCorner.Parent = EatDec

        EatVal = Instance.new("TextLabel")
        EatVal.Text = state.eatThreshold .. "%"
        EatVal.Font = Enum.Font.GothamBold
        EatVal.TextSize = 11
        EatVal.TextColor3 = accent
        EatVal.Position = UDim2.new(0, 156, 0, 0)
        EatVal.Size = UDim2.new(0, 45, 1, 0)
        EatVal.BackgroundTransparency = 1
        EatVal.Parent = EatRow

        local EatInc = Instance.new("TextButton")
        EatInc.Text = "+"
        EatInc.Font = Enum.Font.GothamBold
        EatInc.TextSize = 12
        EatInc.TextColor3 = white
        EatInc.Size = UDim2.new(0, 24, 0, 24)
        EatInc.Position = UDim2.new(0, 203, 0.5, -12)
        EatInc.BackgroundColor3 = Color3.fromRGB(30, 52, 70)
        EatInc.BorderSizePixel = 0
        EatInc.Parent = EatRow
        local EatIncCorner = Instance.new("UICorner")
        EatIncCorner.CornerRadius = UDim.new(0, 4)
        EatIncCorner.Parent = EatInc

        makeButtonSmooth(EatDec)
        makeButtonSmooth(EatInc)

        EatDec.MouseButton1Click:Connect(function()
            if state.eatThreshold > 15 then
                state.eatThreshold = state.eatThreshold - 5
                EatVal.Text = state.eatThreshold .. "%"
                -- manual save only (user must click Save Now)
            end
        end)
        EatInc.MouseButton1Click:Connect(function()
            if state.eatThreshold < 90 then
                state.eatThreshold = state.eatThreshold + 5
                EatVal.Text = state.eatThreshold .. "%"
                -- manual save only (user must click Save Now)
            end
        end)

        EatToggle = Instance.new("TextButton")
        EatToggle.Text = state.autoEat and "เปิด" or "ปิด"
        EatToggle.Font = Enum.Font.GothamBold
        EatToggle.TextSize = 10
        EatToggle.TextColor3 = state.autoEat and Color3.fromRGB(10, 20, 30) or white
        EatToggle.BackgroundColor3 = state.autoEat and accent or Color3.fromRGB(45, 60, 75)
        EatToggle.Size = UDim2.new(0, 46, 0, 24)
        EatToggle.Position = UDim2.new(1, -54, 0.5, -12)
        EatToggle.BorderSizePixel = 0
        EatToggle.Parent = EatRow
        local ETCorner = Instance.new("UICorner")
        ETCorner.CornerRadius = UDim.new(0, 4)
        ETCorner.Parent = EatToggle

        EatToggle.MouseButton1Click:Connect(function()
            state.autoEat = not state.autoEat
            animateButtonToggle(EatToggle, state.autoEat, "เปิด", "ปิด")
            -- manual save only (user must click Save Now)
        end)

        -- Drink Controls Row
        local DrinkRow = Instance.new("Frame")
        DrinkRow.Size = UDim2.new(1, -20, 0, 36)
        DrinkRow.Position = UDim2.new(0, 10, 0, 90)
        DrinkRow.BackgroundColor3 = Color3.fromRGB(18, 34, 48)
        DrinkRow.BorderSizePixel = 0
        DrinkRow.Parent = EatCard
        local DrinkRowCorner = Instance.new("UICorner")
        DrinkRowCorner.CornerRadius = UDim.new(0, 4)
        DrinkRowCorner.Parent = DrinkRow

        local DrinkLbl = Instance.new("TextLabel")
        DrinkLbl.Text = "กินน้ำเมื่อต่ำกว่า:"
        DrinkLbl.Font = Enum.Font.GothamMedium
        DrinkLbl.TextSize = 10
        DrinkLbl.TextColor3 = white
        DrinkLbl.Position = UDim2.new(0, 10, 0, 0)
        DrinkLbl.Size = UDim2.new(0, 120, 1, 0)
        DrinkLbl.TextXAlignment = Enum.TextXAlignment.Left
        DrinkLbl.BackgroundTransparency = 1
        DrinkLbl.Parent = DrinkRow

        local DrinkDec = Instance.new("TextButton")
        DrinkDec.Text = "-"
        DrinkDec.Font = Enum.Font.GothamBold
        DrinkDec.TextSize = 12
        DrinkDec.TextColor3 = white
        DrinkDec.Size = UDim2.new(0, 24, 0, 24)
        DrinkDec.Position = UDim2.new(0, 130, 0.5, -12)
        DrinkDec.BackgroundColor3 = Color3.fromRGB(30, 52, 70)
        DrinkDec.BorderSizePixel = 0
        DrinkDec.Parent = DrinkRow
        local DrinkDecCorner = Instance.new("UICorner")
        DrinkDecCorner.CornerRadius = UDim.new(0, 4)
        DrinkDecCorner.Parent = DrinkDec

        DrinkVal = Instance.new("TextLabel")
        DrinkVal.Text = state.drinkThreshold .. "%"
        DrinkVal.Font = Enum.Font.GothamBold
        DrinkVal.TextSize = 11
        DrinkVal.TextColor3 = accent
        DrinkVal.Position = UDim2.new(0, 156, 0, 0)
        DrinkVal.Size = UDim2.new(0, 45, 1, 0)
        DrinkVal.BackgroundTransparency = 1
        DrinkVal.Parent = DrinkRow

        local DrinkInc = Instance.new("TextButton")
        DrinkInc.Text = "+"
        DrinkInc.Font = Enum.Font.GothamBold
        DrinkInc.TextSize = 12
        DrinkInc.TextColor3 = white
        DrinkInc.Size = UDim2.new(0, 24, 0, 24)
        DrinkInc.Position = UDim2.new(0, 203, 0.5, -12)
        DrinkInc.BackgroundColor3 = Color3.fromRGB(30, 52, 70)
        DrinkInc.BorderSizePixel = 0
        DrinkInc.Parent = DrinkRow
        local DrinkIncCorner = Instance.new("UICorner")
        DrinkIncCorner.CornerRadius = UDim.new(0, 4)
        DrinkIncCorner.Parent = DrinkInc

        makeButtonSmooth(DrinkDec)
        makeButtonSmooth(DrinkInc)

        DrinkDec.MouseButton1Click:Connect(function()
            if state.drinkThreshold > 15 then
                state.drinkThreshold = state.drinkThreshold - 5
                DrinkVal.Text = state.drinkThreshold .. "%"
                -- manual save only (user must click Save Now)
            end
        end)
        DrinkInc.MouseButton1Click:Connect(function()
            if state.drinkThreshold < 90 then
                state.drinkThreshold = state.drinkThreshold + 5
                DrinkVal.Text = state.drinkThreshold .. "%"
                -- manual save only (user must click Save Now)
            end
        end)

        DrinkToggle = Instance.new("TextButton")
        DrinkToggle.Text = state.autoDrink and "เปิด" or "ปิด"
        DrinkToggle.Font = Enum.Font.GothamBold
        DrinkToggle.TextSize = 10
        DrinkToggle.TextColor3 = state.autoDrink and Color3.fromRGB(10, 20, 30) or white
        DrinkToggle.BackgroundColor3 = state.autoDrink and accent or Color3.fromRGB(45, 60, 75)
        DrinkToggle.Size = UDim2.new(0, 46, 0, 24)
        DrinkToggle.Position = UDim2.new(1, -54, 0.5, -12)
        DrinkToggle.BorderSizePixel = 0
        DrinkToggle.Parent = DrinkRow
        local DTCorner = Instance.new("UICorner")
        DTCorner.CornerRadius = UDim.new(0, 4)
        DTCorner.Parent = DrinkToggle

        DrinkToggle.MouseButton1Click:Connect(function()
            state.autoDrink = not state.autoDrink
            animateButtonToggle(DrinkToggle, state.autoDrink, "เปิด", "ปิด")
            -- manual save only (user must click Save Now)
        end)

        -- Update Vital Status text
        task.spawn(function()
            while myToken.running do
                pcall(function()
                    local curHunger, curBrain = getVitalStats()
                    local pData = LocalPlayer:FindFirstChild("PlayerData")
                    local su = pData and pData:GetAttribute("Sushi") or 0
                    local co = pData and pData:GetAttribute("HotCocoa") or 0
                    VitalStatus.Text = string.format("ความหิว: %d%% | ความกระหาย: %d%% | ซูชิ: %d | โกโก้: %d", math.floor(curHunger), math.floor(curBrain), su, co)
                end)
                task.wait(1)
            end
        end)
    end

    -- Underground Depth Setting Stepper Card
    do
        local DepthCard = Instance.new("Frame")
        DepthCard.Size = UDim2.new(1, -10, 0, 44)
        DepthCard.BackgroundColor3 = panel
        DepthCard.BorderSizePixel = 0
        DepthCard.Parent = farmTab
        local DepthCorner = Instance.new("UICorner")
        DepthCorner.CornerRadius = UDim.new(0, 6)
        DepthCorner.Parent = DepthCard
        local DepthStroke = Instance.new("UIStroke")
        DepthStroke.Color = borderColor
        DepthStroke.Parent = DepthCard

        local DepthLabel = Instance.new("TextLabel")
        DepthLabel.Text = "ความเร็วเคลื่อนที่ใต้ดิน (Travel Speed)"
        DepthLabel.Font = Enum.Font.GothamMedium
        DepthLabel.TextSize = 11
        DepthLabel.TextColor3 = white
        DepthLabel.Position = UDim2.new(0, 12, 0, 0)
        DepthLabel.Size = UDim2.new(1, -165, 1, 0)
        DepthLabel.TextXAlignment = Enum.TextXAlignment.Left
        DepthLabel.BackgroundTransparency = 1
        DepthLabel.Parent = DepthCard

        local DecBtn = Instance.new("TextButton")
        DecBtn.Text = "-"
        DecBtn.Font = Enum.Font.GothamBold
        DecBtn.TextSize = 14
        DecBtn.TextColor3 = white
        DecBtn.Size = UDim2.new(0, 28, 0, 26)
        DecBtn.Position = UDim2.new(1, -145, 0.5, -13)
        DecBtn.BackgroundColor3 = Color3.fromRGB(30, 52, 70)
        DecBtn.BorderSizePixel = 0
        DecBtn.Parent = DepthCard
        local DecCorner = Instance.new("UICorner")
        DecCorner.CornerRadius = UDim.new(0, 4)
        DecCorner.Parent = DecBtn

        ValLabel = Instance.new("TextLabel")
        ValLabel.Text = state.moveSpeed .. " studs/s"
        ValLabel.Font = Enum.Font.GothamBold
        ValLabel.TextSize = 11
        ValLabel.TextColor3 = accent
        ValLabel.Size = UDim2.new(0, 80, 1, 0)
        ValLabel.Position = UDim2.new(1, -115, 0, 0)
        ValLabel.BackgroundTransparency = 1
        ValLabel.Parent = DepthCard

        local IncBtn = Instance.new("TextButton")
        IncBtn.Text = "+"
        IncBtn.Font = Enum.Font.GothamBold
        IncBtn.TextSize = 14
        IncBtn.TextColor3 = white
        IncBtn.Size = UDim2.new(0, 28, 0, 26)
        IncBtn.Position = UDim2.new(1, -34, 0.5, -13)
        IncBtn.BackgroundColor3 = Color3.fromRGB(30, 52, 70)
        IncBtn.BorderSizePixel = 0
        IncBtn.Parent = DepthCard
        local IncCorner = Instance.new("UICorner")
        IncCorner.CornerRadius = UDim.new(0, 4)
        IncCorner.Parent = IncBtn

        makeButtonSmooth(DecBtn)
        makeButtonSmooth(IncBtn)

        DecBtn.MouseButton1Click:Connect(function()
            if state.moveSpeed > 30.0 then
                state.moveSpeed = math.max(30.0, state.moveSpeed - 10.0)
                ValLabel.Text = state.moveSpeed .. " studs/s"
                -- manual save only (user must click Save Now)
            end
        end)

        IncBtn.MouseButton1Click:Connect(function()
            if state.moveSpeed < 300.0 then
                state.moveSpeed = math.min(300.0, state.moveSpeed + 10.0)
                ValLabel.Text = state.moveSpeed .. " studs/s"
                -- manual save only (user must click Save Now)
            end
        end)
    end

    -- Walk-in Distance Setting Stepper Card (ระยะโผล่ขึ้นมานอกวงเพื่อเดินเท้าเข้าสู่ฟาร์ม)
    do
        local WalkCard = Instance.new("Frame")
        WalkCard.Size = UDim2.new(1, -10, 0, 44)
        WalkCard.BackgroundColor3 = panel
        WalkCard.BorderSizePixel = 0
        WalkCard.Parent = farmTab
        local WalkCorner = Instance.new("UICorner")
        WalkCorner.CornerRadius = UDim.new(0, 6)
        WalkCorner.Parent = WalkCard
        local WalkStroke = Instance.new("UIStroke")
        WalkStroke.Color = borderColor
        WalkStroke.Parent = WalkCard

        local WalkLabel = Instance.new("TextLabel")
        WalkLabel.Text = "ระยะเดินเท้าเข้าฟาร์ม (Walk-in Dist)"
        WalkLabel.Font = Enum.Font.GothamMedium
        WalkLabel.TextSize = 11
        WalkLabel.TextColor3 = white
        WalkLabel.Position = UDim2.new(0, 12, 0, 0)
        WalkLabel.Size = UDim2.new(1, -165, 1, 0)
        WalkLabel.TextXAlignment = Enum.TextXAlignment.Left
        WalkLabel.BackgroundTransparency = 1
        WalkLabel.Parent = WalkCard

        local WalkDecBtn = Instance.new("TextButton")
        WalkDecBtn.Text = "-"
        WalkDecBtn.Font = Enum.Font.GothamBold
        WalkDecBtn.TextSize = 14
        WalkDecBtn.TextColor3 = white
        WalkDecBtn.Size = UDim2.new(0, 28, 0, 26)
        WalkDecBtn.Position = UDim2.new(1, -145, 0.5, -13)
        WalkDecBtn.BackgroundColor3 = Color3.fromRGB(30, 52, 70)
        WalkDecBtn.BorderSizePixel = 0
        WalkDecBtn.Parent = WalkCard
        local WDecCorner = Instance.new("UICorner")
        WDecCorner.CornerRadius = UDim.new(0, 4)
        WDecCorner.Parent = WalkDecBtn

        WalkValLabel = Instance.new("TextLabel")
        WalkValLabel.Text = (state.walkInDistance or 100.0) .. " studs"
        WalkValLabel.Font = Enum.Font.GothamBold
        WalkValLabel.TextSize = 11
        WalkValLabel.TextColor3 = accent
        WalkValLabel.Size = UDim2.new(0, 80, 1, 0)
        WalkValLabel.Position = UDim2.new(1, -115, 0, 0)
        WalkValLabel.BackgroundTransparency = 1
        WalkValLabel.Parent = WalkCard

        local WalkIncBtn = Instance.new("TextButton")
        WalkIncBtn.Text = "+"
        WalkIncBtn.Font = Enum.Font.GothamBold
        WalkIncBtn.TextSize = 14
        WalkIncBtn.TextColor3 = white
        WalkIncBtn.Size = UDim2.new(0, 28, 0, 26)
        WalkIncBtn.Position = UDim2.new(1, -34, 0.5, -13)
        WalkIncBtn.BackgroundColor3 = Color3.fromRGB(30, 52, 70)
        WalkIncBtn.BorderSizePixel = 0
        WalkIncBtn.Parent = WalkCard
        local WIncCorner = Instance.new("UICorner")
        WIncCorner.CornerRadius = UDim.new(0, 4)
        WIncCorner.Parent = WalkIncBtn

        makeButtonSmooth(WalkDecBtn)
        makeButtonSmooth(WalkIncBtn)

        WalkDecBtn.MouseButton1Click:Connect(function()
            local cur = state.walkInDistance or 100.0
            if cur > 10.0 then
                state.walkInDistance = math.max(10.0, cur - 5.0)
                WalkValLabel.Text = state.walkInDistance .. " studs"
                -- manual save only (user must click Save Now)
            end
        end)

        WalkIncBtn.MouseButton1Click:Connect(function()
            local cur = state.walkInDistance or 100.0
            if cur < 150.0 then
                state.walkInDistance = math.min(150.0, cur + 5.0)
                WalkValLabel.Text = state.walkInDistance .. " studs"
                -- manual save only (user must click Save Now)
            end
        end)
    end

    -- Real-time Inventory Monitor
    task.spawn(function()
        while myToken.running do
            pcall(function()
                local pData = LocalPlayer:FindFirstChild("PlayerData")
                if pData then
                    local b = pData:GetAttribute("Bread") or 0
                    local c = pData:GetAttribute("Catchup") or 0
                    local p = pData:GetAttribute("Pig") or 0
                    local m = pData:GetAttribute("Mango") or 0
                    local r = pData:GetAttribute("Rice") or 0
                    local bn = pData:GetAttribute("Banana") or 0
                    local bnp = pData:GetAttribute("BananaPack") or 0
                    local sw = pData:GetAttribute("Sandwish") or 0
                    local mr = pData:GetAttribute("MangoRice") or 0
                    InvText.Text = string.format("ขนมปัง: %d | ซอส: %d | หมู: %d | แซนด์วิช: %d", b, c, p, sw)
                    InvText2.Text = string.format("มะม่วง: %d | ข้าว: %d | กล้วย: %d | ข้าวเหนียว: %d | ห่อกล้วย: %d", m, r, bn, mr, bnp)

                    if FishCountText then
                        local betta = pData:GetAttribute("Bettafish") or 0
                        local angler = pData:GetAttribute("Anglerfish") or 0
                        local sardine = pData:GetAttribute("Sardine") or 0
                        local totalFish = betta + angler + sardine
                        FishCountText.Text = string.format("ปลากัด: %d | แองเกลอร์: %d | ซาร์ดีน: %d (รวม: %d/25 ตัว)", betta, angler, sardine, totalFish)
                    end

                    if RodStatusText then
                        local r3 = pData:GetAttribute("FishingRodV3") or 0
                        local r2 = pData:GetAttribute("FishingRodV2") or 0
                        local r1 = pData:GetAttribute("FishingRod") or 0
                        if r3 > 0 then
                            RodStatusText.Text = "เบ็ดตกปลา: เบ็ดระดับสูงสุด (FishingRodV3) พร้อมใช้งาน"
                        elseif r2 > 0 then
                            RodStatusText.Text = "เบ็ดตกปลา: เบ็ดระดับกลาง (FishingRodV2) พร้อมใช้งาน"
                        elseif r1 > 0 then
                            RodStatusText.Text = "เบ็ดตกปลา: เบ็ดมาตรฐาน (FishingRod) พร้อมใช้งาน"
                        else
                            RodStatusText.Text = "เบ็ดตกปลา: ยังไม่มีเบ็ด (ระบบจะบินไปซื้อที่ Shop ให้อัตโนมัติ)"
                        end
                    end
                end
                local pig = workspace:FindFirstChild("_LocalFarmPig")
                if pig and pig.PrimaryPart then
                    GhostText.Text = string.format("ระบบผี: ออนไลน์บนดิน (Y=%.1f)", pig.PrimaryPart.Position.Y)
                else
                    GhostText.Text = "ระบบผี: ไม่ได้ทำงาน"
                end
            end)
            task.wait(0.5)
        end
    end)

    -- HELPER: Wait for streamed instances/prompts to load
    local function waitForPrompt(getter, timeout)
        timeout = timeout or 4.5
        local t0 = os.clock()
        while os.clock() - t0 < timeout do
            local p = getter()
            if p then return p end
            task.wait(0.2)
        end
        return getter()
    end

    -- RESTORE CHARACTER VISIBILITY (Strictly ensures character parts are 100% visible and never invisible)
    local function restoreCharacterVisibility()
        local char = LocalPlayer.Character
        if not char then return end
        for _, v in ipairs(char:GetDescendants()) do
            if v.Name == "Mic" or v.Name == "Circle" or (v.Parent and (v.Parent.Name == "Mic" or v.Parent.Name == "Circle")) then
                pcall(function() v:Destroy() end)
            elseif v:IsA("BasePart") or v:IsA("Decal") then
                local orig = v:GetAttribute("OrigTrans")
                if orig ~= nil then
                    v.Transparency = orig
                    v:SetAttribute("OrigTrans", nil)
                elseif v.Name ~= "HumanoidRootPart" and (v:IsA("MeshPart") or (v:IsA("Part") and v.Parent and v.Parent:IsA("Accessory"))) then
                    v.Transparency = 0
                end
            elseif v:IsA("BillboardGui") or v:IsA("Highlight") then
                local orig = v:GetAttribute("OrigEnabled")
                if orig ~= nil then
                    v.Enabled = orig
                    v:SetAttribute("OrigEnabled", nil)
                else
                    v.Enabled = true
                end
            end
        end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.Transparency = 1 end
    end
    local function setCharacterGhost(enabled)
        -- Always restore visibility (never turn character invisible)
        restoreCharacterVisibility()
    end
    table.insert(_G.NexusConnections, LocalPlayer.CharacterAdded:Connect(function()
        task.wait(0.5)
        restoreCharacterVisibility()
    end))
    restoreCharacterVisibility()

    -- =========================================================================
    -- [ NATURAL SURFACE FARMING, SMART QUEUE & STEALTH APPROACH SYSTEM ]
    -- =========================================================================

    -- 1. Helper: Detect other players within radius
    local function getNearbyPlayers(pos, radius)
        local nearby = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                local pRoot = plr.Character.HumanoidRootPart
                local dist = (pRoot.Position - pos).Magnitude
                if dist <= radius then
                    table.insert(nearby, plr)
                end
            end
        end
        return nearby
    end

    -- 2. Helper: Natural surface walking with Humanoid:MoveTo
    local function naturalWalkTo(targetPos, timeout)
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChild("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not hum or not root then return false end

        hum.PlatformStand = false
        root.Anchored = false
        pcall(function() hum:ChangeState(Enum.HumanoidStateType.Running) end)

        hum:MoveTo(targetPos)
        local t0 = os.clock()
        timeout = timeout or 12.0
        local lastPos = root.Position
        local lastProgressTime = os.clock()

        while (root.Position - targetPos).Magnitude > 3.5 and (os.clock() - t0) < timeout do
            if state.stopRequested and not state.isManualAction then break end

            -- Re-issue MoveTo so humanoid keeps walking seamlessly
            hum:MoveTo(targetPos)

            -- Anti-stuck jump if obstructed by small fence/rock
            local moved = (root.Position - lastPos).Magnitude
            if moved > 0.8 then
                lastProgressTime = os.clock()
                lastPos = root.Position
            else
                if (os.clock() - lastProgressTime) > 1.2 then
                    pcall(function() hum.Jump = true end)
                    lastProgressTime = os.clock()
                end
            end

            task.wait(0.2)
        end
        return (root.Position - targetPos).Magnitude <= 4.0
    end

    -- 3. Helper: Smart Queue - Wait for other player to finish using station (Crafting/Selling/Shop)
    local function waitForStationClear(stationPos, stationName)
        -- Station queue check (non-blocking for seamless auto-farming)
        local checkRadius = 6
        local nearby = getNearbyPlayers(stationPos, checkRadius)
        if #nearby == 0 then return true end

        local occupier = nearby[1]
        local name = occupier.DisplayName or occupier.Name
        StatusText.Text = string.format("มีผู้เล่น (%s) อยู่ใกล้%s... เตรียมพร้อมเข้าใช้งาน", name, stationName or "โต๊ะ")
        task.wait(0.5)
        return true
    end


    -- 4. Underground Travel with Smooth Natural Speed and Stealth Approach
    local function travelToSurface(destPos, speedOverride, depthOverride)
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChild("Humanoid")
        if not root or not hum then return end
        if isAtServerSelectionScreen() then
            return
        end

        restoreCharacterVisibility()
        state.isFlying = true

        -- Request stream around destination
        pcall(function()
            LocalPlayer:RequestStreamAroundAsync(destPos, 4)
        end)

        local destGround, _ = getGroundAt(destPos.X, destPos.Z, destPos.Y)
        destGround = destGround or (destPos.Y - 2.5)

        -- Determine if destination itself is an underground location (e.g. Safe Vault)
        local isDestUnderground = (destPos.Y < destGround - 4.5)
        local finalTargetPos
        if isDestUnderground then
            finalTargetPos = destPos
        else
            finalTargetPos = Vector3.new(destPos.X, destGround + 3.2, destPos.Z)
        end

        local startPos = root.Position
        local horizontalDist = (Vector3.new(finalTargetPos.X, 0, finalTargetPos.Z) - Vector3.new(startPos.X, 0, startPos.Z)).Magnitude

        local targetArrival = finalTargetPos
        local shouldWalkIn = false

        -- If very close (under 20 studs) and already on surface: walk naturally directly to destination
        if horizontalDist <= 20 and not isDestUnderground and (startPos.Y >= (destGround - 2)) then
            hum.PlatformStand = false
            root.Anchored = false
            pcall(function() hum:ChangeState(Enum.HumanoidStateType.Running) end)
            naturalWalkTo(finalTargetPos, (horizontalDist / 16) + 1.2)
        else
            -- Standoff Approach: ทุกฟาร์ม (Bread, Catchup, Pig, Mango, Rice, Banana, Rock, Svibranium)
            -- บินมุดใต้ดินไปโผล่ที่ขอบวง (ระยะปลอดภัย 11 studs) แล้วเดินเท้าเข้าสู่วงฟาร์มตรงจุดอย่างแม่นยำ
            local isFarmDestination = false
            for _, fPos in ipairs({
                FARM_COORDS.Bread,
                FARM_COORDS.Catchup,
                FARM_COORDS.Pig,
                FARM_COORDS.Mango,
                FARM_COORDS.Rice,
                FARM_COORDS.Banana,
                FARM_COORDS.Rock,
                FARM_COORDS.Svibranium
            }) do
                if (destPos - fPos).Magnitude < 15 then
                    isFarmDestination = true
                    break
                end
            end

            local targetStandoff = state.walkInDistance or 100.0
            if isFarmDestination and not isDestUnderground and horizontalDist > (targetStandoff + 5.0) then
                local diff = (startPos - finalTargetPos)
                local approachDir = diff.Magnitude > 1 and Vector3.new(diff.X, 0, diff.Z).Unit or Vector3.new(0, 0, 1)

                -- ค้นหาระยะไกลที่ปลอดภัย (100 studs) นอกวงฟาร์ม เพื่อให้ตัวละครโผล่ขึ้นมาจากใต้ดินไกลตาคนแล้วเดินเท้าเข้าสู่วง
                local chosenPoint = nil
                for testDist = targetStandoff, 18.0, -3.0 do
                    local pt = finalTargetPos + (approachDir * testDist)
                    local ogY, hitInst = getGroundAt(pt.X, pt.Z, finalTargetPos.Y)
                    if ogY and ogY > 11.5 and math.abs(ogY - (destGround or ogY)) <= 12.0 then
                        chosenPoint = Vector3.new(pt.X, ogY + 3.2, pt.Z)
                        break
                    end
                end

                -- หากทิศทางหลักติดน้ำหรือหน้าผา ให้สแกนมุมเยื้อง (+/- 25, +/- 45 องศา)
                if not chosenPoint then
                    for _, angleDeg in ipairs({25, -25, 45, -45}) do
                        local rad = math.rad(angleDeg)
                        local cosA, sinA = math.cos(rad), math.sin(rad)
                        local altDir = Vector3.new(
                            approachDir.X * cosA - approachDir.Z * sinA,
                            0,
                            approachDir.X * sinA + approachDir.Z * cosA
                        ).Unit
                        for testDist = targetStandoff, 18.0, -5.0 do
                            local pt = finalTargetPos + (altDir * testDist)
                            local ogY, hitInst = getGroundAt(pt.X, pt.Z, finalTargetPos.Y)
                            if ogY and ogY > 11.5 and math.abs(ogY - (destGround or ogY)) <= 12.0 then
                                chosenPoint = Vector3.new(pt.X, ogY + 3.2, pt.Z)
                                break
                            end
                        end
                        if chosenPoint then break end
                    end
                end

                if chosenPoint then
                    shouldWalkIn = true
                    targetArrival = chosenPoint
                else
                    targetArrival = finalTargetPos
                end
            end
            -- 3-Phase 100% Underground Stealth Travel (แตะน้ำน้อยที่สุด และไม่โผล่บนดินเด็ดขาด)
            hum.PlatformStand = true
            root.Anchored = false

            local currentSpeed = (type(speedOverride) == "number" and speedOverride) or state.moveSpeed or 160.0
            currentSpeed = math.clamp(currentSpeed, 30.0, 300.0)

            local startGround, _ = getGroundAt(startPos.X, startPos.Z, startPos.Y)
            startGround = startGround or (startPos.Y - 3.2)

            -- Function to calculate safe underground or under-bridge Y
            -- Water level across the map is at Y = 10.4.
            -- BRIDGE CROSSING: When crossing an elevated bridge / road over water, fly strictly UNDER the bridge deck (Y = 12.0)
            --   so players and cars on the bridge cannot see the character at all.
            -- SOLID LAND: Fly strictly underground (ground >= 19.0 with no air gap): Y = math.clamp(ground - 6.0, 14.0, ground - 4.5)
            -- OVER WATER: Y = 7.5 (submerged under water surface to stay hidden)
            local lastWasBridge = false
            local function getSafeUndergroundY(x, z, hintGround)
                local gY, _ = getGroundAt(x, z, hintGround)
                local isBridge = false

                if gY and gY >= 18.0 then
                    -- Detect if surface is an elevated bridge/road by checking for open air clearance underneath the deck
                    local underRay = workspace:Raycast(Vector3.new(x, gY - 2.5, z), Vector3.new(0, -35.0, 0), rayParams)
                    if not underRay or (gY - underRay.Position.Y) > 5.5 then
                        isBridge = true
                    end
                end

                -- Also detect the central river/bridge corridor (X between 400 and 2200) when gY is elevated or streamed out
                if not isBridge and (x > 400 and x < 2200) then
                    if (gY and gY >= 18.0) or (not gY and (hintGround and hintGround >= 18.0)) then
                        isBridge = true
                    end
                end

                lastWasBridge = isBridge

                -- 1. Bridge Crossing: ALWAYS fly under the bridge deck
                if isBridge then
                    return 12.0
                end

                -- 2. Streamed out / missing ground over water
                if not gY then
                    if x > 400 and x < 2200 then
                        return 12.0
                    end
                    local fb = hintGround or 20.0
                    if fb >= 19.0 then
                        return math.clamp(fb - 6.0, 14.0, fb - 4.5)
                    else
                        return 7.5
                    end
                end

                -- 3. Solid Land: Stay underground
                if gY >= 19.0 then
                    return math.clamp(gY - 6.0, 14.0, gY - 4.5)
                else
                    return 7.5
                end
            end

            -- PHASE 1: In-Place Vertical Dive (จมลงใต้ดินทันทีก่อนเคลื่อนที่ในแนวราบ ห้ามโผล่บนดินเด็ดขาด)
            local isStartUnderground = (startPos.Y <= startGround - 4.5)
            local currentTravelY = startPos.Y

            if not isStartUnderground then
                StatusText.Text = "กำลังมุดลงใต้ดิน ณ จุดเดิม..."
                local targetDiveY = getSafeUndergroundY(startPos.X, startPos.Z, startGround)
                local diveSteps = 5
                for i = 1, diveSteps do
                    if state.stopRequested and not state.isManualAction then break end
                    local frac = i / diveSteps
                    currentTravelY = startPos.Y + (targetDiveY - startPos.Y) * frac
                    root.CFrame = CFrame.new(startPos.X, currentTravelY, startPos.Z)
                    root.AssemblyLinearVelocity = Vector3.zero
                    root.AssemblyAngularVelocity = Vector3.zero
                    task.wait(0.025)
                end
                currentTravelY = targetDiveY
            else
                currentTravelY = getSafeUndergroundY(startPos.X, startPos.Z, startGround)
            end

            -- PHASE 2: Multi-Segment 100% Underground & Stealth Bridge Route Transit
            -- ตรวจจับการข้ามฝั่งระหว่างเกาะฝั่งตะวันตก (X < -50) และฝั่งเมือง/เศรษฐกิจฝั่งตะวันออก (X > 500)
            local isCrossingWestToEast = (startPos.X < -50 and targetArrival.X > 500)
            local isCrossingEastToWest = (startPos.X > 500 and targetArrival.X < -50)
            local isCrossingRiver = isCrossingWestToEast or isCrossingEastToWest

            local waypoints = {}
            if isCrossingRiver then
                -- รายการสะพานข้ามแม่น้ำหลัก
                -- South Bridge (Z = 3365.0): สะพานหลักทางหลวงใต้จากรูปผู้ใช้ เชื่อมโซนเศรษฐกิจและฟาร์มตรงๆ
                -- Middle Bridge (Z = 3676.0): สะพานกลางทางหลวง อยู่ใกล้ฟาร์มขนมปัง
                local BRIDGES = {
                    South = {
                        name = "สะพานหลักทางหลวงใต้",
                        Z = 3365.0,
                        west = Vector3.new(-450.0, 12.0, 3365.0),
                        east = Vector3.new(650.0, 12.0, 3365.0)
                    },
                    Middle = {
                        name = "สะพานกลาง",
                        Z = 3676.0,
                        west = Vector3.new(-450.0, 12.0, 3676.0),
                        east = Vector3.new(650.0, 12.0, 3676.0)
                    }
                }

                -- เลือกสะพานที่ระยะทางรวมสั้นที่สุด
                local costSouth = (Vector3.new(startPos.X, 0, startPos.Z) - (isCrossingWestToEast and BRIDGES.South.west or BRIDGES.South.east)).Magnitude
                                + (Vector3.new(targetArrival.X, 0, targetArrival.Z) - (isCrossingWestToEast and BRIDGES.South.east or BRIDGES.South.west)).Magnitude
                local costMid = (Vector3.new(startPos.X, 0, startPos.Z) - (isCrossingWestToEast and BRIDGES.Middle.west or BRIDGES.Middle.east)).Magnitude
                              + (Vector3.new(targetArrival.X, 0, targetArrival.Z) - (isCrossingWestToEast and BRIDGES.Middle.east or BRIDGES.Middle.west)).Magnitude

                local chosenBridge = BRIDGES.South
                if costMid < costSouth - 300 then
                    chosenBridge = BRIDGES.Middle
                end

                if isCrossingWestToEast then
                    table.insert(waypoints, { pos = chosenBridge.west, isBridge = false, desc = "มุดใต้ดินมุ่งหน้าสู่หัวสะพาน" })
                    table.insert(waypoints, { pos = chosenBridge.east, isBridge = true, desc = "กำลังบินใต้สะพานข้ามฝั่ง เพื่อหลบสายตาคน (เนียน 100%)" })
                    table.insert(waypoints, { pos = targetArrival, isBridge = false, desc = "มุดใต้ดินมุ่งหน้าสู่จุดหมายปลายทาง" })
                else
                    table.insert(waypoints, { pos = chosenBridge.east, isBridge = false, desc = "มุดใต้ดินมุ่งหน้าสู่หัวสะพาน" })
                    table.insert(waypoints, { pos = chosenBridge.west, isBridge = true, desc = "กำลังบินใต้สะพานข้ามฝั่ง เพื่อหลบสายตาคน (เนียน 100%)" })
                    table.insert(waypoints, { pos = targetArrival, isBridge = false, desc = "มุดใต้ดินมุ่งหน้าสู่จุดหมายปลายทาง" })
                end
            else
                table.insert(waypoints, { pos = targetArrival, isBridge = false, desc = "กำลังเคลื่อนที่ใต้ดิน" })
            end

            -- เคลื่อนที่ทีละ Segment อย่างนุ่มนวล แม่นยำ และปลอดภัย
            local currentPos = Vector3.new(startPos.X, currentTravelY, startPos.Z)
            for segIdx, wp in ipairs(waypoints) do
                if state.stopRequested and not state.isManualAction then break end
                if not myToken.running then break end

                local segStart = currentPos
                local segTarget = wp.pos
                local isFinalLeg = (segIdx == #waypoints)
                local legDist = (Vector3.new(segTarget.X, 0, segTarget.Z) - Vector3.new(segStart.X, 0, segStart.Z)).Magnitude

                if legDist > 2.0 then
                    local legTime = math.max(0.1, legDist / currentSpeed)
                    local legStartTime = os.clock()

                    while myToken.running do
                        if state.stopRequested and not state.isManualAction then break end
                        local elapsed = os.clock() - legStartTime
                        local alpha = math.clamp(elapsed / legTime, 0, 1)

                        local curX = segStart.X + (segTarget.X - segStart.X) * alpha
                        local curZ = segStart.Z + (segTarget.Z - segStart.Z) * alpha

                        local targetY
                        if wp.isBridge then
                            -- บินใต้สะพานเด็ดขาด (Y = 12.0) แผ่นสะพานหนาบังมิดชิดจากเบื้องบน 100%
                            targetY = 12.0
                        elseif isFinalLeg and targetArrival.Y > 60.0 and alpha >= 0.70 then
                            -- เฉพาะกรณีจุดหมายอยู่บนอาคารสูง (เช่น เตาหลอม Y = 154) จึงให้ค่อยๆ ไต่ระดับขึ้นสู่พื้นอาคาร
                            local riseAlpha = (alpha - 0.70) / 0.30
                            local approxGround = startGround + (destGround - startGround) * alpha
                            local baseTravelY = getSafeUndergroundY(curX, curZ, approxGround)
                            targetY = baseTravelY + (targetArrival.Y - baseTravelY) * riseAlpha
                        else
                            -- ฟาร์มทั้งหมดบนพื้นดิน: บินใต้ดิน 100% ตลอดเส้นทาง ไม่โผล่บินบนฟ้าเด็ดขาด
                            local approxGround = startGround + (destGround - startGround) * alpha
                            targetY = getSafeUndergroundY(curX, curZ, approxGround)
                        end

                        currentTravelY = currentTravelY + math.clamp(targetY - currentTravelY, -3.5, 3.5)
                        currentPos = Vector3.new(curX, currentTravelY, curZ)

                        local lookDir = (segTarget - currentPos)
                        if lookDir.Magnitude > 0.5 then
                            root.CFrame = CFrame.new(currentPos, currentPos + Vector3.new(lookDir.X, 0, lookDir.Z))
                        else
                            root.CFrame = CFrame.new(currentPos)
                        end

                        root.AssemblyLinearVelocity = Vector3.zero
                        root.AssemblyAngularVelocity = Vector3.zero

                        StatusText.Text = string.format("%s... (%.0f%%)", wp.desc, alpha * 100)

                        if alpha >= 1 then break end
                        task.wait(0.033)
                    end
                end

                currentPos = Vector3.new(segTarget.X, currentTravelY, segTarget.Z)
                root.CFrame = CFrame.new(currentPos)
                root.AssemblyLinearVelocity = Vector3.zero
                root.AssemblyAngularVelocity = Vector3.zero
            end

            -- มั่นใจว่าถึงพิกัดแนวราบจุดหมายปลายทางอย่างแม่นยำ
            root.CFrame = CFrame.new(targetArrival.X, currentTravelY, targetArrival.Z)
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero

            -- Pre-load terrain and floor collision at destination before emerging
            pcall(function()
                LocalPlayer:RequestStreamAroundAsync(targetArrival, 4)
            end)
            if not isDestUnderground and targetArrival.Y < 50.0 then
                local gWait = os.clock()
                local confirmedGround = nil
                while (os.clock() - gWait) < 0.6 do
                    confirmedGround = getGroundAt(targetArrival.X, targetArrival.Z, targetArrival.Y)
                    if confirmedGround then break end
                    task.wait(0.05)
                end
                if confirmedGround then
                    targetArrival = Vector3.new(targetArrival.X, confirmedGround + 3.39, targetArrival.Z)
                end
            end

            -- PHASE 3: In-Place Vertical Emerge (โผล่ขึ้นสู่ผิวดิน ณ จุดหมายปลายทางเท่านั้น)
            if not isDestUnderground then
                StatusText.Text = "ถึงจุดหมายแล้ว กำลังโผล่ขึ้นสู่ผิวดิน..."
                local surfaceTargetY = targetArrival.Y
                local emergeSteps = 6
                for i = 1, emergeSteps do
                    local frac = i / emergeSteps
                    local riseY = currentTravelY + (surfaceTargetY - currentTravelY) * frac
                    root.CFrame = CFrame.new(targetArrival.X, riseY, targetArrival.Z)
                    root.AssemblyLinearVelocity = Vector3.zero
                    root.AssemblyAngularVelocity = Vector3.zero
                    task.wait(0.025)
                end
            end
        end

        root.CFrame = CFrame.new(targetArrival)
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        hum.PlatformStand = false
        pcall(function() hum:ChangeState(Enum.HumanoidStateType.Running) end)
        if isDestUnderground then
            updateSafePlatform(targetArrival, true)
        else
            updateSafePlatform(nil, false)
        end
        task.wait(0.1)

        -- เดินเท้าเข้าสู่วงฟาร์มอย่างเป็นธรรมชาติ
        if shouldWalkIn and not isDestUnderground then
            StatusText.Text = "โผล่ขึ้นมาจากใต้ดินนอกวงแล้ว... กำลังเดินเท้าเข้าสู่วงฟาร์ม"
            local walkTimeout = math.clamp((targetArrival - finalTargetPos).Magnitude / 10 + 4.5, 6.0, 25.0)
            naturalWalkTo(finalTargetPos, walkTimeout)
        end

        state.isFlying = false
        root.Anchored = false
        hum.PlatformStand = false
        pcall(function() hum:ChangeState(Enum.HumanoidStateType.Running) end)
        updateSafePlatform(nil, false)
    end
    local flyUnderground = travelToSurface -- Alias for full backwards compatibility
    _G.NexusHubFlyUnderground = travelToSurface

    -- 5. Auto Restock Supplies on Surface
    ensureSupplies = function(reason)
        if isRestocking or state.isFlying then return false end
        local pData = LocalPlayer:FindFirstChild("PlayerData")
        local sushi = pData and (pData:GetAttribute("Sushi") or 0) or 0
        local cocoa = pData and (pData:GetAttribute("HotCocoa") or 0) or 0
        local money = pData and (pData:GetAttribute("Money") or 0) or 0

        if (sushi <= 1 or cocoa <= 1) and money >= 200 then
            isRestocking = true
            lastRestockTime = os.clock()
            StatusText.Text = "ตรวจพบข้าวหรือน้ำหมด! กำลังเดินทางไปซื้อที่ร้านค้า (Shop) บนดิน..."

            -- Cancel active farm if any
            cancelGameFarm()
            task.wait(0.2)

            travelToSurface(FARM_COORDS.Shop, true)
            waitForStationClear(FARM_COORDS.Shop, "ร้านสะดวกซื้อ")

            pcall(function()
                LocalPlayer:RequestStreamAroundAsync(FARM_COORDS.Shop, 5)
            end)

            local prompt = waitForPrompt(function()
                local f = workspace:FindFirstChild("Systems") and workspace.Systems:FindFirstChild("Shop")
                local pt = f and f:FindFirstChild("Prompt")
                return pt and pt:FindFirstChildWhichIsA("ProximityPrompt")
            end, 6)

            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root then
                local sPos = FARM_COORDS.Shop
                local groundY, _ = getGroundAt(sPos.X, sPos.Z, sPos.Y)
                local shopSurface = Vector3.new(sPos.X, (groundY or sPos.Y) + 3.2, sPos.Z)
                naturalWalkTo(shopSurface, 2.5)
            end
            task.wait(0.4)

            if prompt and fireproximityprompt then
                fireproximityprompt(prompt)
            end
            if prompt then
                pcall(function()
                    prompt:InputHoldBegin()
                    task.wait(prompt.HoldDuration + 0.15)
                    prompt:InputHoldEnd()
                end)
            end
            task.wait(0.6)

            -- Buy Sushi
            if sushi <= 1 and money >= 80 then
                pcall(function()
                    Remotes.Fire("_shop", "Buy", "Sushi", 10)
                end)
                task.wait(0.5)
            end

            -- Buy HotCocoa
            pData = LocalPlayer:FindFirstChild("PlayerData")
            cocoa = pData and (pData:GetAttribute("HotCocoa") or 0) or 0
            money = pData and (pData:GetAttribute("Money") or 0) or 0
            if cocoa <= 1 and money >= 80 then
                pcall(function()
                    Remotes.Fire("_shop", "Buy", "HotCocoa", 10)
                end)
                task.wait(0.5)
            end

            -- Close Shop GUI
            pcall(function()
                local sGui = LocalPlayer.PlayerGui:FindFirstChild("Shop")
                local grp = sGui and sGui:FindFirstChild("Group")
                if grp then grp.Visible = false end
            end)

            StatusText.Text = "ซื้อข้าวและน้ำเสร็จสิ้น! กำลังกลับไปทำงาน..."
            task.wait(0.8)
            isRestocking = false
            return true
        end
        return false
    end

    -- 5.1 Fishing Remote Bite Listener
    pcall(function()
        Remotes.On("_fishing", function(action, token)
            if action == "Bite" then
                _G.NexusFishingToken = token
                _G.NexusBiteTime = os.clock()
            end
        end)
    end)

    -- 5.2 Auto Ensure Fishing Rod (Check, Auto-Buy from Shop 10k, Auto-Equip best rod)
    local function ensureFishingRod()
        local pData = LocalPlayer:FindFirstChild("PlayerData")
        local rodCount = pData and (
            (pData:GetAttribute("FishingRodV3") or 0) +
            (pData:GetAttribute("FishingRodV2") or 0) +
            (pData:GetAttribute("FishingRod") or 0)
        ) or 0

        local char = LocalPlayer.Character
        local bp = LocalPlayer:FindFirstChild("Backpack")
        local equippedTool = char and (char:FindFirstChild("FishingRodV3") or char:FindFirstChild("FishingRodV2") or char:FindFirstChild("FishingRod"))
        local bpTool = bp and (bp:FindFirstChild("FishingRodV3") or bp:FindFirstChild("FishingRodV2") or bp:FindFirstChild("FishingRod"))

        if rodCount == 0 and not equippedTool and not bpTool then
            -- Player has no rod at all, must purchase from Shop (10,000$)
            local money = pData and (pData:GetAttribute("Money") or 0) or 0
            if money < 10000 then
                return nil, "เงินไม่พอซื้อเบ็ดตกปลา (ต้องการ 10,000$)"
            end
            StatusText.Text = "ไม่มีเบ็ดตกปลา! กำลังบินไปซื้อเบ็ดตกปลาที่ร้านสะดวกซื้อ (10,000$)..."
            cancelGameFarm()
            task.wait(0.2)
            travelToSurface(FARM_COORDS.Shop, true)
            waitForStationClear(FARM_COORDS.Shop, "ร้านสะดวกซื้อ")
            pcall(function()
                LocalPlayer:RequestStreamAroundAsync(FARM_COORDS.Shop, 5)
            end)
            local prompt = waitForPrompt(function()
                local f = workspace:FindFirstChild("Systems") and workspace.Systems:FindFirstChild("Shop")
                local pt = f and f:FindFirstChild("Prompt")
                return pt and pt:FindFirstChildWhichIsA("ProximityPrompt")
            end, 6)
            local sPos = FARM_COORDS.Shop
            local groundY, _ = getGroundAt(sPos.X, sPos.Z, sPos.Y)
            local shopSurface = Vector3.new(sPos.X, (groundY or sPos.Y) + 3.2, sPos.Z)
            naturalWalkTo(shopSurface, 2.5)
            task.wait(0.3)
            if prompt and fireproximityprompt then fireproximityprompt(prompt) end
            if prompt then
                pcall(function()
                    prompt:InputHoldBegin()
                    task.wait(prompt.HoldDuration + 0.15)
                    prompt:InputHoldEnd()
                end)
            end
            task.wait(0.5)
            pcall(function()
                Remotes.Fire("_shop", "Buy", "FishingRod", 1)
            end)
            task.wait(0.6)
            pcall(function()
                local sGui = LocalPlayer.PlayerGui:FindFirstChild("Shop")
                local grp = sGui and sGui:FindFirstChild("Group")
                if grp then grp.Visible = false end
            end)
            pData = LocalPlayer:FindFirstChild("PlayerData")
        end

        char = LocalPlayer.Character
        bp = LocalPlayer:FindFirstChild("Backpack")
        equippedTool = char and (char:FindFirstChild("FishingRodV3") or char:FindFirstChild("FishingRodV2") or char:FindFirstChild("FishingRod"))
        if equippedTool then return equippedTool end

        bpTool = bp and (bp:FindFirstChild("FishingRodV3") or bp:FindFirstChild("FishingRodV2") or bp:FindFirstChild("FishingRod"))
        if not bpTool then
            -- Try to spawn into backpack from PlayerData using _inventory:Use
            local bestRod = (pData and (pData:GetAttribute("FishingRodV3") or 0) > 0 and "FishingRodV3")
                or (pData and (pData:GetAttribute("FishingRodV2") or 0) > 0 and "FishingRodV2")
                or "FishingRod"
            pcall(function()
                Remotes.Fire("_inventory", "Use", bestRod)
            end)
            task.wait(0.5)
            bp = LocalPlayer:FindFirstChild("Backpack")
            bpTool = bp and (bp:FindFirstChild("FishingRodV3") or bp:FindFirstChild("FishingRodV2") or bp:FindFirstChild("FishingRod"))
        end

        if bpTool and char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum:EquipTool(bpTool)
                task.wait(0.3)
            end
        end

        char = LocalPlayer.Character
        return char and (char:FindFirstChild("FishingRodV3") or char:FindFirstChild("FishingRodV2") or char:FindFirstChild("FishingRod"))
    end

    -- CANCEL ACTIVE NATIVE FARM SESSION (100% RELIABLE SERVER & CLIENT CANCEL)
    cancelGameFarm = function()
        -- 1. Click native Auto Farm Close button via firesignal (uses valid session token in Farm_Module)
        pcall(function()
            local af = LocalPlayer.PlayerGui:FindFirstChild("Auto Farm")
            local closeBtn = af and af:FindFirstChild("Group") and af.Group:FindFirstChild("Main") and af.Group.Main:FindFirstChild("Prees") and af.Group.Main.Prees:FindFirstChild("Close")
            if closeBtn and firesignal then
                firesignal(closeBtn.MouseButton1Click)
            end
        end)

        -- 2. Send key 'X' to VirtualInputManager
        pcall(function()
            local vim = game:GetService("VirtualInputManager")
            if vim then
                vim:SendKeyEvent(true, Enum.KeyCode.X, false, game)
                task.wait(0.04)
                vim:SendKeyEvent(false, Enum.KeyCode.X, false, game)
            end
        end)

        -- 3. Fire Remote as fallback
        pcall(function()
            Remotes.Fire("_farm", "Cancel")
        end)

        -- 4. Hide Auto Farm GUI directly if still visible
        pcall(function()
            local af = LocalPlayer.PlayerGui:FindFirstChild("Auto Farm")
            local grp = af and af:FindFirstChild("Group")
            if grp then
                grp.Visible = false
                grp.GroupTransparency = 1
            end
        end)

        -- 5. Restore Character State
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChild("Humanoid")
        if root then
            root.Anchored = false
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end
        if hum then
            hum.PlatformStand = false
            pcall(function() hum:ChangeState(Enum.HumanoidStateType.Running) end)
        end
        updateSafePlatform(nil, false)
    end

    -- 6. Trigger Farm Prompt on Surface (In Big Circle, Standing 5.2 studs away from Pillar)
    local function triggerFarmPrompt(farmFolder)
        if not farmFolder then return false end
        local prompt = waitForPrompt(function()
            local pf = farmFolder:FindFirstChild("Prompt")
            local fm = pf and pf:FindFirstChild("Farm")
            local p = fm and fm:FindFirstChildWhichIsA("ProximityPrompt", true)
            if p then return p end

            -- Filter out any vehicle spawn or garage prompts
            for _, pp in ipairs(farmFolder:GetDescendants()) do
                if pp:IsA("ProximityPrompt") then
                    local pName = pp.Parent and pp.Parent.Name:lower() or ""
                    local gName = pp.Parent and pp.Parent.Parent and pp.Parent.Parent.Name:lower() or ""
                    local action = (pp.ActionText or ""):lower()
                    local obj = (pp.ObjectText or ""):lower()
                    if not pName:find("spawn") and not gName:find("spawn") and not action:find("car") and not action:find("spawn") and not obj:find("car") then
                        return pp
                    end
                end
            end
            return nil
        end, 4)
        if not prompt then return false end

        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return false end

        local pWorldPos = (prompt.Parent:IsA("Attachment") and prompt.Parent.WorldPosition) or (prompt.Parent:IsA("BasePart") and prompt.Parent.Position) or root.Position
        local zonePart = (farmFolder:FindFirstChild("Prompt") and farmFolder.Prompt:FindFirstChild("Zone")) or farmFolder:FindFirstChild("Zone", true)
        local centerPos = (zonePart and zonePart.Position) or root.Position

        -- Calculate natural stand position 5.2 studs away from the pillar towards the center of the big circle
        local offsetDir = (centerPos - pWorldPos)
        if Vector3.new(offsetDir.X, 0, offsetDir.Z).Magnitude > 0.5 then
            offsetDir = Vector3.new(offsetDir.X, 0, offsetDir.Z).Unit
        else
            local fromRoot = (root.Position - pWorldPos)
            offsetDir = Vector3.new(fromRoot.X, 0, fromRoot.Z).Magnitude > 0.5 and Vector3.new(fromRoot.X, 0, fromRoot.Z).Unit or Vector3.new(0, 0, 1)
        end

        local standPos = pWorldPos + (offsetDir * 5.2)
        local groundY, _ = getGroundAt(standPos.X, standPos.Z, standPos.Y)
        local trigSurface = Vector3.new(standPos.X, (groundY or standPos.Y) + 3.2, standPos.Z)

        restoreCharacterVisibility()

        -- Stand naturally in the big circle facing the pillar
        root.CFrame = CFrame.new(trigSurface, Vector3.new(pWorldPos.X, trigSurface.Y, pWorldPos.Z))
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        root.Anchored = false
        updateSafePlatform(nil, false)
        task.wait(0.2)

        -- 1. Fire proximity prompt directly
        if fireproximityprompt then
            fireproximityprompt(prompt)
        end

        -- 2. Fallback input hold if needed
        task.wait(0.2)
        if not isFarmingActive() then
            pcall(function()
                prompt:InputHoldBegin()
                task.wait(prompt.HoldDuration + 0.15)
                prompt:InputHoldEnd()
            end)
        end

        local t0 = os.clock()
        while os.clock() - t0 < 0.8 do
            if isFarmingActive() then break end
            task.wait(0.05)
        end

        return isFarmingActive()
    end

    -- 7. Ensure Farming Active Helper
    local function ensureFarmingActive(farmFolder)
        if isFarmingActive() then return true end

        local maxAttempts = 6
        for attempt = 1, maxAttempts do
            if state.stopRequested or (not state.sandwich and not state.mangoRice and not state.bananaFarm and not state.fishFarm and not state.rockFarm and not state.svibFarm) then
                break
            end

            StatusText.Text = string.format("แตะจุดฟาร์มวงใหญ่ ยืนห่างเสา (รอบที่ %d)...", attempt)
            triggerFarmPrompt(farmFolder)

            local t0 = os.clock()
            while os.clock() - t0 < 0.8 do
                if isFarmingActive() then
                    StatusText.Text = "เริ่มฟาร์มสำเร็จ! กำลังฟาร์มในวงใหญ่อยู่บนดิน..."
                    return true
                end
                task.wait(0.1)
            end

            StatusText.Text = "ยังไม่เริ่มฟาร์ม กำลังลองกดใหม่อีกครั้ง..."
            task.wait(0.3)
        end

        return isFarmingActive()
    end

    -- 8. Farm Items Until Target (100% on Surface in Big Circle, Standing 5.2 studs away from Pillar)
    local function farmItemsUntilTarget(farmFolder, itemName, targetCount, maxBatch, activeConditionCheck)
        local prompt = waitForPrompt(function()
            local pf = farmFolder and farmFolder:FindFirstChild("Prompt")
            local fm = pf and pf:FindFirstChild("Farm")
            local p = fm and fm:FindFirstChildWhichIsA("ProximityPrompt", true)
            if p then return p end

            -- Filter out any vehicle spawn or garage prompts
            if farmFolder then
                for _, pp in ipairs(farmFolder:GetDescendants()) do
                    if pp:IsA("ProximityPrompt") then
                        local pName = pp.Parent and pp.Parent.Name:lower() or ""
                        local gName = pp.Parent and pp.Parent.Parent and pp.Parent.Parent.Name:lower() or ""
                        local action = (pp.ActionText or ""):lower()
                        local obj = (pp.ObjectText or ""):lower()
                        if not pName:find("spawn") and not gName:find("spawn") and not action:find("car") and not action:find("spawn") and not obj:find("car") then
                            return pp
                        end
                    end
                end
            end
            return nil
        end, 4)

        local zonePart = (farmFolder and farmFolder:FindFirstChild("Prompt") and farmFolder.Prompt:FindFirstChild("Zone")) or (farmFolder and farmFolder:FindFirstChild("Zone", true))
        local pWorldPos = (prompt and ((prompt.Parent:IsA("Attachment") and prompt.Parent.WorldPosition) or (prompt.Parent:IsA("BasePart") and prompt.Parent.Position))) or (zonePart and zonePart.Position) or FARM_COORDS[itemName] or (LocalPlayer.Character and LocalPlayer.Character.HumanoidRootPart.Position)
        local centerPos = (zonePart and zonePart.Position) or FARM_COORDS[itemName] or pWorldPos

        -- Stand 5.2 studs away from the pillar towards the center of the big circle
        local offsetDir = (centerPos - pWorldPos)
        if Vector3.new(offsetDir.X, 0, offsetDir.Z).Magnitude > 0.5 then
            offsetDir = Vector3.new(offsetDir.X, 0, offsetDir.Z).Unit
        else
            offsetDir = Vector3.new(0, 0, 1)
        end

        local standPos = pWorldPos + (offsetDir * 5.2)
        local groundY, _ = getGroundAt(standPos.X, standPos.Z, standPos.Y)
        local surfaceFarmPos = Vector3.new(standPos.X, (groundY or standPos.Y) + 3.2, standPos.Z)

        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if root then
            root.CFrame = CFrame.new(surfaceFarmPos, Vector3.new(pWorldPos.X, surfaceFarmPos.Y, pWorldPos.Z))
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            root.Anchored = false
        end
        updateSafePlatform(nil, false)

        ensureFarmingActive(farmFolder)
        local pData = LocalPlayer:FindFirstChild("PlayerData")
        local lastCount = pData and (pData:GetAttribute(itemName) or 0) or 0
        local lastGainTime = os.clock()
        local overallTimeout = 0

        while activeConditionCheck() and overallTimeout < 240 do
            while isRestocking or isConsuming do
                task.wait(0.5)
                lastGainTime = os.clock()
            end

            local curCount = pData and (pData:GetAttribute(itemName) or 0) or 0
            if curCount >= targetCount or curCount >= maxBatch then
                break
            end

            StatusText.Text = string.format("กำลังฟาร์ม %s ในวงใหญ่บนดิน (ได้ %d/%d)...", itemName, curCount, targetCount)

            if curCount > lastCount then
                lastCount = curCount
                lastGainTime = os.clock()
            else
                if os.clock() - lastGainTime >= 14 then
                    StatusText.Text = string.format("ฟาร์ม %s ติดขัด (ไม่มีของเข้า 14 วิ)! ยกเลิกแล้วเริ่มใหม่...", itemName)
                    cancelGameFarm()
                    task.wait(0.5)
                    ensureFarmingActive(farmFolder)
                    lastGainTime = os.clock()
                elseif not isFarmingActive() then
                    ensureFarmingActive(farmFolder)
                    lastGainTime = os.clock()
                end
            end

            -- Maintain natural standing position 5.2 studs away from pillar facing it
            local c = LocalPlayer.Character
            local r = c and c:FindFirstChild("HumanoidRootPart")
            if r and (r.Position - surfaceFarmPos).Magnitude > 6 then
                r.CFrame = CFrame.new(surfaceFarmPos, Vector3.new(pWorldPos.X, surfaceFarmPos.Y, pWorldPos.Z))
            end

            task.wait(0.5)
            overallTimeout = overallTimeout + 0.5
        end

        cancelGameFarm()
        local c = LocalPlayer.Character
        local r = c and c:FindFirstChild("HumanoidRootPart")
        if r then r.Anchored = false end
    end

    -- 9. Surface Craft Food Helper with Guaranteed Inventory Inflow & Auto-Retry Loop
    local function craftFoodUnderground(recipeName, count)
        local pData = LocalPlayer:FindFirstChild("PlayerData")
        local foodDisplayName = recipeName == "Sandwish" and "แซนด์วิช" or "ข้าวเหนียวมะม่วง"

        -- บันทึกจำนวนของเดิมในกระเป๋าก่อนเริ่มคราฟต์
        local initialFoodCount = pData and (pData:GetAttribute(recipeName) or 0) or 0

        StatusText.Text = string.format("กำลังบินไปโต๊ะคราฟต์อาหาร เพื่อคราฟต์ %s...", foodDisplayName)
        travelToSurface(FARM_COORDS.CraftFood, true)

        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChild("Humanoid")
        if not root or not hum then return false end

        pcall(function()
            LocalPlayer:RequestStreamAroundAsync(FARM_COORDS.CraftFood, 5)
        end)

        -- ฟังก์ชันคำนวณวัตถุดิบและจำนวนชิ้นที่คราฟต์ได้จริงสูงสุด
        local function getMaxCraftable()
            local b = pData and (pData:GetAttribute("Bread") or 0) or 0
            local c = pData and (pData:GetAttribute("Catchup") or 0) or 0
            local p = pData and (pData:GetAttribute("Pig") or 0) or 0
            local m = pData and (pData:GetAttribute("Mango") or 0) or 0
            local r = pData and (pData:GetAttribute("Rice") or 0) or 0

            if recipeName == "Sandwish" then
                return math.min(math.floor(b / 3), math.floor(c / 2), math.floor(p / 2))
            elseif recipeName == "MangoRice" then
                return math.min(math.floor(m / 2), math.floor(r / 3))
            end
            return 1
        end

        local maxRetries = 6
        local retryAttempt = 0
        local craftCompleted = false

        while retryAttempt < maxRetries do
            if state.stopRequested or (not state.sandwich and not state.mangoRice and not state.isManualAction) then break end
            retryAttempt = retryAttempt + 1

            local maxPossible = getMaxCraftable()
            if maxPossible <= 0 then
                -- วัตถุดิบหมด ไม่สามารถคราฟต์ต่อได้
                break
            end

            -- คราฟต์จำนวนมากที่สุดที่จะคราฟต์ได้อิงจากของที่มีอยู่ในตัว (ไม่มีการจำกัดเพดาน 20 ชิ้น)
            local toCraft = math.max(1, count and math.min(count, maxPossible) or maxPossible)

            -- 1. ยืนประจำจุดหน้าโต๊ะคราฟต์อย่างมั่นคง (ห้ามห่างเกิน 6 studs ตามเงื่อนไขเกม)
            local prompt = waitForPrompt(function()
                local c3 = workspace:FindFirstChild("Systems") and workspace.Systems:FindFirstChild("Crafting") and workspace.Systems.Crafting:FindFirstChild("Craft_3")
                local pt = c3 and c3:FindFirstChild("Prompt")
                return pt and pt:FindFirstChildWhichIsA("ProximityPrompt")
            end, 4)

            local promptPart = prompt and prompt.Parent
            local pPos = (promptPart and promptPart:IsA("BasePart") and promptPart.Position)
                      or (promptPart and promptPart:IsA("Attachment") and promptPart.WorldPosition)
                      or FARM_COORDS.CraftFood
            local groundY, _ = getGroundAt(pPos.X, pPos.Z, pPos.Y)
            local craftSurfacePos = Vector3.new(pPos.X, (groundY or pPos.Y) + 3.2, pPos.Z)

            if (root.Position - craftSurfacePos).Magnitude > 4.5 then
                naturalWalkTo(craftSurfacePos, 2.0)
            end
            updateSafePlatform(nil, false)
            task.wait(0.2)

            if retryAttempt == 1 then
                StatusText.Text = "กำลังเปิดโต๊ะคราฟต์อาหาร..."
            else
                StatusText.Text = string.format("ตรวจพบของยังไม่เข้าตัว! กำลังเปิดโต๊ะคราฟต์ใหม่ (รอบที่ %d/%d)...", retryAttempt, maxRetries)
            end

            if prompt then
                if fireproximityprompt then
                    fireproximityprompt(prompt)
                end
                pcall(function()
                    prompt:InputHoldBegin()
                    task.wait(prompt.HoldDuration + 0.15)
                    prompt:InputHoldEnd()
                end)
            end
            task.wait(0.5)

            -- 2. เลือกสูตรใน UI และกรอกจำนวน
            local cGui = LocalPlayer.PlayerGui:FindFirstChild("Crafting")
            local grp = cGui and cGui:FindFirstChild("Group")
            local main = grp and grp:FindFirstChild("Main")

            if main then
                grp.Visible = true
                -- เลือกปุ่มสูตร
                local scroller = main:FindFirstChild("Left_Tab") and main.Left_Tab:FindFirstChild("ScrollingFrame")
                local recipeBtn = scroller and scroller:FindFirstChild(recipeName)
                local clickTarget = recipeBtn and (recipeBtn:IsA("GuiButton") and recipeBtn or recipeBtn:FindFirstChildWhichIsA("GuiButton", true))
                if clickTarget then
                    if firesignal then
                        firesignal(clickTarget.MouseButton1Click)
                    else
                        clickTarget.MouseButton1Click:Fire()
                    end
                end
                task.wait(0.25)

                -- กรอกจำนวนชิ้น
                local amtBox = main:FindFirstChild("Function") and main.Function:FindFirstChild("Amount") and main.Function.Amount:FindFirstChild("Amount")
                if amtBox then
                    amtBox.Text = tostring(toCraft)
                end
                task.wait(0.2)

                -- กดปุ่มคราฟต์บน UI
                local craftBtn = main:FindFirstChild("Button") and main.Button:FindFirstChild("Craft")
                if craftBtn then
                    if firesignal then
                        firesignal(craftBtn.MouseButton1Click)
                    else
                        craftBtn.MouseButton1Click:Fire()
                    end
                end
            end

            -- 3. ส่งคำสั่ง Remote Request ควบคู่ไปด้วยเพื่อความชัวร์
            pcall(function()
                Remotes.Fire("_crafting", "Request", "Craft_3", recipeName, toCraft, false)
            end)

            -- 4. นับเวลาคราฟต์ 11 วินาที (ตัวละครยืนประจำจุดที่โต๊ะ)
            for sec = 11, 1, -1 do
                if state.stopRequested or (not state.sandwich and not state.mangoRice and not state.isManualAction) then break end
                StatusText.Text = string.format("กำลังคราฟต์ %s %d ชิ้น [รอบที่ %d] (เหลือ %d วินาที)...", foodDisplayName, toCraft, retryAttempt, sec)
                task.wait(1)
            end

            -- 5. ส่งคำสั่ง Complete ไปที่ Remote
            pcall(function()
                Remotes.Fire("_crafting", "Complete", "Craft_3", recipeName, toCraft, false)
            end)
            task.wait(0.8)

            -- 6. ตรวจสอบของในตัว (Verification): เช็กว่าไอเทมที่คราฟต์เพิ่มขึ้นจริงหรือไม่
            local startWait = os.clock()
            local itemGained = false
            while os.clock() - startWait < 4.0 do
                local curCount = pData and (pData:GetAttribute(recipeName) or 0) or 0
                if curCount > initialFoodCount or curCount >= toCraft then
                    itemGained = true
                    craftCompleted = true
                    break
                end
                task.wait(0.4)
            end

            if itemGained then
                local finalFoodCount = pData and (pData:GetAttribute(recipeName) or 0) or 0
                StatusText.Text = string.format("คราฟต์ %s สำเร็จ! ของเข้าตัวเรียบร้อย (มีในตัว %d ชิ้น)", foodDisplayName, finalFoodCount)
                task.wait(0.8)
                break
            else
                StatusText.Text = string.format("ของยังไม่เข้าตัว (มี %d ชิ้น)! กำลังกดคราฟต์ใหม่...", pData and (pData:GetAttribute(recipeName) or 0) or 0)
                task.wait(1.0)
            end
        end

        -- ปิดหน้าต่าง Crafting UI
        pcall(function()
            local cGui = LocalPlayer.PlayerGui:FindFirstChild("Crafting")
            local grp = cGui and cGui:FindFirstChild("Group")
            if grp then grp.Visible = false end
        end)

        local currentFinal = pData and (pData:GetAttribute(recipeName) or 0) or 0
        return currentFinal > 0 or craftCompleted
    end

    -- 10. Surface Sell at Economy with Queue Check
    local function sellAtEconomyUnderground(foodItem)
        local foodDisplayName = foodItem == "Sandwish" and "แซนด์วิช" 
            or (foodItem == "MangoRice" and "ข้าวเหนียวมะม่วง" 
            or (foodItem == "BananaPack" and "ห่อกล้วย (BananaPack)" 
            or (foodItem == "Fish" and "ปลาทุกชนิด" or "สินค้า")))
        StatusText.Text = "กำลังเดินทางไปขายที่ร้านค้า (Economy) บนดิน..."
        travelToSurface(FARM_COORDS.Sell, true)

        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChild("Humanoid")
        if not root or not hum then return end

        pcall(function()
            LocalPlayer:RequestStreamAroundAsync(FARM_COORDS.Sell, 5)
        end)

        local prompt = waitForPrompt(function()
            local econ = workspace:FindFirstChild("Systems") and workspace.Systems:FindFirstChild("Economy")
            local pt = econ and econ:FindFirstChild("Prompt")
            return pt and pt:FindFirstChildWhichIsA("ProximityPrompt")
        end, 6)

        local promptPart = prompt and prompt.Parent
        local econPos = (promptPart and promptPart:IsA("BasePart") and promptPart.Position) or FARM_COORDS.Sell
        local groundY, _ = getGroundAt(econPos.X, econPos.Z, econPos.Y)
        local sellSurfacePos = Vector3.new(econPos.X, (groundY or econPos.Y) + 3.2, econPos.Z)

        naturalWalkTo(sellSurfacePos, 2.5)
        updateSafePlatform(nil, false)
        task.wait(0.2)

        if prompt and fireproximityprompt then
            fireproximityprompt(prompt)
        end
        if prompt then
            pcall(function()
                prompt:InputHoldBegin()
                task.wait(prompt.HoldDuration + 0.15)
                prompt:InputHoldEnd()
            end)
        end
        task.wait(0.4)

        local pData = LocalPlayer:FindFirstChild("PlayerData")
        local count = foodItem and pData and (pData:GetAttribute(foodItem) or 0) or 0

        StatusText.Text = string.format("กำลังขาย %s...", foodDisplayName)
        if foodItem == "Fish" then
            for _, fishName in ipairs({"Bettafish", "Anglerfish", "Sardine"}) do
                local fCount = pData and (pData:GetAttribute(fishName) or 0) or 0
                if fCount > 0 then
                    pcall(function()
                        Remotes.Fire("_economy", "Sell", fishName, fCount)
                    end)
                    task.wait(0.2)
                end
            end
        elseif foodItem and count > 0 then
            pcall(function()
                Remotes.Fire("_economy", "Sell", foodItem, count)
            end)
            task.wait(0.4)
        end

        pcall(function()
            Remotes.Fire("_economy", "SellAll")
        end)
        task.wait(0.6)

        -- Close Economy GUI
        pcall(function()
            local eGui = LocalPlayer.PlayerGui:FindFirstChild("Economy")
            local grp = eGui and eGui:FindFirstChild("Group")
            if grp then grp.Visible = false end
        end)

        local moneyNow = pData and (pData:GetAttribute("Money") or 0) or 0
        StatusText.Text = string.format("ขาย %s สำเร็จเรียบร้อย! เงินปัจจุบัน: %d$", foodDisplayName, moneyNow)
        task.wait(1.0)
        if root then root.Anchored = false end
        return true
    end

    -- CHECK & AUTO-BUY PICKAXE HELPER (Strictly Underground)
    local function hasPickaxe()
        local pData = LocalPlayer:FindFirstChild("PlayerData")
        local pickAttr = pData and (pData:GetAttribute("Pickaxe") or 0) or 0
        if pickAttr > 0 then return true end
        if LocalPlayer.Backpack:FindFirstChild("Pickaxe") then return true end
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Pickaxe") then return true end
        return false
    end

    local function ensurePickaxe()
        if hasPickaxe() then return true end

        StatusText.Text = "ตรวจพบไม่มีพิกแอ็กซ์! กำลังเดินทางไปซื้อที่ร้านค้าใต้ดิน (1,500$)..."
        flyUnderground(FARM_COORDS.Shop)

        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChild("Humanoid")
        if not root or not hum then return false end

        local shopPos = FARM_COORDS.Shop
        local targetPos = Vector3.new(shopPos.X, shopPos.Y - state.undergroundDepth, shopPos.Z)
        root.CFrame = CFrame.new(targetPos)
        root.AssemblyLinearVelocity = Vector3.zero
        root.Anchored = true
        updateSafePlatform(targetPos, true)
        task.wait(0.3)

        local promptPart = workspace:FindFirstChild("Systems") and workspace.Systems:FindFirstChild("Shop") and workspace.Systems.Shop:FindFirstChild("Prompt")
        local prompt = promptPart and promptPart:FindFirstChildWhichIsA("ProximityPrompt")

        if prompt then
            if fireproximityprompt then
                fireproximityprompt(prompt)
            end
            pcall(function()
                prompt:InputHoldBegin()
                task.wait(prompt.HoldDuration + 0.1)
                prompt:InputHoldEnd()
            end)
            task.wait(0.5)
        end

        local pData = LocalPlayer:FindFirstChild("PlayerData")
        local money = pData and (pData:GetAttribute("Money") or 0) or 0
        if money < 1500 then
            StatusText.Text = string.format("เงินไม่พอซื้อพิกแอ็กซ์! ต้องการ 1,500$ (มี %s$)", tostring(money))
            return false
        end

        StatusText.Text = "กำลังสั่งซื้อพิกแอ็กซ์ที่ร้านค้า..."
        pcall(function()
            Remotes.Fire("_shop", "Buy", {Pickaxe = 1}, "Money")
        end)
        task.wait(1)

        pcall(function()
            local sGui = LocalPlayer.PlayerGui:FindFirstChild("Shop")
            local grp = sGui and sGui:FindFirstChild("Group")
            if grp then grp.Visible = false end
        end)

        if hasPickaxe() then
            StatusText.Text = "ซื้อพิกแอ็กซ์สำเร็จเรียบร้อย! กำลังไปขุดแร่ต่อ..."
            task.wait(1)
            return true
        else
            StatusText.Text = "ซื้อพิกแอ็กซ์ไม่สำเร็จ กรุณาตรวจสอบเงินหรือร้านค้า"
            return false
        end
    end

    -- DETECT VAULT / SAFE STATUS & UPGRADE LEVEL (+0 to +4)
    local function getVaultStatus()
        local pData = LocalPlayer:FindFirstChild("PlayerData")
        local pSafe = LocalPlayer:FindFirstChild("PlayerSafe")
        local pSetting = pSafe and pSafe:FindFirstChild("Setting")

        local level = 0
        local activeKey = nil

        -- 1. Check via Vault_Config GetLevel (game standard)
        pcall(function()
            local vc = require(ReplicatedStorage.Systems.Config.Vault_Config)
            if vc and vc.GetLevel and pData then
                level = vc.GetLevel(pData)
                if level > 0 and vc.Keys and vc.Keys[level] then
                    activeKey = vc.Keys[level]
                end
            end
        end)

        -- 2. Fallback check: PlayerData and PlayerSafe direct attributes
        local keyTiers = {
            VaultKeyV5 = {level = 5, plus = "+4", name = "ตู้เซฟ +4 (V5)", maxWeight = 1500},
            VaultKeyV4 = {level = 4, plus = "+3", name = "ตู้เซฟ +3 (V4)", maxWeight = 1000},
            VaultKeyV3 = {level = 3, plus = "+2", name = "ตู้เซฟ +2 (V3)", maxWeight = 800},
            VaultKeyV2 = {level = 2, plus = "+1", name = "ตู้เซฟ +1 (V2)", maxWeight = 600},
            VaultKey   = {level = 1, plus = "+0", name = "ตู้เซฟเริ่มต้น (+0)", maxWeight = 400},
        }

        if level == 0 then
            for _, kName in ipairs({"VaultKeyV5", "VaultKeyV4", "VaultKeyV3", "VaultKeyV2", "VaultKey"}) do
                local c1 = pData and pData:GetAttribute(kName) or 0
                local c2 = pSafe and pSafe:GetAttribute(kName) or 0
                if (type(c1) == "number" and c1 > 0) or (type(c2) == "number" and c2 > 0) then
                    level = keyTiers[kName].level
                    activeKey = kName
                    break
                end
            end
        end

        -- 3. Fallback check: PlayerSafe.Setting.Level
        if level == 0 and pSetting then
            local sLvl = pSetting:GetAttribute("Level")
            if type(sLvl) == "number" and sLvl > 0 then
                level = sLvl
                local keyNames = {"VaultKey", "VaultKeyV2", "VaultKeyV3", "VaultKeyV4", "VaultKeyV5"}
                activeKey = keyNames[math.clamp(level, 1, 5)]
            end
        end

        -- Calculate capacity & current safe weight
        local maxWeight = 0
        local currentWeight = 0
        if level > 0 then
            pcall(function()
                local vc = require(ReplicatedStorage.Systems.Config.Vault_Config)
                maxWeight = vc.GetMaxWeight(level)
            end)
            if maxWeight == 0 then
                local defWeights = {400, 600, 800, 1000, 1500}
                maxWeight = defWeights[math.clamp(level, 1, 5)] or 400
            end

            pcall(function()
                local Items = require(ReplicatedStorage.Systems.Modules.Data.Items)
                if pSafe and Items and Items.Items_Image then
                    for k, v in pairs(pSafe:GetAttributes()) do
                        if type(v) == "number" and v > 0 then
                            local itemData = Items.Items_Image[k]
                            local w = (itemData and itemData.Weight) or 0.2
                            currentWeight = currentWeight + (v * w)
                        end
                    end
                end
            end)
        end

        local hasVault = (level > 0)
        local tierInfo = {
            [0] = {plus = "ไม่มี", name = "ไม่มีตู้เซฟ", maxWeight = 0},
            [1] = {plus = "+0", name = "ตู้เซฟเริ่มต้น (+0)", maxWeight = 400},
            [2] = {plus = "+1", name = "ตู้เซฟ +1 (V2)", maxWeight = 600},
            [3] = {plus = "+2", name = "ตู้เซฟ +2 (V3)", maxWeight = 800},
            [4] = {plus = "+3", name = "ตู้เซฟ +3 (V4)", maxWeight = 1000},
            [5] = {plus = "+4", name = "ตู้เซฟ +4 (V5)", maxWeight = 1500},
        }

        local info = tierInfo[math.clamp(level, 0, 5)] or tierInfo[0]

        local statusStr = ""
        if hasVault then
            statusStr = string.format("%s (ระดับ %d) | ความจุ: %.1f/%.0f กก.", info.name, level, currentWeight, maxWeight)
        else
            statusStr = "ไม่มีตู้เซฟ (ยังไม่ได้คราฟต์กุญแจ VaultKey)"
        end

        return {
            hasVault = hasVault,
            level = level,
            plus = info.plus,
            name = info.name,
            activeKey = activeKey,
            currentWeight = currentWeight,
            maxWeight = maxWeight,
            displayStatus = statusStr
        }
    end

    -- DEPOSIT ORES & VIBRANIUM TO VAULT (Strictly Underground, Specific Items Only)
    local VAULT_ORES = {"Rock", "Iron", "Gold", "Diamond", "Svibranium", "Vibranium"}

    local function depositOresToVault()
        if not state.autoVaultOres then return false end
        local pData = LocalPlayer:FindFirstChild("PlayerData")
        if not pData then return false end

        -- Check if player holds any ores or vibranium
        local hasOres = false
        for _, ore in ipairs(VAULT_ORES) do
            local count = pData:GetAttribute(ore) or 0
            if count > 0 then
                hasOres = true
                break
            end
        end
        if not hasOres then return false end

        -- Check VaultKey requirement (level > 0)
        local vaultStatus = getVaultStatus()
        if not vaultStatus.hasVault then
            StatusText.Text = "ตู้เซฟ: ตรวจพบว่ายังไม่มีตู้เซฟ (ยังไม่มีกุญแจ VaultKey ข้ามการฝาก)"
            task.wait(1.5)
            return false
        end

        StatusText.Text = string.format("กำลังเดินทางไปตู้เซฟ [%s] ใต้ดินเพื่อฝากแร่...", vaultStatus.name)
        flyUnderground(FARM_COORDS.Vault, 220, 6.0)

        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return false end

        pcall(function()
            LocalPlayer:RequestStreamAroundAsync(FARM_COORDS.Vault, 5)
        end)

        local prompt = waitForPrompt(function()
            local sv = workspace:FindFirstChild("Systems") and workspace.Systems:FindFirstChild("Safe Vault")
            local v = sv and sv:FindFirstChild("Vault")
            local pt = v and v:FindFirstChild("Prompt")
            return pt and pt:FindFirstChildOfClass("ProximityPrompt")
        end, 6)

        local vPos = FARM_COORDS.Vault
        -- Position strictly underground (6.0 studs below prompt, well within 8 studs check and 15 studs prompt activation)
        local underVaultPos = Vector3.new(vPos.X, vPos.Y - 6.0, vPos.Z)
        root.CFrame = CFrame.new(underVaultPos)
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        root.Anchored = true
        updateSafePlatform(underVaultPos, true)
        task.wait(0.4)

        if prompt and fireproximityprompt then
            fireproximityprompt(prompt)
        end
        if prompt then
            pcall(function()
                prompt:InputHoldBegin()
                task.wait(prompt.HoldDuration + 0.1)
                prompt:InputHoldEnd()
            end)
        end
        task.wait(0.5)

        -- Deposit strictly ores and vibranium only
        for _, ore in ipairs(VAULT_ORES) do
            local count = pData:GetAttribute(ore) or 0
            if count > 0 then
                StatusText.Text = string.format("กำลังฝาก %s x%d ลงในตู้เซฟ...", ore, count)
                pcall(function()
                    Remotes.Fire("_vault", "Deposit", ore, count)
                end)
                task.wait(0.35)
            end
        end

        -- Close Vault GUI if open
        pcall(function()
            local vGui = LocalPlayer.PlayerGui:FindFirstChild("Vault")
            local grp = vGui and vGui:FindFirstChild("Group")
            if grp then grp.Visible = false end
        end)

        StatusText.Text = "ฝากแร่และไวเบรเนียมในตู้เซฟเรียบร้อยแล้ว!"
        task.wait(1.0)
        if root then root.Anchored = false end
        return true
    end

    -- Sandwich Auto-Farm Loop
    task.spawn(function()
        while myToken.running do
            if isAtServerSelectionScreen() then
                task.wait(1.5)
            elseif state.sandwich then
                local sOk, sErr = pcall(function()
                    local pData = LocalPlayer:FindFirstChild("PlayerData")
                    local b = pData and pData:GetAttribute("Bread") or 0
                    local c = pData and pData:GetAttribute("Catchup") or 0
                    local p = pData and pData:GetAttribute("Pig") or 0

                    local sw = pData and pData:GetAttribute("Sandwish") or 0

                    -- PRIORITY 1: If player has Sandwiches in inventory, sell them immediately!
                    if sw > 0 then
                        StatusText.Text = string.format("ตรวจพบแซนด์วิชในตัว %d ชิ้น! กำลังเดินทางไปขายที่ร้านค้าทันที...", sw)
                        sellAtEconomyUnderground("Sandwish")
                    -- PRIORITY 2: If all 3 ingredients are >= 60, craft and sell!
                    elseif b >= 60 and c >= 60 and p >= 60 then
                        cancelGameFarm()
                        local canCraft = math.min(math.floor(b / 3), math.floor(c / 2), math.floor(p / 2))
                        local toCraft = canCraft
                        if toCraft > 0 then
                            StatusText.Text = string.format("วัตถุดิบครบแล้ว! กำลังเดินทางไปคราฟต์แซนด์วิชจำนวนสูงสุด (%d ชิ้น)", toCraft)
                            craftFoodUnderground("Sandwish", toCraft)
                            if state.sandwich then
                                local swNow = pData and (pData:GetAttribute("Sandwish") or 0) or 0
                                if swNow > 0 then
                                    StatusText.Text = string.format("คราฟต์สำเร็จ (มีในตัว %d ชิ้น)! กำลังเดินทางไปขายที่ร้านค้าทันที", swNow)
                                    sellAtEconomyUnderground("Sandwish")
                                else
                                    StatusText.Text = "ตรวจพบไม่มีแซนด์วิชในตัว ข้ามการขายและกลับไปตรวจสอบวัตถุดิบ..."
                                end
                            end
                        end
                    -- PRIORITY 3: Farm ingredients
                    elseif b < 60 then
                        if isFarmingActive() then
                            cancelGameFarm()
                            task.wait(0.2)
                        end
                        StatusText.Text = string.format("กำลังไปฟาร์ม ขนมปัง (มี %d/60)...", b)
                        flyUnderground(FARM_COORDS.Bread)
                        if state.sandwich then
                            farmItemsUntilTarget(workspace.Systems.Farm.Bread, "Bread", 60, 60, function() return state.sandwich end)
                        end
                    elseif c < 60 then
                        if isFarmingActive() then
                            cancelGameFarm()
                            task.wait(0.2)
                        end
                        StatusText.Text = string.format("กำลังไปฟาร์ม ซอสมะเขือเทศ (มี %d/60)...", c)
                        flyUnderground(FARM_COORDS.Catchup)
                        if state.sandwich then
                            farmItemsUntilTarget(workspace.Systems.Farm.Catchup, "Catchup", 60, 60, function() return state.sandwich end)
                        end
                    elseif p < 60 then
                        if isFarmingActive() then
                            cancelGameFarm()
                            task.wait(0.2)
                        end
                        StatusText.Text = string.format("กำลังไปฟาร์ม เนื้อหมู (มี %d/60)...", p)
                        flyUnderground(FARM_COORDS.Pig)
                        if state.sandwich then
                            farmItemsUntilTarget(workspace.Systems.Farm.Pig, "Pig", 60, 60, function() return state.sandwich end)
                        end
                    end

                    -- IMMEDIATE POST-CHECK: If all 3 ingredients are >= 60, craft and sell immediately!
                    if state.sandwich then
                        local pDataPost = LocalPlayer:FindFirstChild("PlayerData")
                        local bPost = pDataPost and pDataPost:GetAttribute("Bread") or 0
                        local cPost = pDataPost and pDataPost:GetAttribute("Catchup") or 0
                        local pPost = pDataPost and pDataPost:GetAttribute("Pig") or 0
                        local canCraftPost = math.min(math.floor(bPost / 3), math.floor(cPost / 2), math.floor(pPost / 2))
                        if bPost >= 60 and cPost >= 60 and pPost >= 60 and canCraftPost > 0 then
                            cancelGameFarm()
                            local toCraftPost = canCraftPost
                            StatusText.Text = string.format("วัตถุดิบครบ 60 อันทุกอย่างแล้ว! บินไปคราฟต์แซนด์วิชจำนวนสูงสุด (%d ชิ้น) ทันที", toCraftPost)
                            craftFoodUnderground("Sandwish", toCraftPost)
                            if state.sandwich then
                                local swPost = pDataPost and (pDataPost:GetAttribute("Sandwish") or 0) or 0
                                if swPost > 0 then
                                    StatusText.Text = string.format("คราฟต์สำเร็จ (มีในตัว %d ชิ้น)! กำลังเดินทางไปขายที่ร้านค้าทันที", swPost)
                                    sellAtEconomyUnderground("Sandwish")
                                else
                                    StatusText.Text = "ตรวจพบไม่มีแซนด์วิชในตัว ข้ามการขายและกลับไปตรวจสอบวัตถุดิบ..."
                                end
                            end
                        end
                    end
                end)
                if not sOk then
                    warn("[Nexus Hub] Sandwich loop error:", sErr)
                    task.wait(1)
                end
            end
            task.wait(0.5)
        end
    end)

    -- Mango Rice Auto-Farm Loop
    task.spawn(function()
        while myToken.running do
            if isAtServerSelectionScreen() then
                task.wait(1.5)
            elseif state.mangoRice then
                local mOk, mErr = pcall(function()
                    local pData = LocalPlayer:FindFirstChild("PlayerData")
                    local m = pData and pData:GetAttribute("Mango") or 0
                    local r = pData and pData:GetAttribute("Rice") or 0

                    local mr = pData and pData:GetAttribute("MangoRice") or 0

                    -- PRIORITY 1: If player has MangoRice in inventory, sell them immediately!
                    if mr > 0 then
                        StatusText.Text = string.format("ตรวจพบข้าวเหนียวมะม่วงในตัว %d ชิ้น! กำลังเดินทางไปขายที่ร้านค้าทันที...", mr)
                        sellAtEconomyUnderground("MangoRice")
                    -- PRIORITY 2: If both ingredients are >= 60, craft and sell!
                    elseif m >= 60 and r >= 60 then
                        cancelGameFarm()
                        local canCraft = math.min(math.floor(m / 2), math.floor(r / 3))
                        local toCraft = canCraft
                        if toCraft > 0 then
                            StatusText.Text = string.format("วัตถุดิบครบแล้ว! กำลังเดินทางไปคราฟต์ข้าวเหนียวมะม่วงจำนวนสูงสุด (%d ชิ้น)", toCraft)
                            craftFoodUnderground("MangoRice", toCraft)
                            if state.mangoRice then
                                local mrNow = pData and (pData:GetAttribute("MangoRice") or 0) or 0
                                if mrNow > 0 then
                                    StatusText.Text = string.format("คราฟต์สำเร็จ (มีในตัว %d ชิ้น)! กำลังเดินทางไปขายที่ร้านค้าทันที", mrNow)
                                    sellAtEconomyUnderground("MangoRice")
                                else
                                    StatusText.Text = "ตรวจพบไม่มีข้าวเหนียวมะม่วงในตัว ข้ามการขายและกลับไปตรวจสอบวัตถุดิบ..."
                                end
                            end
                        end
                    -- PRIORITY 3: Farm ingredients
                    elseif m < 60 then
                        if isFarmingActive() then
                            cancelGameFarm()
                            task.wait(0.2)
                        end
                        StatusText.Text = string.format("กำลังไปฟาร์ม มะม่วง (มี %d/60)...", m)
                        flyUnderground(FARM_COORDS.Mango)
                        if state.mangoRice then
                            farmItemsUntilTarget(workspace.Systems.Farm.Mango, "Mango", 60, 60, function() return state.mangoRice end)
                        end
                    elseif r < 60 then
                        if isFarmingActive() then
                            cancelGameFarm()
                            task.wait(0.2)
                        end
                        StatusText.Text = string.format("กำลังไปฟาร์ม ข้าว (มี %d/60)...", r)
                        flyUnderground(FARM_COORDS.Rice)
                        if state.mangoRice then
                            farmItemsUntilTarget(workspace.Systems.Farm.Rice, "Rice", 60, 60, function() return state.mangoRice end)
                        end
                    end

                    -- IMMEDIATE POST-CHECK: If both ingredients are >= 60, craft and sell immediately!
                    if state.mangoRice then
                        local pDataPost = LocalPlayer:FindFirstChild("PlayerData")
                        local mPost = pDataPost and pDataPost:GetAttribute("Mango") or 0
                        local rPost = pDataPost and pDataPost:GetAttribute("Rice") or 0
                        local canCraftPost = math.min(math.floor(mPost / 2), math.floor(rPost / 3))
                        if mPost >= 60 and rPost >= 60 and canCraftPost > 0 then
                            cancelGameFarm()
                            local toCraftPost = canCraftPost
                            StatusText.Text = string.format("วัตถุดิบครบ 60 อันทุกอย่างแล้ว! บินไปคราฟต์ข้าวเหนียวมะม่วงจำนวนสูงสุด (%d ชิ้น) ทันที", toCraftPost)
                            craftFoodUnderground("MangoRice", toCraftPost)
                            if state.mangoRice then
                                local mrPost = pDataPost and (pDataPost:GetAttribute("MangoRice") or 0) or 0
                                if mrPost > 0 then
                                    StatusText.Text = string.format("คราฟต์สำเร็จ (มีในตัว %d ชิ้น)! กำลังเดินทางไปขายที่ร้านค้าทันที", mrPost)
                                    sellAtEconomyUnderground("MangoRice")
                                else
                                    StatusText.Text = "ตรวจพบไม่มีข้าวเหนียวมะม่วงในตัว ข้ามการขายและกลับไปตรวจสอบวัตถุดิบ..."
                                end
                            end
                        end
                    end
                end)
                if not mOk then
                    warn("[Nexus Hub] Mango Rice loop error:", mErr)
                    task.wait(1)
                end
            end
            task.wait(0.5)
        end
    end)

    -- =========================================================================
    -- [ AUTO BANANA & BANANAPACK FARM LOOP ]
    -- =========================================================================
    task.spawn(function()
        while myToken.running do
            if isAtServerSelectionScreen() then
                task.wait(1.5)
            elseif state.bananaFarm then
                local bOk, bErr = pcall(function()
                    local pData = LocalPlayer:FindFirstChild("PlayerData")
                    local curBanana = pData and (pData:GetAttribute("Banana") or 0) or 0
                    local curPack = pData and (pData:GetAttribute("BananaPack") or 0) or 0

                    -- Check hunger & thirst
                    if state.autoEat and consumeFood and consumeFood() then
                        task.wait(0.5)
                    end
                    if state.autoDrink and consumeDrink and consumeDrink() then
                        task.wait(0.5)
                    end

                    if not state.bananaFarm then return end

                    -- If we already have BananaPack in inventory, go sell first
                    if curPack > 0 and curBanana < 3 then
                        StatusText.Text = string.format("มีห่อกล้วยอยู่ในตัว (%d ห่อ)! กำลังเดินทางไปขายที่ร้านค้า...", curPack)
                        sellAtEconomyUnderground("BananaPack")
                        task.wait(1)
                        return
                    end

                    -- Step 1: Farm Banana up to 60
                    if curBanana < 60 then
                        if isFarmingActive() then
                            cancelGameFarm()
                            task.wait(0.3)
                        end
                        StatusText.Text = string.format("กำลังบินไปฟาร์มกล้วย (มี %d/60 ผล)...", curBanana)
                        flyUnderground(FARM_COORDS.Banana)
                        if state.bananaFarm then
                            local bananaFolder = workspace:FindFirstChild("Systems") and workspace.Systems.Farm:FindFirstChild("Banana")
                            if bananaFolder then
                                farmItemsUntilTarget(bananaFolder, "Banana", 60, 60, function() return state.bananaFarm end)
                            end
                        end
                    else
                        -- Step 2: Banana reached 60, go process into BananaPack
                        if isFarmingActive() then
                            cancelGameFarm()
                            task.wait(0.3)
                        end
                        StatusText.Text = "ฟาร์มกล้วยครบ 60 ผลแล้ว! กำลังบินไปแปรรูปห่อกล้วย (Process Banana)..."
                        flyUnderground(FARM_COORDS.ProcessBanana)
                        if state.bananaFarm then
                            local char = LocalPlayer.Character
                            local root = char and char:FindFirstChild("HumanoidRootPart")
                            local hum = char and char:FindFirstChild("Humanoid")
                            local procSurface = FARM_COORDS.ProcessBanana
                            if root then
                                local gY, _ = getGroundAt(FARM_COORDS.ProcessBanana.X, FARM_COORDS.ProcessBanana.Z, FARM_COORDS.ProcessBanana.Y)
                                local standY = gY and (gY + 3.39) or FARM_COORDS.ProcessBanana.Y
                                procSurface = Vector3.new(FARM_COORDS.ProcessBanana.X, standY, FARM_COORDS.ProcessBanana.Z)
                                root.CFrame = CFrame.lookAt(procSurface, Vector3.new(2444.32, standY, 4673.39))
                                root.AssemblyLinearVelocity = Vector3.zero
                                root.AssemblyAngularVelocity = Vector3.zero
                                root.Anchored = false
                                updateSafePlatform(procSurface, true)
                                if hum then
                                    hum.PlatformStand = false
                                    pcall(function() hum:ChangeState(Enum.HumanoidStateType.Running) end)
                                end
                                restoreCharacterVisibility()
                            end
                            task.wait(0.3)

                            -- Trigger ProximityPrompt at Process.Banana
                            StatusText.Text = "ถึงจุดแปรรูปกล้วยแล้ว! กำลังกดเริ่มแปรรูปห่อกล้วย (Interact Prompt)..."
                            local prompt = waitForPrompt(function()
                                local procFolder = workspace:FindFirstChild("Systems") and workspace.Systems:FindFirstChild("Process") and workspace.Systems.Process:FindFirstChild("Banana")
                                local pt = procFolder and procFolder:FindFirstChild("Prompt")
                                return (pt and pt:FindFirstChildWhichIsA("ProximityPrompt")) or (procFolder and procFolder:FindFirstChildWhichIsA("ProximityPrompt", true))
                            end, 4)

                            if prompt then
                                if fireproximityprompt then
                                    fireproximityprompt(prompt)
                                end
                                pcall(function()
                                    prompt:InputHoldBegin()
                                    task.wait(prompt.HoldDuration + 0.1)
                                    prompt:InputHoldEnd()
                                end)
                            end
                            task.wait(0.3)
                            pcall(function()
                                Remotes.Fire("_process", "Start", "Banana")
                            end)

                            StatusText.Text = "กำลังแปรรูปห่อกล้วย (BananaPack 100%)..."
                            local pTimeout = 0
                            local lastB = pData and (pData:GetAttribute("Banana") or 0) or 0
                            while state.bananaFarm and pTimeout < 90 do
                                local curB = pData and (pData:GetAttribute("Banana") or 0) or 0
                                local curP = pData and (pData:GetAttribute("BananaPack") or 0) or 0
                                StatusText.Text = string.format("กำลังแปรรูปห่อกล้วย... (เหลือกล้วย %d | ได้ห่อกล้วย %d)", curB, curP)
                                if curB < 3 then
                                    break
                                end
                                if curB ~= lastB then
                                    lastB = curB
                                end
                                if pTimeout % 6 == 0 and curB >= 3 then
                                    pcall(function()
                                        Remotes.Fire("_process", "Start", "Banana")
                                    end)
                                end
                                task.wait(1.5)
                                pTimeout = pTimeout + 1.5
                            end
                            pcall(function()
                                Remotes.Fire("_process", "Stop")
                            end)

                            -- Close process UI
                            local pGui = LocalPlayer:FindFirstChild("PlayerGui")
                            local grp = pGui and pGui:FindFirstChild("Process") and pGui.Process:FindFirstChild("Group")
                            if grp then grp.Visible = false end

                            local exitChar = LocalPlayer.Character
                            local exitRoot = exitChar and exitChar:FindFirstChild("HumanoidRootPart")
                            if exitRoot then
                                exitRoot.Anchored = false
                            end
                            updateSafePlatform(nil, false)
                            StatusText.Text = "แปรรูปห่อกล้วยสำเร็จ! กำลังเดินทางไปขายที่ร้านค้า (Economy)..."
                            task.wait(0.5)

                            -- Step 3: Sell BananaPack at Economy
                            curPack = pData and (pData:GetAttribute("BananaPack") or 0) or 0
                            if curPack > 0 then
                                sellAtEconomyUnderground("BananaPack")
                            end
                            task.wait(1)
                        end
                    end
                end)
                if not bOk then
                    warn("[Nexus Hub] Banana Farm loop error:", bErr)
                    task.wait(1)
                end
            end
            task.wait(0.5)
        end
    end)

    -- =========================================================================
    -- [ AUTO FISHING FARM LOOP ]
    -- =========================================================================
    task.spawn(function()
        while myToken.running do
            if isAtServerSelectionScreen() then
                task.wait(1.5)
            elseif state.fishFarm then
                local fOk, fErr = pcall(function()
                    local pData = LocalPlayer:FindFirstChild("PlayerData")

                    -- Check hunger & thirst
                    if state.autoEat and consumeFood and consumeFood() then
                        task.wait(0.5)
                    end
                    if state.autoDrink and consumeDrink and consumeDrink() then
                        task.wait(0.5)
                    end

                    if not state.fishFarm then return end

                    -- Check inventory fish count (Bettafish + Anglerfish + Sardine)
                    local betta = pData and (pData:GetAttribute("Bettafish") or 0) or 0
                    local angler = pData and (pData:GetAttribute("Anglerfish") or 0) or 0
                    local sardine = pData and (pData:GetAttribute("Sardine") or 0) or 0
                    local totalFish = betta + angler + sardine

                    if totalFish >= 25 then
                        StatusText.Text = string.format("ปลาเต็มกระเป๋า (%d ตัว)! กำลังเดินทางไปขายที่ร้านค้า (Economy)...", totalFish)
                        sellAtEconomyUnderground("Fish")
                        task.wait(1)
                        return
                    end

                    -- Ensure rod tool is equipped or purchased
                    local rodTool = ensureFishingRod()
                    if not rodTool then
                        StatusText.Text = "ไม่พบเบ็ดตกปลา หรือเงินไม่พอซื้อ (ต้องการ 10,000$)"
                        task.wait(3)
                        return
                    end

                    -- Check distance to fishing dock
                    local fishSpot = FARM_COORDS.Fish
                    local char = LocalPlayer.Character
                    local root = char and char:FindFirstChild("HumanoidRootPart")
                    local dist = root and (Vector3.new(root.Position.X, 0, root.Position.Z) - Vector3.new(fishSpot.X, 0, fishSpot.Z)).Magnitude or 9999

                    if dist > 15 then
                        StatusText.Text = "กำลังบินใต้ดินไปยังจุดตกปลาแม่น้ำหลัก..."
                        flyUnderground(fishSpot)
                        if not state.fishFarm then return end
                    end

                    -- Surface onto fishing pier facing water (+Z direction)
                    char = LocalPlayer.Character
                    root = char and char:FindFirstChild("HumanoidRootPart")
                    local hum = char and char:FindFirstChildOfClass("Humanoid")
                    if root and hum and hum.Health > 0 then
                        local gY, _ = getGroundAt(fishSpot.X, fishSpot.Z, fishSpot.Y)
                        local surfacePos = Vector3.new(fishSpot.X, (gY or fishSpot.Y) + 3.2, fishSpot.Z)
                        root.CFrame = CFrame.lookAt(surfacePos, surfacePos + Vector3.new(0, 0, 20))
                        root.AssemblyLinearVelocity = Vector3.zero
                        root.Anchored = false
                        updateSafePlatform(nil, false)
                    end
                    task.wait(0.4)

                    -- Ensure rod is equipped in Character
                    char = LocalPlayer.Character
                    hum = char and char:FindFirstChildOfClass("Humanoid")
                    rodTool = char and (char:FindFirstChild("FishingRodV3") or char:FindFirstChild("FishingRodV2") or char:FindFirstChild("FishingRod"))
                    if not rodTool and hum then
                        local bp = LocalPlayer:FindFirstChild("Backpack")
                        rodTool = bp and (bp:FindFirstChild("FishingRodV3") or bp:FindFirstChild("FishingRodV2") or bp:FindFirstChild("FishingRod"))
                        if rodTool then
                            hum:EquipTool(rodTool)
                            task.wait(0.3)
                        end
                    end

                    if not rodTool or rodTool.Parent ~= char then
                        task.wait(0.5)
                        return
                    end

                    -- Cast fishing rod!
                    StatusText.Text = "กำลังเหวี่ยงเบ็ดตกปลา... รอปลากินเบ็ด"
                    pcall(function() rodTool:Activate() end)
                    task.wait(0.6)

                    -- Wait for Bite or FishingGame UI
                    local castStart = os.clock()
                    while state.fishFarm and (os.clock() - castStart < 35) do
                        local fg = LocalPlayer.PlayerGui:FindFirstChild("FishingGame")
                        if fg and fg:FindFirstChild("Minigame") then
                            StatusText.Text = "ปลากินเบ็ดแล้ว! กำลังดึงเบ็ดอัตโนมัติ (Auto Win)..."

                            local mg = fg.Minigame
                            local gameFrame = mg:FindFirstChild("Game")
                            local point = gameFrame and gameFrame:FindFirstChild("Point")
                            local fish = mg:FindFirstChild("Fish")

                            local minigameStart = os.clock()
                            while state.fishFarm and fg and fg.Parent and (os.clock() - minigameStart < 8) do
                                -- Keep Point centered on Fish
                                pcall(function()
                                    if point and fish then
                                        point.Position = UDim2.new(point.Position.X.Scale, point.Position.X.Offset, fish.Position.Y.Scale, 0)
                                    end
                                    local vim = game:GetService("VirtualInputManager")
                                    if vim and point and fish then
                                        if point.AbsolutePosition.Y > fish.AbsolutePosition.Y then
                                            vim:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
                                        else
                                            vim:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
                                        end
                                    end
                                end)

                                -- Remote auto-finish safety once past min game threshold
                                if os.clock() - minigameStart >= 2.0 then
                                    if _G.NexusFishingToken then
                                        pcall(function()
                                            Remotes.Fire("_fishing", "Result", true, _G.NexusFishingToken)
                                        end)
                                    end
                                end

                                task.wait(0.03)
                                fg = LocalPlayer.PlayerGui:FindFirstChild("FishingGame")
                            end

                            -- Release Space key
                            pcall(function()
                                game:GetService("VirtualInputManager"):SendKeyEvent(false, Enum.KeyCode.Space, false, game)
                            end)

                            StatusText.Text = "ตกปลาสำเร็จ! ได้รับปลาเรียบร้อย"
                            task.wait(1.2)
                            break
                        end

                        task.wait(0.2)
                    end

                    task.wait(0.8)
                end)
                if not fOk then
                    warn("[Nexus Hub] Fishing loop error:", fErr)
                    task.wait(1)
                end
            end
            task.wait(0.5)
        end
    end)

    -- Section Cards Helper
    local swSection, mrSection, bananaSection, fishingSection, rockSection, svibSection, vaultSection

    local LABEL_MAP = {
        ["rbxassetid://73033354129137"] = "ขนมปัง x3",
        ["rbxassetid://118207121583641"] = "ซอส x2",
        ["rbxassetid://134982296920775"] = "หมู x2",
        ["rbxassetid://124088933252520"] = "มะม่วง x2",
        ["rbxassetid://100600116558646"] = "ข้าว x3",
        ["rbxassetid://84273609389156"] = "กล้วย x4",
        ["rbxassetid://108479853811237"] = "เบ็ด V1",
        ["rbxassetid://71503351723129"] = "เบ็ด V2",
        ["rbxassetid://86134830359297"] = "เบ็ด V3",
        ["rbxassetid://94553259692482"] = "ที่ขุดแร่"
    }

    local function createSectionCard(parent, title, desc, onToggle, initialVal, iconId, subIcons)
        local hasSub = subIcons and #subIcons > 0
        local cardHeight = hasSub and 82 or 54

        local Card = Instance.new("Frame")
        Card.Name = "CardSection"
        Card.Size = UDim2.new(1, -10, 0, cardHeight)
        Card.BackgroundColor3 = Color3.fromRGB(18, 27, 38)
        Card.BorderSizePixel = 0
        Card.Parent = parent

        local CCorner = Instance.new("UICorner")
        CCorner.CornerRadius = UDim.new(0, 8)
        CCorner.Parent = Card

        local CStroke = Instance.new("UIStroke")
        CStroke.Color = Color3.fromRGB(36, 54, 76)
        CStroke.Thickness = 1.2
        CStroke.Parent = Card

        -- Header Frame
        local Header = Instance.new("Frame")
        Header.Size = UDim2.new(1, 0, 0, 48)
        Header.BackgroundTransparency = 1
        Header.Parent = Card

        local iconOffset = 12
        if iconId then
            local IconBadge = Instance.new("Frame")
            IconBadge.Size = UDim2.new(0, 36, 0, 36)
            IconBadge.Position = UDim2.new(0, 10, 0, 6)
            IconBadge.BackgroundColor3 = Color3.fromRGB(25, 38, 54)
            IconBadge.BorderSizePixel = 0
            IconBadge.Parent = Header

            local IBCorner = Instance.new("UICorner")
            IBCorner.CornerRadius = UDim.new(0, 8)
            IBCorner.Parent = IconBadge

            local IBStroke = Instance.new("UIStroke")
            IBStroke.Color = Color3.fromRGB(48, 74, 104)
            IBStroke.Thickness = 1
            IBStroke.Parent = IconBadge

            local HIcon = Instance.new("ImageLabel")
            HIcon.Name = "HeaderIcon"
            HIcon.Size = UDim2.new(1, -6, 1, -6)
            HIcon.Position = UDim2.new(0, 3, 0, 3)
            HIcon.BackgroundTransparency = 1
            HIcon.Image = iconId
            HIcon.ScaleType = Enum.ScaleType.Fit
            HIcon.Parent = IconBadge

            iconOffset = 54
        end

        local TextContainer = Instance.new("Frame")
        TextContainer.Position = UDim2.new(0, iconOffset, 0, 6)
        TextContainer.Size = UDim2.new(1, -iconOffset - 96, 0, 36)
        TextContainer.BackgroundTransparency = 1
        TextContainer.Parent = Header

        local HText = Instance.new("TextLabel")
        HText.Text = title
        HText.Font = Enum.Font.GothamBold
        HText.TextSize = 12
        HText.TextColor3 = white
        HText.Size = UDim2.new(1, 0, 0, 18)
        HText.TextXAlignment = Enum.TextXAlignment.Left
        HText.TextTruncate = Enum.TextTruncate.AtEnd
        HText.BackgroundTransparency = 1
        HText.Parent = TextContainer

        local DescLabel = Instance.new("TextLabel")
        DescLabel.Text = desc
        DescLabel.Font = Enum.Font.GothamMedium
        DescLabel.TextSize = 10
        DescLabel.TextColor3 = Color3.fromRGB(140, 180, 215)
        DescLabel.Position = UDim2.new(0, 0, 0, 18)
        DescLabel.Size = UDim2.new(1, 0, 0, 16)
        DescLabel.TextXAlignment = Enum.TextXAlignment.Left
        DescLabel.TextTruncate = Enum.TextTruncate.AtEnd
        DescLabel.BackgroundTransparency = 1
        DescLabel.Parent = TextContainer

        -- Modern Pill Toggle Switch
        local isToggled = initialVal or false
        local Toggle = Instance.new("TextButton")
        Toggle.Text = isToggled and "เปิด (ON)" or "ปิด (OFF)"
        Toggle.Font = Enum.Font.GothamBold
        Toggle.TextSize = 10
        Toggle.TextColor3 = isToggled and Color3.fromRGB(10, 20, 30) or white
        Toggle.Size = UDim2.new(0, 78, 0, 26)
        Toggle.Position = UDim2.new(1, -88, 0, 11)
        Toggle.BackgroundColor3 = isToggled and accent or Color3.fromRGB(36, 52, 70)
        Toggle.BorderSizePixel = 0
        Toggle.Parent = Header

        local TCorner = Instance.new("UICorner")
        TCorner.CornerRadius = UDim.new(0, 13)
        TCorner.Parent = Toggle

        local TStroke = Instance.new("UIStroke")
        TStroke.Color = isToggled and Color3.fromRGB(100, 240, 255) or Color3.fromRGB(50, 72, 95)
        TStroke.Thickness = 1
        TStroke.Parent = Toggle

        -- SubIcons / Ingredients Chips (Bottom of Card)
        if hasSub then
            local Divider = Instance.new("Frame")
            Divider.Size = UDim2.new(1, -20, 0, 1)
            Divider.Position = UDim2.new(0, 10, 0, 48)
            Divider.BackgroundColor3 = Color3.fromRGB(28, 42, 58)
            Divider.BorderSizePixel = 0
            Divider.Parent = Card

            local SubBar = Instance.new("Frame")
            SubBar.Name = "SubIcons"
            SubBar.Size = UDim2.new(1, -20, 0, 26)
            SubBar.Position = UDim2.new(0, 10, 0, 51)
            SubBar.BackgroundTransparency = 1
            SubBar.Parent = Card

            local SubLayout = Instance.new("UIListLayout")
            SubLayout.FillDirection = Enum.FillDirection.Horizontal
            SubLayout.VerticalAlignment = Enum.VerticalAlignment.Center
            SubLayout.Padding = UDim.new(0, 6)
            SubLayout.Parent = SubBar

            for _, subId in ipairs(subIcons) do
                local Chip = Instance.new("Frame")
                Chip.Size = UDim2.new(0, 84, 0, 22)
                Chip.BackgroundColor3 = Color3.fromRGB(24, 36, 50)
                Chip.BorderSizePixel = 0
                Chip.Parent = SubBar

                local ChipCorner = Instance.new("UICorner")
                ChipCorner.CornerRadius = UDim.new(0, 5)
                ChipCorner.Parent = Chip

                local ChipStroke = Instance.new("UIStroke")
                ChipStroke.Color = Color3.fromRGB(40, 60, 82)
                ChipStroke.Thickness = 1
                ChipStroke.Parent = Chip

                local cImg = Instance.new("ImageLabel")
                cImg.Size = UDim2.new(0, 16, 0, 16)
                cImg.Position = UDim2.new(0, 3, 0.5, -8)
                cImg.BackgroundTransparency = 1
                cImg.Image = subId
                cImg.ScaleType = Enum.ScaleType.Fit
                cImg.Parent = Chip

                local cLbl = Instance.new("TextLabel")
                cLbl.Text = LABEL_MAP[subId] or "ไอเทม"
                cLbl.Font = Enum.Font.GothamMedium
                cLbl.TextSize = 9
                cLbl.TextColor3 = white
                cLbl.Position = UDim2.new(0, 22, 0, 0)
                cLbl.Size = UDim2.new(1, -24, 1, 0)
                cLbl.TextXAlignment = Enum.TextXAlignment.Left
                cLbl.BackgroundTransparency = 1
                cLbl.Parent = Chip
            end
        end

        local function setVisual(val)
            isToggled = val
            local targetBg = isToggled and accent or Color3.fromRGB(36, 52, 70)
            local targetText = isToggled and Color3.fromRGB(10, 20, 30) or white
            local targetStroke = isToggled and Color3.fromRGB(100, 240, 255) or Color3.fromRGB(50, 72, 95)
            Toggle.Text = isToggled and "เปิด (ON)" or "ปิด (OFF)"
            TweenService:Create(Toggle, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundColor3 = targetBg,
                TextColor3 = targetText
            }):Play()
            TweenService:Create(TStroke, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Color = targetStroke
            }):Play()
            -- Micro tactile bounce
            Toggle.Size = UDim2.new(0, 72, 0, 24)
            Toggle.Position = UDim2.new(1, -85, 0, 12)
            TweenService:Create(Toggle, TweenInfo.new(0.24, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 78, 0, 26),
                Position = UDim2.new(1, -88, 0, 11)
            }):Play()
        end

        Toggle.MouseEnter:Connect(function()
            if not isToggled then
                TweenService:Create(Toggle, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(48, 68, 88)}):Play()
            else
                TweenService:Create(Toggle, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(150, 235, 255)}):Play()
            end
        end)
        Toggle.MouseLeave:Connect(function()
            local targetBg = isToggled and accent or Color3.fromRGB(36, 52, 70)
            TweenService:Create(Toggle, TweenInfo.new(0.15), {BackgroundColor3 = targetBg}):Play()
        end)

        Toggle.MouseButton1Click:Connect(function()
            setVisual(not isToggled)
            onToggle(isToggled)
            if state.autoSaveConfig and saveConfig then saveConfig() end
        end)

        return {
            set = function(val)
                setVisual(val)
                onToggle(val)
            end,
            setVisualOnly = function(val)
                setVisual(val)
            end
        }
    end

    swSection = createSectionCard(farmTab, "ฟาร์มแซนด์วิชอัตโนมัติ (คราฟต์สูงสุด)", "สูตร: ขนมปัง 3 + ซอส 2 + เนื้อหมู 2 (คราฟต์จำนวนมากที่สุดทันที)", function(val)
        state.sandwich = val
        if val then
            state.mangoRice = false
            state.bananaFarm = false
            state.fishFarm = false
            state.rockFarm = false
            state.svibFarm = false
            state.stopRequested = false
            isConsuming = false
            isRestocking = false
            state.isFlying = false
            StatusText.Text = "เปิดฟาร์มแซนด์วิชแล้ว! กำลังบินไปฟาร์มทันที..."
            if mrSection then mrSection.setVisualOnly(false) end
            if bananaSection then bananaSection.setVisualOnly(false) end
            if fishingSection then fishingSection.setVisualOnly(false) end
            if rockSection then rockSection.setVisualOnly(false) end
            if svibSection then svibSection.setVisualOnly(false) end
        else
            if not state.mangoRice and not state.bananaFarm and not state.fishFarm and not state.rockFarm and not state.svibFarm then
                state.stopRequested = true
                StatusText.Text = "สถานะ: ปิดการทำงานเรียบร้อย (ยกเลิกฟาร์มทันที)"
                cancelGameFarm()
            end
        end
    end, state.sandwich, "rbxassetid://97979228888843", {"rbxassetid://73033354129137", "rbxassetid://118207121583641", "rbxassetid://134982296920775"})

    mrSection = createSectionCard(farmTab, "ฟาร์มข้าวเหนียวมะม่วงอัตโนมัติ (คราฟต์สูงสุด)", "สูตร: มะม่วง 2 + ข้าว 3 (คราฟต์จำนวนมากที่สุดทันที)", function(val)
        state.mangoRice = val
        if val then
            state.sandwich = false
            state.bananaFarm = false
            state.fishFarm = false
            state.rockFarm = false
            state.svibFarm = false
            state.stopRequested = false
            isConsuming = false
            isRestocking = false
            state.isFlying = false
            StatusText.Text = "เปิดฟาร์มข้าวเหนียวมะม่วงแล้ว! กำลังบินไปฟาร์มทันที..."
            if swSection then swSection.setVisualOnly(false) end
            if bananaSection then bananaSection.setVisualOnly(false) end
            if fishingSection then fishingSection.setVisualOnly(false) end
            if rockSection then rockSection.setVisualOnly(false) end
            if svibSection then svibSection.setVisualOnly(false) end
        else
            if not state.sandwich and not state.bananaFarm and not state.fishFarm and not state.rockFarm and not state.svibFarm then
                state.stopRequested = true
                StatusText.Text = "สถานะ: ปิดการทำงานเรียบร้อย (ยกเลิกฟาร์มทันที)"
                cancelGameFarm()
            end
        end
    end, state.mangoRice, "rbxassetid://70943629941899", {"rbxassetid://124088933252520", "rbxassetid://100600116558646"})

    bananaSection = createSectionCard(farmTab, "ฟาร์มกล้วย & แปรรูปห่อกล้วยอัตโนมัติ (Banana & BananaPack)", "สูตร: กล้วย 4 ผล แปรรูปเป็น BananaPack 1 ห่อ (อัตราสำเร็จ 100% ขายห่อละ 200-250$)", function(val)
        state.bananaFarm = val
        if val then
            state.sandwich = false
            state.mangoRice = false
            state.fishFarm = false
            state.rockFarm = false
            state.svibFarm = false
            state.stopRequested = false
            isConsuming = false
            isRestocking = false
            state.isFlying = false
            StatusText.Text = "เปิดฟาร์มกล้วยแล้ว! กำลังบินไปฟาร์มทันที..."
            if swSection then swSection.setVisualOnly(false) end
            if mrSection then mrSection.setVisualOnly(false) end
            if fishingSection then fishingSection.setVisualOnly(false) end
            if rockSection then rockSection.setVisualOnly(false) end
            if svibSection then svibSection.setVisualOnly(false) end
        else
            if not state.sandwich and not state.mangoRice and not state.fishFarm and not state.rockFarm and not state.svibFarm then
                state.stopRequested = true
                StatusText.Text = "สถานะ: ปิดการทำงานเรียบร้อย (ยกเลิกฟาร์มทันที)"
                cancelGameFarm()
            end
            pcall(function()
                Remotes.Fire("_process", "Stop")
            end)
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root then root.Anchored = false end
            updateSafePlatform(nil, false)
        end
    end, state.bananaFarm, "rbxassetid://73719777510289", {"rbxassetid://84273609389156"})

    fishingSection = createSectionCard(fishTab, "ระบบตกปลาอัตโนมัติ (Auto Fishing & Auto Sell)", "เหวี่ยงเบ็ดอัตโนมัติ + ดึงปลาชนะ 100% + เดินทางขายปลาอัตโนมัติเมื่อปลาเต็ม (ซื้อเบ็ดให้อัตโนมัติ)", function(val)
        state.fishFarm = val
        if val then
            state.sandwich = false
            state.mangoRice = false
            state.bananaFarm = false
            state.rockFarm = false
            state.svibFarm = false
            state.stopRequested = false
            isConsuming = false
            isRestocking = false
            state.isFlying = false
            StatusText.Text = "เปิดระบบตกปลาอัตโนมัติแล้ว! กำลังเตรียมเบ็ดและเดินทางไปจุดตกปลา..."
            if swSection then swSection.setVisualOnly(false) end
            if mrSection then mrSection.setVisualOnly(false) end
            if bananaSection then bananaSection.setVisualOnly(false) end
            if rockSection then rockSection.setVisualOnly(false) end
            if svibSection then svibSection.setVisualOnly(false) end
        else
            if not state.sandwich and not state.mangoRice and not state.bananaFarm and not state.rockFarm and not state.svibFarm then
                state.stopRequested = true
                StatusText.Text = "สถานะ: ปิดการทำงานเรียบร้อย (ยกเลิกตกปลาทันที)"
                cancelGameFarm()
            end
        end
    end, state.fishFarm, "rbxassetid://98178293197940", {"rbxassetid://108479853811237", "rbxassetid://71503351723129", "rbxassetid://86134830359297"})

    -- Fish Info Card in fishTab
    do
        local FishInfoCard = Instance.new("Frame")
        FishInfoCard.Size = UDim2.new(1, -10, 0, 115)
        FishInfoCard.BackgroundColor3 = panel
        FishInfoCard.BorderSizePixel = 0
        FishInfoCard.Parent = fishTab
        local FICorner = Instance.new("UICorner")
        FICorner.CornerRadius = UDim.new(0, 6)
        FICorner.Parent = FishInfoCard
        local FIStroke = Instance.new("UIStroke")
        FIStroke.Color = borderColor
        FIStroke.Parent = FishInfoCard

        local FITitle = Instance.new("TextLabel")
        FITitle.Text = "ข้อมูลระบบตกปลา (Fishing System Status)"
        FITitle.Font = Enum.Font.GothamBold
        FITitle.TextSize = 11
        FITitle.TextColor3 = accent
        FITitle.Position = UDim2.new(0, 12, 0, 8)
        FITitle.Size = UDim2.new(1, -24, 0, 16)
        FITitle.TextXAlignment = Enum.TextXAlignment.Left
        FITitle.BackgroundTransparency = 1
        FITitle.Parent = FishInfoCard

        local rawRodStatus = Instance.new("TextLabel")
        rawRodStatus.Text = "เบ็ดตกปลา: กำลังตรวจจับ..."
        rawRodStatus.Font = Enum.Font.GothamMedium
        rawRodStatus.TextSize = 10
        rawRodStatus.TextColor3 = white
        rawRodStatus.Position = UDim2.new(0, 12, 0, 28)
        rawRodStatus.Size = UDim2.new(1, -24, 0, 16)
        rawRodStatus.TextXAlignment = Enum.TextXAlignment.Left
        rawRodStatus.BackgroundTransparency = 1
        rawRodStatus.Parent = FishInfoCard

        RodStatusText = setmetatable({}, {
            __index = function(_, k) return (rawRodStatus and rawRodStatus.Parent) and rawRodStatus[k] or nil end,
            __newindex = function(_, k, v) if rawRodStatus and rawRodStatus.Parent then pcall(function() rawRodStatus[k] = v end) end end
        })

        local rawFishCount = Instance.new("TextLabel")
        rawFishCount.Text = "ปลากัด (Betta): 0 | ปลาแองเกลอร์: 0 | ปลาซาร์ดีน: 0 (รวม: 0/25)"
        rawFishCount.Font = Enum.Font.Gotham
        rawFishCount.TextSize = 10
        rawFishCount.TextColor3 = muted
        rawFishCount.Position = UDim2.new(0, 12, 0, 48)
        rawFishCount.Size = UDim2.new(1, -24, 0, 16)
        rawFishCount.TextXAlignment = Enum.TextXAlignment.Left
        rawFishCount.BackgroundTransparency = 1
        rawFishCount.Parent = FishInfoCard

        FishCountText = setmetatable({}, {
            __index = function(_, k) return (rawFishCount and rawFishCount.Parent) and rawFishCount[k] or nil end,
            __newindex = function(_, k, v) if rawFishCount and rawFishCount.Parent then pcall(function() rawFishCount[k] = v end) end end
        })

        local FishSpotText = Instance.new("TextLabel")
        FishSpotText.Text = "จุดตกปลา: ท่าเรือแม่น้ำหลัก (X: 437, Y: 31, Z: -3004)"
        FishSpotText.Font = Enum.Font.Gotham
        FishSpotText.TextSize = 10
        FishSpotText.TextColor3 = muted
        FishSpotText.Position = UDim2.new(0, 12, 0, 68)
        FishSpotText.Size = UDim2.new(1, -24, 0, 16)
        FishSpotText.TextXAlignment = Enum.TextXAlignment.Left
        FishSpotText.BackgroundTransparency = 1
        FishSpotText.Parent = FishInfoCard

        local FishFeatureText = Instance.new("TextLabel")
        FishFeatureText.Text = "ฟังก์ชันพิเศษ: ดักจับ Bite Token ทันที + Virtual Space Tracking (ชนะ 100%)"
        FishFeatureText.Font = Enum.Font.Gotham
        FishFeatureText.TextSize = 9
        FishFeatureText.TextColor3 = accent
        FishFeatureText.Position = UDim2.new(0, 12, 0, 88)
        FishFeatureText.Size = UDim2.new(1, -24, 0, 16)
        FishFeatureText.TextXAlignment = Enum.TextXAlignment.Left
        FishFeatureText.BackgroundTransparency = 1
        FishFeatureText.Parent = FishInfoCard
    end

    do
        local QuickFishSellRow = Instance.new("Frame")
        QuickFishSellRow.Size = UDim2.new(1, -10, 0, 42)
        QuickFishSellRow.BackgroundColor3 = panel
        QuickFishSellRow.BorderSizePixel = 0
        QuickFishSellRow.Parent = fishTab
        local QFSCorner = Instance.new("UICorner")
        QFSCorner.CornerRadius = UDim.new(0, 4)
        QFSCorner.Parent = QuickFishSellRow

        local QFSTitle = Instance.new("TextLabel")
        QFSTitle.Text = "ขายปลาที่ร้านค้าทันที (Quick Sell All Fish)"
        QFSTitle.Font = Enum.Font.GothamBold
        QFSTitle.TextSize = 11
        QFSTitle.TextColor3 = white
        QFSTitle.Position = UDim2.new(0, 10, 0, 4)
        QFSTitle.Size = UDim2.new(1, -110, 0, 16)
        QFSTitle.TextXAlignment = Enum.TextXAlignment.Left
        QFSTitle.BackgroundTransparency = 1
        QFSTitle.Parent = QuickFishSellRow

        local QFSSub = Instance.new("TextLabel")
        QFSSub.Text = "เดินทางไปร้าน Economy บนดินเพื่อขายปลาทั้งหมดในกระเป๋าและรับเงินทันที"
        QFSSub.Font = Enum.Font.Gotham
        QFSSub.TextSize = 9
        QFSSub.TextColor3 = muted
        QFSSub.Position = UDim2.new(0, 10, 0, 22)
        QFSSub.Size = UDim2.new(1, -110, 0, 14)
        QFSSub.TextXAlignment = Enum.TextXAlignment.Left
        QFSSub.BackgroundTransparency = 1
        QFSSub.Parent = QuickFishSellRow

        local QFSBtn = Instance.new("TextButton")
        QFSBtn.Text = "ขายปลาทันที"
        QFSBtn.Font = Enum.Font.GothamBold
        QFSBtn.TextSize = 10
        QFSBtn.TextColor3 = Color3.fromRGB(10, 20, 30)
        QFSBtn.Size = UDim2.new(0, 90, 0, 26)
        QFSBtn.Position = UDim2.new(1, -100, 0.5, -13)
        QFSBtn.BackgroundColor3 = accent
        QFSBtn.BorderSizePixel = 0
        QFSBtn.Parent = QuickFishSellRow
        local QFSC = Instance.new("UICorner")
        QFSC.CornerRadius = UDim.new(0, 4)
        QFSC.Parent = QFSBtn

        QFSBtn.MouseButton1Click:Connect(function()
            if state.isFlying or state.isManualAction then return end
            task.spawn(function()
                state.isManualAction = true
                cancelGameFarm()
                task.wait(0.2)
                sellAtEconomyUnderground("Fish")
                state.isManualAction = false
            end)
        end)
    end

    do
        local QuickSellRow = Instance.new("Frame")
        QuickSellRow.Size = UDim2.new(1, -10, 0, 42)
        QuickSellRow.BackgroundColor3 = panel
        QuickSellRow.BorderSizePixel = 0
        QuickSellRow.Parent = farmTab
        local QSCorner = Instance.new("UICorner")
        QSCorner.CornerRadius = UDim.new(0, 4)
        QSCorner.Parent = QuickSellRow

        local QSTitle = Instance.new("TextLabel")
        QSTitle.Text = "ขายสินค้าที่ร้านค้าทันที (Economy)"
        QSTitle.Font = Enum.Font.GothamBold
        QSTitle.TextSize = 11
        QSTitle.TextColor3 = white
        QSTitle.Position = UDim2.new(0, 10, 0, 4)
        QSTitle.Size = UDim2.new(1, -110, 0, 16)
        QSTitle.TextXAlignment = Enum.TextXAlignment.Left
        QSTitle.BackgroundTransparency = 1
        QSTitle.Parent = QuickSellRow

        local QSSub = Instance.new("TextLabel")
        QSSub.Text = "เดินทางไป Economy แล้วกดขายสินค้าทั้งหมดทันที"
        QSSub.Font = Enum.Font.Gotham
        QSSub.TextSize = 9
        QSSub.TextColor3 = muted
        QSSub.Position = UDim2.new(0, 10, 0, 22)
        QSSub.Size = UDim2.new(1, -110, 0, 14)
        QSSub.TextXAlignment = Enum.TextXAlignment.Left
        QSSub.BackgroundTransparency = 1
        QSSub.Parent = QuickSellRow

        local QSBtn = Instance.new("TextButton")
        QSBtn.Text = "ขายทันที"
        QSBtn.Font = Enum.Font.GothamBold
        QSBtn.TextSize = 10
        QSBtn.TextColor3 = Color3.fromRGB(10, 20, 30)
        QSBtn.BackgroundColor3 = accent
        QSBtn.Size = UDim2.new(0, 80, 0, 26)
        QSBtn.Position = UDim2.new(1, -90, 0.5, -13)
        QSBtn.BorderSizePixel = 0
        QSBtn.Parent = QuickSellRow
        local QSC = Instance.new("UICorner")
        QSC.CornerRadius = UDim.new(0, 4)
        QSC.Parent = QSBtn

        makeButtonSmooth(QSBtn)

        QSBtn.MouseButton1Click:Connect(function()
            task.spawn(function()
                state.isManualAction = true
                state.stopRequested = false
                sellAtEconomyUnderground(nil)
                state.isManualAction = false
            end)
        end)
    end

    ------------------------------------------------------------------------
    -- TAB 2: MINING & CRAFTING
    ------------------------------------------------------------------------
    do
        local MineStatusCard = Instance.new("Frame")
        MineStatusCard.Size = UDim2.new(1, -10, 0, 115)
        MineStatusCard.BackgroundColor3 = panel
        MineStatusCard.BorderSizePixel = 0
        MineStatusCard.Parent = mineTab
        local MStatCorner = Instance.new("UICorner")
        MStatCorner.CornerRadius = UDim.new(0, 6)
        MStatCorner.Parent = MineStatusCard
        local MStatStroke = Instance.new("UIStroke")
        MStatStroke.Color = borderColor
        MStatStroke.Parent = MineStatusCard

        local MTitle = Instance.new("TextLabel")
        MTitle.Text = "คลังแร่ & วัตถุดิบคราฟต์"
        MTitle.Font = Enum.Font.GothamBold
        MTitle.TextSize = 11
        MTitle.TextColor3 = accent
        MTitle.Position = UDim2.new(0, 12, 0, 8)
        MTitle.Size = UDim2.new(1, -24, 0, 16)
        MTitle.TextXAlignment = Enum.TextXAlignment.Left
        MTitle.BackgroundTransparency = 1
        MTitle.Parent = MineStatusCard

        local OreText1 = Instance.new("TextLabel")
        OreText1.Text = "หิน: 0 | เหล็ก: 0 | ทอง: 0 | เพชร: 0"
        OreText1.Font = Enum.Font.GothamMedium
        OreText1.TextSize = 10
        OreText1.TextColor3 = white
        OreText1.Position = UDim2.new(0, 12, 0, 28)
        OreText1.Size = UDim2.new(1, -24, 0, 16)
        OreText1.TextXAlignment = Enum.TextXAlignment.Left
        OreText1.BackgroundTransparency = 1
        OreText1.Parent = MineStatusCard

        local OreText2 = Instance.new("TextLabel")
        OreText2.Text = "ไวเบรเนียมดิบ: 0 | ไวเบรเนียมหลอม: 0 | เงินสด: 0"
        OreText2.Font = Enum.Font.GothamMedium
        OreText2.TextSize = 10
        OreText2.TextColor3 = muted
        OreText2.Position = UDim2.new(0, 12, 0, 48)
        OreText2.Size = UDim2.new(1, -24, 0, 16)
        OreText2.TextXAlignment = Enum.TextXAlignment.Left
        OreText2.BackgroundTransparency = 1
        OreText2.Parent = MineStatusCard

        local EquipText = Instance.new("TextLabel")
        EquipText.Text = "เกราะ: 0 | ยาชุบ: 0 | ยาแก้ปวด: 0"
        EquipText.Font = Enum.Font.GothamMedium
        EquipText.TextSize = 10
        EquipText.TextColor3 = accent
        EquipText.Position = UDim2.new(0, 12, 0, 68)
        EquipText.Size = UDim2.new(1, -24, 0, 16)
        EquipText.TextXAlignment = Enum.TextXAlignment.Left
        EquipText.BackgroundTransparency = 1
        EquipText.Parent = MineStatusCard

        local VaultText = Instance.new("TextLabel")
        VaultText.Text = "ตู้เซฟ: กำลังตรวจสอบ..."
        VaultText.Font = Enum.Font.GothamMedium
        VaultText.TextSize = 10
        VaultText.TextColor3 = white
        VaultText.Position = UDim2.new(0, 12, 0, 88)
        VaultText.Size = UDim2.new(1, -24, 0, 16)
        VaultText.TextXAlignment = Enum.TextXAlignment.Left
        VaultText.BackgroundTransparency = 1
        VaultText.Parent = MineStatusCard

        task.spawn(function()
            while myToken.running do
                pcall(function()
                    local pData = LocalPlayer:FindFirstChild("PlayerData")
                    if pData then
                        local r = pData:GetAttribute("Rock") or 0
                        local ir = pData:GetAttribute("Iron") or 0
                        local go = pData:GetAttribute("Gold") or 0
                        local di = pData:GetAttribute("Diamond") or 0
                        local sv = pData:GetAttribute("Svibranium") or 0
                        local vb = pData:GetAttribute("Vibranium") or 0
                        local mo = pData:GetAttribute("Money") or 0
                        local ar = pData:GetAttribute("Armor") or 0
                        local ae = pData:GetAttribute("Aed") or 0
                        local pk = pData:GetAttribute("Painkiller") or 0
                        OreText1.Text = string.format("หิน: %d | เหล็ก: %d | ทอง: %d | เพชร: %d", r, ir, go, di)
                        OreText2.Text = string.format("ไวเบรเนียมดิบ: %d | ไวเบรเนียมหลอม: %d | พิกแอ็กซ์: %s", sv, vb, hasPickaxe() and "มีพร้อมใช้งาน" or "ไม่มี (จะซื้อให้อัตโนมัติ)")
                        EquipText.Text = string.format("เกราะ: %d | ยาชุบ: %d | ยาแก้ปวด: %d | เงินสด: %s$", ar, ae, pk, tostring(mo))

                        local vStat = getVaultStatus()
                        if vStat.hasVault then
                            VaultText.TextColor3 = accent
                            VaultText.Text = string.format("ตู้เซฟ: %s", vStat.displayStatus)
                        else
                            VaultText.TextColor3 = Color3.fromRGB(255, 175, 150)
                            VaultText.Text = string.format("ตู้เซฟ: %s", vStat.displayStatus)
                        end
                    end
                end)
                task.wait(0.5)
            end
        end)
    end

    -- Auto Mining & Processing Loop (Rock)
    task.spawn(function()
        while myToken.running do
            if isAtServerSelectionScreen() then
                task.wait(1.5)
            elseif state.rockFarm then
                if not ensurePickaxe() then
                    task.wait(2)
                else
                    local pData = LocalPlayer:FindFirstChild("PlayerData")
                    local r = pData and pData:GetAttribute("Rock") or 0

                    if r < 120 then
                        StatusText.Text = "กำลังเดินทางไป เหมืองหิน (Rock)"
                        flyUnderground(FARM_COORDS.Rock)
                        if state.rockFarm then
                            local rockFolder = workspace:FindFirstChild("Systems") and workspace.Systems.Farm:FindFirstChild("Rock")
                            if rockFolder then
                                StatusText.Text = "กำลังขุดหินใต้ดิน..."
                                farmItemsUntilTarget(rockFolder, "Rock", 120, 120, function() return state.rockFarm end)
                            end
                        end
                    else
                        cancelGameFarm()
                        StatusText.Text = "หินครบ 120 ก้อน! กำลังบินไปเตาหลอมแร่ (Process)"
                        flyUnderground(FARM_COORDS.ProcessRock)
                        if state.rockFarm then
                            local char = LocalPlayer.Character
                            local root = char and char:FindFirstChild("HumanoidRootPart")
                            local hum = char and char:FindFirstChild("Humanoid")
                            if root then
                                local standPos = FARM_COORDS.ProcessRock
                                root.CFrame = CFrame.new(standPos)
                                root.AssemblyLinearVelocity = Vector3.zero
                                root.AssemblyAngularVelocity = Vector3.zero
                                root.Anchored = false
                                updateSafePlatform(standPos, true)
                                if hum then
                                    hum.PlatformStand = false
                                    pcall(function() hum:ChangeState(Enum.HumanoidStateType.Running) end)
                                end
                                updateSafePlatform(procSurface, true)
                                restoreCharacterVisibility()
                            end
                            task.wait(0.3)

                            -- Trigger ProximityPrompt at Process.Rock
                            StatusText.Text = "ถึงเตาหลอมแล้ว! กำลังกดเริ่มแปรรูปหิน (Interact Prompt)..."
                            local prompt = waitForPrompt(function()
                                local procFolder = workspace:FindFirstChild("Systems") and workspace.Systems:FindFirstChild("Process") and workspace.Systems.Process:FindFirstChild("Rock")
                                local pt = procFolder and procFolder:FindFirstChild("Prompt")
                                return (pt and pt:FindFirstChildWhichIsA("ProximityPrompt")) or (procFolder and procFolder:FindFirstChildWhichIsA("ProximityPrompt", true))
                            end, 4)

                            if prompt then
                                if fireproximityprompt then
                                    fireproximityprompt(prompt)
                                end
                                pcall(function()
                                    prompt:InputHoldBegin()
                                    task.wait(prompt.HoldDuration + 0.1)
                                    prompt:InputHoldEnd()
                                end)
                            end
                            task.wait(0.3)
                            pcall(function()
                                Remotes.Fire("_process", "Start", "Rock")
                            end)

                            StatusText.Text = "กำลังหลอมหินเป็น เหล็ก/ทอง/เพชร..."
                            local pTimeout = 0
                            local lastR = pData and (pData:GetAttribute("Rock") or 0) or 0
                            while state.rockFarm and pTimeout < 240 do
                                local curR = pData and (pData:GetAttribute("Rock") or 0) or 0
                                local curIr = pData and (pData:GetAttribute("Iron") or 0) or 0
                                local curGo = pData and (pData:GetAttribute("Gold") or 0) or 0
                                local curDi = pData and (pData:GetAttribute("Diamond") or 0) or 0
                                StatusText.Text = string.format("กำลังหลอมหิน... (เหลือหิน %d | เหล็ก %d | ทอง %d | เพชร %d)", curR, curIr, curGo, curDi)

                                if curR < 2 then
                                    break
                                end

                                -- Watchdog: หากผ่านไป 5 วิ แล้วหินไม่ลด ให้กดซ้ำ
                                if pTimeout % 5 == 0 and pTimeout > 0 and curR >= lastR then
                                    if prompt and fireproximityprompt then
                                        fireproximityprompt(prompt)
                                    end
                                    pcall(function()
                                        Remotes.Fire("_process", "Start", "Rock")
                                    end)
                                end
                                lastR = curR

                                task.wait(1)
                                pTimeout = pTimeout + 1
                            end

                            pcall(function()
                                Remotes.Fire("_process", "Stop")
                            end)
                            pcall(function()
                                local pGui = LocalPlayer:FindFirstChild("PlayerGui")
                                local grp = pGui and pGui:FindFirstChild("Process") and pGui.Process:FindFirstChild("Group")
                                if grp then grp.Visible = false end
                            end)
                            local exitChar = LocalPlayer.Character
                            local exitRoot = exitChar and exitChar:FindFirstChild("HumanoidRootPart")
                            if exitRoot then
                                exitRoot.Anchored = false
                            end
                            updateSafePlatform(nil, false)
                            StatusText.Text = "หลอมแร่เสร็จสิ้น! ตรวจสอบการฝากตู้เซฟ..."
                            depositOresToVault()
                            StatusText.Text = "บินกลับไปขุดหินต่อ..."
                            task.wait(1)
                        end
                    end
                end
            end
            task.wait(0.5)
        end
    end)

    -- Auto Mining & Processing Loop (Svibranium)
    task.spawn(function()
        while myToken.running do
            if isAtServerSelectionScreen() then
                task.wait(1.5)
            elseif state.svibFarm then
                if not ensurePickaxe() then
                    task.wait(2)
                else
                    local pData = LocalPlayer:FindFirstChild("PlayerData")
                    local sv = pData and pData:GetAttribute("Svibranium") or 0

                    if sv < 120 then
                        StatusText.Text = "กำลังเดินทางไป ไวเบรเนียม (Svibranium)"
                        flyUnderground(FARM_COORDS.Svibranium)
                        if state.svibFarm then
                            local svibFolder = workspace:FindFirstChild("Systems") and workspace.Systems.Farm:FindFirstChild("Svibranium")
                            if svibFolder then
                                StatusText.Text = "กำลังขุดไวเบรเนียม..."
                                farmItemsUntilTarget(svibFolder, "Svibranium", 120, 120, function() return state.svibFarm end)
                            end
                        end
                    else
                        cancelGameFarm()
                        StatusText.Text = "ไวเบรเนียมครบ 120 ก้อนแล้ว! กำลังบินไปเตาหลอม (Process)"
                        flyUnderground(FARM_COORDS.ProcessSvib)
                        if state.svibFarm then
                            local char = LocalPlayer.Character
                            local root = char and char:FindFirstChild("HumanoidRootPart")
                            local hum = char and char:FindFirstChild("Humanoid")
                            if root then
                                local standPos = FARM_COORDS.ProcessSvib
                                root.CFrame = CFrame.new(standPos)
                                root.AssemblyLinearVelocity = Vector3.zero
                                root.AssemblyAngularVelocity = Vector3.zero
                                root.Anchored = false
                                updateSafePlatform(standPos, true)
                                if hum then
                                    hum.PlatformStand = false
                                    pcall(function() hum:ChangeState(Enum.HumanoidStateType.Running) end)
                                end
                                updateSafePlatform(procSurface, true)
                                restoreCharacterVisibility()
                            end
                            task.wait(0.3)

                            -- Trigger ProximityPrompt at Process.Svibranium
                            StatusText.Text = "ถึงเตาหลอมแล้ว! กำลังกดเริ่มแปรรูปไวเบรเนียม (Interact Prompt)..."
                            local prompt = waitForPrompt(function()
                                local procFolder = workspace:FindFirstChild("Systems") and workspace.Systems:FindFirstChild("Process") and workspace.Systems.Process:FindFirstChild("Svibranium")
                                local pt = procFolder and procFolder:FindFirstChild("Prompt")
                                return (pt and pt:FindFirstChildWhichIsA("ProximityPrompt")) or (procFolder and procFolder:FindFirstChildWhichIsA("ProximityPrompt", true))
                            end, 4)

                            if prompt then
                                if fireproximityprompt then
                                    fireproximityprompt(prompt)
                                end
                                pcall(function()
                                    prompt:InputHoldBegin()
                                    task.wait(prompt.HoldDuration + 0.1)
                                    prompt:InputHoldEnd()
                                end)
                            end
                            task.wait(0.3)
                            pcall(function()
                                Remotes.Fire("_process", "Start", "Svibranium")
                            end)

                            StatusText.Text = "กำลังหลอมไวเบรเนียม (อัตราได้ 10%)..."
                            local pTimeout = 0
                            local lastSv = pData and (pData:GetAttribute("Svibranium") or 0) or 0
                            while state.svibFarm and pTimeout < 120 do
                                local curSv = pData and (pData:GetAttribute("Svibranium") or 0) or 0
                                local curVb = pData and (pData:GetAttribute("Vibranium") or 0) or 0
                                StatusText.Text = string.format("กำลังหลอมไวเบรเนียม... (เหลือดิบ %d | ได้หลอม %d)", curSv, curVb)

                                if curSv < 4 then
                                    break
                                end

                                if pTimeout % 5 == 0 and pTimeout > 0 and curSv >= lastSv then
                                    if prompt and fireproximityprompt then
                                        fireproximityprompt(prompt)
                                    end
                                    pcall(function()
                                        Remotes.Fire("_process", "Start", "Svibranium")
                                    end)
                                end
                                lastSv = curSv

                                task.wait(1)
                                pTimeout = pTimeout + 1
                            end

                            pcall(function()
                                Remotes.Fire("_process", "Stop")
                            end)
                            pcall(function()
                                local pGui = LocalPlayer:FindFirstChild("PlayerGui")
                                local grp = pGui and pGui:FindFirstChild("Process") and pGui.Process:FindFirstChild("Group")
                                if grp then grp.Visible = false end
                            end)
                            local exitChar = LocalPlayer.Character
                            local exitRoot = exitChar and exitChar:FindFirstChild("HumanoidRootPart")
                            if exitRoot then
                                exitRoot.Anchored = false
                            end
                            updateSafePlatform(nil, false)
                            StatusText.Text = "หลอมเสร็จสิ้น! ตรวจสอบการฝากตู้เซฟ..."
                            depositOresToVault()
                            StatusText.Text = "บินกลับไปขุดต่อ..."
                            task.wait(1)
                        end
                    end
                end
            end
            task.wait(0.5)
        end
    end)

    rockSection = createSectionCard(mineTab, "ขุดหิน & แปรรูปอัตโนมัติ (ขุด 120 ก้อน -> หลอมแร่)", "ขุดหินแล้วบินไปหลอมเป็น เหล็ก (40%) ทอง (40%) เพชร (8%)", function(val)
        state.rockFarm = val
        if val then
            state.sandwich = false
            state.mangoRice = false
            state.bananaFarm = false
            state.fishFarm = false
            state.svibFarm = false
            state.stopRequested = false
            if swSection then swSection.setVisualOnly(false) end
            if mrSection then mrSection.setVisualOnly(false) end
            if bananaSection then bananaSection.setVisualOnly(false) end
            if fishingSection then fishingSection.setVisualOnly(false) end
            if svibSection then svibSection.setVisualOnly(false) end
        else
            if not state.sandwich and not state.mangoRice and not state.bananaFarm and not state.fishFarm and not state.svibFarm then
                state.stopRequested = true
                StatusText.Text = "สถานะ: ปิดการทำงาน"
                cancelGameFarm()
            end
            pcall(function()
                Remotes.Fire("_process", "Stop")
            end)
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root then root.Anchored = false end
            updateSafePlatform(nil, false)
        end
    end, state.rockFarm, "rbxassetid://109015975005899", {"rbxassetid://94553259692482"})

    svibSection = createSectionCard(mineTab, "ขุดไวเบรเนียม & หลอมอัตโนมัติ (Svibranium)", "ขุดไวเบรเนียม 120 ก้อน แล้วบินไปหลอมเป็น Vibranium (10%)", function(val)
        state.svibFarm = val
        if val then
            state.sandwich = false
            state.mangoRice = false
            state.bananaFarm = false
            state.fishFarm = false
            state.rockFarm = false
            state.stopRequested = false
            if swSection then swSection.setVisualOnly(false) end
            if mrSection then mrSection.setVisualOnly(false) end
            if bananaSection then bananaSection.setVisualOnly(false) end
            if fishingSection then fishingSection.setVisualOnly(false) end
            if rockSection then rockSection.setVisualOnly(false) end
        else
            if not state.sandwich and not state.mangoRice and not state.bananaFarm and not state.fishFarm and not state.rockFarm then
                state.stopRequested = true
                StatusText.Text = "สถานะ: ปิดการทำงาน"
                cancelGameFarm()
            end
            pcall(function()
                Remotes.Fire("_process", "Stop")
            end)
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root then root.Anchored = false end
            updateSafePlatform(nil, false)
        end
    end, state.svibFarm, "rbxassetid://121285038473063", {"rbxassetid://94553259692482"})

    vaultSection = createSectionCard(mineTab, "ฝากแร่ในตู้เซฟอัตโนมัติ (Auto Vault)", "นำเฉพาะ Rock, Iron, Gold, Diamond, Svibranium, Vibranium ไปฝากในตู้เซฟใต้ดินเมื่อหลอมเสร็จ (ตรวจจับตู้เซฟและระดับอัตโนมัติ)", function(val)
        state.autoVaultOres = val
        -- manual save only (user must click Save Now)
    end, state.autoVaultOres, "rbxassetid://128795058778401", {})

    do
        local QuickVaultRow = Instance.new("Frame")
        QuickVaultRow.Size = UDim2.new(1, -10, 0, 42)
        QuickVaultRow.BackgroundColor3 = panel
        QuickVaultRow.BorderSizePixel = 0
        QuickVaultRow.Parent = mineTab
        local QVCorner = Instance.new("UICorner")
        QVCorner.CornerRadius = UDim.new(0, 4)
        QVCorner.Parent = QuickVaultRow

        local QVTitle = Instance.new("TextLabel")
        QVTitle.Text = "ฝากแร่ในตู้เซฟทันที (Deposit Ores to Vault)"
        QVTitle.Font = Enum.Font.GothamBold
        QVTitle.TextSize = 11
        QVTitle.TextColor3 = white
        QVTitle.Position = UDim2.new(0, 10, 0, 4)
        QVTitle.Size = UDim2.new(1, -110, 0, 16)
        QVTitle.TextXAlignment = Enum.TextXAlignment.Left
        QVTitle.BackgroundTransparency = 1
        QVTitle.Parent = QuickVaultRow

        local QVSub = Instance.new("TextLabel")
        QVSub.Text = "บินไปตู้เซฟใต้ดินและฝากแร่กับไวเบรเนียมทั้งหมดทันที (มีระบบตรวจระดับตู้)"
        QVSub.Font = Enum.Font.Gotham
        QVSub.TextSize = 9
        QVSub.TextColor3 = muted
        QVSub.Position = UDim2.new(0, 10, 0, 22)
        QVSub.Size = UDim2.new(1, -110, 0, 16)
        QVSub.TextXAlignment = Enum.TextXAlignment.Left
        QVSub.BackgroundTransparency = 1
        QVSub.Parent = QuickVaultRow

        local QVBtn = Instance.new("TextButton")
        QVBtn.Text = "ฝากแร่ทันที"
        QVBtn.Font = Enum.Font.GothamBold
        QVBtn.TextSize = 10
        QVBtn.TextColor3 = Color3.fromRGB(10, 20, 30)
        QVBtn.BackgroundColor3 = accent
        QVBtn.Size = UDim2.new(0, 80, 0, 26)
        QVBtn.Position = UDim2.new(1, -90, 0.5, -13)
        QVBtn.BorderSizePixel = 0
        QVBtn.Parent = QuickVaultRow
        local QVC = Instance.new("UICorner")
        QVC.CornerRadius = UDim.new(0, 4)
        QVC.Parent = QVBtn

        makeButtonSmooth(QVBtn)

        QVBtn.MouseButton1Click:Connect(function()
            task.spawn(function()
                local vStat = getVaultStatus()
                if not vStat.hasVault then
                    StatusText.Text = "ตรวจพบคุณยังไม่มีตู้เซฟ (ยังไม่มีกุญแจ VaultKey)! กรุณาคราฟต์ก่อน"
                    task.wait(2)
                    return
                end
                state.isManualAction = true
                depositOresToVault()
                state.isManualAction = false
            end)
        end)
    end

    do
        local QuickBuyPickRow = Instance.new("Frame")
        QuickBuyPickRow.Size = UDim2.new(1, -10, 0, 42)
        QuickBuyPickRow.BackgroundColor3 = panel
        QuickBuyPickRow.BorderSizePixel = 0
        QuickBuyPickRow.Parent = mineTab
        local QBPCorner = Instance.new("UICorner")
        QBPCorner.CornerRadius = UDim.new(0, 4)
        QBPCorner.Parent = QuickBuyPickRow

        local QBPTitle = Instance.new("TextLabel")
        QBPTitle.Text = "ซื้อพิกแอ็กซ์ที่ร้านค้าทันที (Shop)"
        QBPTitle.Font = Enum.Font.GothamBold
        QBPTitle.TextSize = 11
        QBPTitle.TextColor3 = white
        QBPTitle.Position = UDim2.new(0, 10, 0, 4)
        QBPTitle.Size = UDim2.new(1, -110, 0, 16)
        QBPTitle.TextXAlignment = Enum.TextXAlignment.Left
        QBPTitle.BackgroundTransparency = 1
        QBPTitle.Parent = QuickBuyPickRow

        local QBPSub = Instance.new("TextLabel")
        QBPSub.Text = "ราคา 1,500$ เดินทางไปร้านค้าและซื้อให้อัตโนมัติ"
        QBPSub.Font = Enum.Font.Gotham
        QBPSub.TextSize = 9
        QBPSub.TextColor3 = muted
        QBPSub.Position = UDim2.new(0, 10, 0, 22)
        QBPSub.Size = UDim2.new(1, -110, 0, 16)
        QBPSub.TextXAlignment = Enum.TextXAlignment.Left
        QBPSub.BackgroundTransparency = 1
        QBPSub.Parent = QuickBuyPickRow

        local QBPBtn = Instance.new("TextButton")
        QBPBtn.Text = "ซื้อพิกแอ็กซ์"
        QBPBtn.Font = Enum.Font.GothamBold
        QBPBtn.TextSize = 10
        QBPBtn.TextColor3 = Color3.fromRGB(10, 20, 30)
        QBPBtn.BackgroundColor3 = accent
        QBPBtn.Size = UDim2.new(0, 80, 0, 26)
        QBPBtn.Position = UDim2.new(1, -90, 0.5, -13)
        QBPBtn.BorderSizePixel = 0
        QBPBtn.Parent = QuickBuyPickRow
        local QBPC = Instance.new("UICorner")
        QBPC.CornerRadius = UDim.new(0, 4)
        QBPC.Parent = QBPBtn

        makeButtonSmooth(QBPBtn)

        QBPBtn.MouseButton1Click:Connect(function()
            task.spawn(function()
                state.isManualAction = true
                ensurePickaxe()
                state.isManualAction = false
            end)
        end)
    end

    -- Quick Craft Actions
    local function createCraftActionBtn(parent, itemName, recipeDesc, stationId, recipeKey, craftDur)
        local Row = Instance.new("Frame")
        Row.Size = UDim2.new(1, -10, 0, 42)
        Row.BackgroundColor3 = panel
        Row.BorderSizePixel = 0
        Row.Parent = parent
        local RCorner = Instance.new("UICorner")
        RCorner.CornerRadius = UDim.new(0, 4)
        RCorner.Parent = Row

        local TitleLbl = Instance.new("TextLabel")
        TitleLbl.Text = itemName
        TitleLbl.Font = Enum.Font.GothamBold
        TitleLbl.TextSize = 11
        TitleLbl.TextColor3 = white
        TitleLbl.Position = UDim2.new(0, 10, 0, 4)
        TitleLbl.Size = UDim2.new(1, -100, 0, 16)
        TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
        TitleLbl.BackgroundTransparency = 1
        TitleLbl.Parent = Row

        local SubLbl = Instance.new("TextLabel")
        SubLbl.Text = recipeDesc
        SubLbl.Font = Enum.Font.Gotham
        SubLbl.TextSize = 9
        SubLbl.TextColor3 = muted
        SubLbl.Position = UDim2.new(0, 10, 0, 22)
        SubLbl.Size = UDim2.new(1, -100, 0, 16)
        SubLbl.TextXAlignment = Enum.TextXAlignment.Left
        SubLbl.BackgroundTransparency = 1
        SubLbl.Parent = Row

        local ActBtn = Instance.new("TextButton")
        ActBtn.Text = "คราฟต์ 1 ชิ้น"
        ActBtn.Font = Enum.Font.GothamBold
        ActBtn.TextSize = 10
        ActBtn.TextColor3 = Color3.fromRGB(10, 20, 30)
        ActBtn.BackgroundColor3 = accent
        ActBtn.Size = UDim2.new(0, 80, 0, 26)
        ActBtn.Position = UDim2.new(1, -90, 0.5, -13)
        ActBtn.BorderSizePixel = 0
        ActBtn.Parent = Row
        local ACorner = Instance.new("UICorner")
        ACorner.CornerRadius = UDim.new(0, 4)
        ACorner.Parent = ActBtn

        makeButtonSmooth(ActBtn)

        ActBtn.MouseButton1Click:Connect(function()
            task.spawn(function()
                local targetCoord = stationId == "Craft_1" and FARM_COORDS.CraftWeapon or FARM_COORDS.CraftEquip
                StatusText.Text = "กำลังเดินทางไปโต๊ะคราฟต์ " .. itemName
                flyUnderground(targetCoord)

                local char = LocalPlayer.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if root then
                    local craftUnder = Vector3.new(targetCoord.X, targetCoord.Y - state.undergroundDepth, targetCoord.Z)
                    root.CFrame = CFrame.new(craftUnder)
                    root.AssemblyLinearVelocity = Vector3.zero
                    root.Anchored = true
                    updateSafePlatform(craftUnder, true)
                end
                task.wait(0.3)

                local pData = LocalPlayer:FindFirstChild("PlayerData")
                local initialItemCount = pData and (pData:GetAttribute(recipeKey) or 0) or 0
                local itemReceived = false

                for attempt = 1, 3 do
                    StatusText.Text = string.format("ส่งคำสั่งคราฟต์ %s [รอบที่ %d]...", itemName, attempt)
                    pcall(function()
                        Remotes.Fire("_crafting", "Request", stationId, recipeKey, 1, false)
                    end)

                    for s = craftDur, 1, -1 do
                        StatusText.Text = string.format("กำลังคราฟต์ %s [รอบที่ %d] (เหลือ %d วินาที)...", itemName, attempt, s)
                        task.wait(1)
                    end

                    pcall(function()
                        Remotes.Fire("_crafting", "Complete", stationId, recipeKey, 1, false)
                    end)
                    task.wait(0.8)

                    -- ตรวจสอบของในตัว (Verification)
                    local curItemCount = pData and (pData:GetAttribute(recipeKey) or 0) or 0
                    if curItemCount > initialItemCount or curItemCount > 0 then
                        itemReceived = true
                        StatusText.Text = string.format("คราฟต์ %s สำเร็จ! ของเข้าตัวแล้ว (มีในตัว %d ชิ้น)", itemName, curItemCount)
                        break
                    else
                        StatusText.Text = string.format("ของ %s ยังไม่เข้าตัว! กำลังกดคราฟต์ใหม่...", itemName)
                        task.wait(1.0)
                    end
                end

                if not itemReceived then
                    StatusText.Text = "คราฟต์ " .. itemName .. " เสร็จสิ้น!"
                end
                if root then root.Anchored = false end
                updateSafePlatform(nil, false)
                task.wait(1)
            end)
        end)
    end

    do
        local CraftHeader = Instance.new("Frame")
        CraftHeader.Size = UDim2.new(1, -10, 0, 28)
        CraftHeader.BackgroundColor3 = Color3.fromRGB(30, 60, 80)
        CraftHeader.BorderSizePixel = 0
        CraftHeader.Parent = mineTab
        local CHCorner = Instance.new("UICorner")
        CHCorner.CornerRadius = UDim.new(0, 4)
        CHCorner.Parent = CraftHeader
        local CHText = Instance.new("TextLabel")
        CHText.Text = "คราฟต์เกราะ & ยา & อุปกรณ์ (โต๊ะ Craft_2 ที่ Rebel)"
        CHText.Font = Enum.Font.GothamBold
        CHText.TextSize = 11
        CHText.TextColor3 = white
        CHText.Position = UDim2.new(0, 10, 0, 0)
        CHText.Size = UDim2.new(1, -20, 1, 0)
        CHText.TextXAlignment = Enum.TextXAlignment.Left
        CHText.BackgroundTransparency = 1
        CHText.Parent = CraftHeader
    end

    createCraftActionBtn(mineTab, "เกราะ (Armor)", "สูตร: เหล็ก 45 + ทอง 23 (ใช้เวลา 5 วิ)", "Craft_2", "Armor", 5)
    createCraftActionBtn(mineTab, "ยาชุบชีวิต (Aed)", "สูตร: เหล็ก 90 + ทอง 55 (ใช้เวลา 5 วิ)", "Craft_2", "Aed", 5)
    createCraftActionBtn(mineTab, "ยาแก้ปวด (Painkiller)", "สูตร: เหล็ก 34 + ทอง 23 (ใช้เวลา 5 วิ)", "Craft_2", "Painkiller", 5)
    createCraftActionBtn(mineTab, "สลิง (Wire)", "สูตร: เหล็ก 55 + ทอง 55 (ใช้เวลา 10 วิ)", "Craft_2", "Wire", 10)
    createCraftActionBtn(mineTab, "ปูน (Cement)", "สูตร: เหล็ก 55 + ทอง 55 (ใช้เวลา 10 วิ)", "Craft_2", "Cement", 10)

    do
        local WeaponHeader = Instance.new("Frame")
        WeaponHeader.Size = UDim2.new(1, -10, 0, 28)
        WeaponHeader.BackgroundColor3 = Color3.fromRGB(30, 60, 80)
        WeaponHeader.BorderSizePixel = 0
        WeaponHeader.Parent = mineTab
        local WHCorner = Instance.new("UICorner")
        WHCorner.CornerRadius = UDim.new(0, 4)
        WHCorner.Parent = WeaponHeader
        local WHText = Instance.new("TextLabel")
        WHText.Text = "คราฟต์อาวุธ & กุญแจ (โต๊ะ Craft_1 ที่ Rebel)"
        WHText.Font = Enum.Font.GothamBold
        WHText.TextSize = 11
        WHText.TextColor3 = white
        WHText.Position = UDim2.new(0, 10, 0, 0)
        WHText.Size = UDim2.new(1, -20, 1, 0)
        WHText.TextXAlignment = Enum.TextXAlignment.Left
        WHText.BackgroundTransparency = 1
        WHText.Parent = WeaponHeader
    end

    createCraftActionBtn(mineTab, "ไม้เบสบอล+0 (BatPlus0)", "ไวเบรเนียม 2 + เพชร 12 + กล่องอาวุธ 1 + ทอง 23 + เหล็ก 55", "Craft_1", "BatPlus0", 10)
    createCraftActionBtn(mineTab, "ประแจ (Wrench)", "เพชร 6 + ทอง 2 + เหล็ก 2 + เงิน 22,000", "Craft_1", "Wrench", 10)
    createCraftActionBtn(mineTab, "กุญแจเซฟ (VaultKey)", "เพชร 12 + ทอง 23 + เหล็ก 23 + สลิง 2 + ปูน 2", "Craft_1", "VaultKey", 10)

    -- =========================================================================
    -- [ ANTI-LAG & FPS OPTIMIZER SYSTEM ]
    -- =========================================================================
    local antiLagConnection = nil

    local function applyAntiLag(enable)
        local Lighting = game:GetService("Lighting")
        local Terrain = workspace.Terrain
        if enable then
            pcall(function() Lighting.GlobalShadows = false end)
            pcall(function() Lighting.FogEnd = 9e9 end)
            pcall(function() Terrain.Decoration = false end)
            pcall(function() Terrain.WaterWaveSize = 0 end)
            pcall(function() Terrain.WaterWaveSpeed = 0 end)
            pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)

            for _, d in ipairs(Lighting:GetChildren()) do
                if d:IsA("PostEffect") then
                    pcall(function() d.Enabled = false end)
                end
            end

            for _, d in ipairs(workspace:GetDescendants()) do
                if d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Beam") or d:IsA("Smoke") or d:IsA("Fire") or d:IsA("Sparkles") then
                    pcall(function() d.Enabled = false end)
                elseif d:IsA("Decal") or d:IsA("Texture") then
                    pcall(function() d.Transparency = 1 end)
                elseif d:IsA("BasePart") and not d:IsDescendantOf(LocalPlayer.Character) then
                    pcall(function()
                        d.Material = Enum.Material.SmoothPlastic
                        d.CastShadow = false
                    end)
                end
            end

            if not antiLagConnection then
                antiLagConnection = workspace.DescendantAdded:Connect(function(d)
                    if not state.antiLag then return end
                    task.wait(0.1)
                    if d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Beam") or d:IsA("Smoke") or d:IsA("Fire") or d:IsA("Sparkles") then
                        pcall(function() d.Enabled = false end)
                    elseif d:IsA("Decal") or d:IsA("Texture") then
                        pcall(function() d.Transparency = 1 end)
                    elseif d:IsA("BasePart") and not d:IsDescendantOf(LocalPlayer.Character) then
                        pcall(function()
                            d.Material = Enum.Material.SmoothPlastic
                            d.CastShadow = false
                        end)
                    end
                end)
            end
        else
            if antiLagConnection then
                pcall(function() antiLagConnection:Disconnect() end)
                antiLagConnection = nil
            end
            pcall(function() Lighting.GlobalShadows = true end)
            pcall(function() Lighting.FogEnd = 1000 end)
            for _, d in ipairs(Lighting:GetChildren()) do
                if d:IsA("PostEffect") then
                    pcall(function() d.Enabled = true end)
                end
            end
        end
    end

    local function applyFpsCap(fps)
        pcall(function()
            if setfpscap then
                setfpscap(fps)
            end
        end)
    end

    local function applyGpuSaver(enable)
        pcall(function()
            RunService:Set3dRenderingEnabled(not enable)
        end)
    end

    -- =========================================================================
    -- [ AUTO-REJOIN & LOWEST-PLAYER SERVER SELECTOR ]
    -- =========================================================================
    local TeleportService = game:GetService("TeleportService")

    local isRejoining = false

    local function setupQueueOnTeleport()
        pcall(function()
            local queueFunc = queue_on_teleport or (syn and syn.queue_on_teleport)
            if queueFunc then
                queueFunc([[
                    task.spawn(function()
                        task.wait(2.5)
                        local rfile = readfile or (syn and syn.readfile)
                        if rfile then
                            if isfile and isfile("NexusHub.lua") then
                                loadstring(readfile("NexusHub.lua"))()
                            elseif isfile and isfile("nexus_hub.lua") then
                                loadstring(readfile("nexus_hub.lua"))()
                            end
                        end
                        end
                    end)
                ]])
            end
        end)
    end

    local function triggerAutoRejoin(reason)
        if isRejoining then return end
        isRejoining = true
        warn("[Nexus Hub] Auto-Rejoining due to:", tostring(reason))

        setupQueueOnTeleport()

        -- หน่วงเวลา 6 วินาทีเพื่อเคลียร์ Session ให้ปลอดภัยก่อนเข้าเซิร์ฟเวอร์ใหม่
        for remaining = 6, 1, -1 do
            StatusText.Text = string.format("ตรวจพบเซิร์ฟเวอร์รีเซ็ต/หลุด... กำลังรีจอยใน %d วินาที", remaining)
            task.wait(1)
        end

        StatusText.Text = "กำลังเดินทางไปหน้าเลือกเซิร์ฟเวอร์..."
        task.wait(0.5)

        local teleported = false
        pcall(function()
            teleported = true
            TeleportService:Teleport(LOBBY_PLACE_ID, LocalPlayer)
        end)

        task.wait(6)
        if not teleported then
            pcall(function()
                TeleportService:Teleport(game.PlaceId, LocalPlayer)
            end)
        end
    end

    -- 1. Scan and join lowest player server from in-game UI or Roblox API
    local isSelectingServer = false
    local function findAndJoinLowestServer()
        if isSelectingServer then return false end
        isSelectingServer = true

        local lowestEntry = nil
        local lowestPlayerCount = math.huge
        local joinButtonToClick = nil

        -- Scan PlayerGui for Server Selection UI
        pcall(function()
            for _, gui in ipairs(LocalPlayer.PlayerGui:GetChildren()) do
                if gui:IsA("ScreenGui") and gui.Enabled then
                    for _, desc in ipairs(gui:GetDescendants()) do
                        if desc:IsA("TextLabel") or desc:IsA("TextButton") then
                            local text = desc.Text or ""
                            local current, max = text:match("(%d+)%s*/%s*(%d+)")
                            if not current then
                                current = text:match("(%d+)%s*คน") or text:match("(%d+)%s*[Pp]layers?") or text:match("[Pp]layers?:%s*(%d+)")
                            end
                            if current then
                                local count = tonumber(current)
                                local maxCount = max and tonumber(max) or 60
                                if count and count >= 0 and count < maxCount then
                                    local parent = desc.Parent
                                    local btn = nil
                                    for _ = 1, 4 do
                                        if not parent or parent == gui then break end
                                        for _, b in ipairs(parent:GetChildren()) do
                                            if b:IsA("GuiButton") and (b.Text:lower():find("join") or b.Text:find("เข้า") or b.Text:find("เลือก") or b.Name:lower():find("join") or b.Name:lower():find("btn") or b.Name:lower():find("play")) then
                                                btn = b
                                                break
                                            end
                                        end
                                        if not btn and parent:IsA("GuiButton") then
                                            btn = parent
                                        end
                                        if btn then break end
                                        parent = parent.Parent
                                    end

                                    -- กรองเฉพาะเซิร์ฟเวอร์ที่มีผู้เล่น 0 ถึง 3 คนเท่านั้นตามที่ผู้ใช้กำหนด
                                    if btn and count >= 0 and count <= 3 and count < lowestPlayerCount then
                                        lowestPlayerCount = count
                                        lowestEntry = desc
                                        joinButtonToClick = btn
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end)

        if joinButtonToClick and lowestPlayerCount <= 3 then
            StatusText.Text = string.format("พบเซิร์ฟเวอร์คนน้อย (%d คน)! กำลังเข้าร่วมเซิร์ฟเวอร์ทันที...", lowestPlayerCount)
            setupQueueOnTeleport()
            task.wait(1.2)
            if firesignal then
                firesignal(joinButtonToClick.MouseButton1Click)
            elseif joinButtonToClick:IsA("GuiButton") then
                pcall(function() joinButtonToClick.MouseButton1Click:Fire() end)
            end
            task.wait(2)
            isSelectingServer = false
            return true
        else
            StatusText.Text = "กำลังรอ/ค้นหาเซิร์ฟเวอร์ที่มีคน 0-3 คน..."
        end

        isSelectingServer = false
        return false
    end

    -- 2. Watchdog for Disconnect / Kick / Server Reset
    task.spawn(function()
        pcall(function()
            game:GetService("GuiService").ErrorMessageChanged:Connect(function(msg)
                if state.autoRejoin and msg and msg ~= "" then
                    local lower = tostring(msg):lower()
                    if lower:find("disconnect") or lower:find("kick") or lower:find("lost connection") or lower:find("reconnect") then
                        warn("[Nexus Hub] Genuine Disconnect Detected:", msg)
                        triggerAutoRejoin("GuiService Error: " .. tostring(msg))
                    end
                end
            end)
        end)

        pcall(function()
            local coreGui = game:GetService("CoreGui")
            local promptGui = coreGui:WaitForChild("RobloxPromptGui", 5)
            local overlay = promptGui and promptGui:WaitForChild("promptOverlay", 5)
            if overlay then
                overlay.ChildAdded:Connect(function(child)
                    if state.autoRejoin and child.Name == "ErrorPrompt" then
                        warn("[Nexus Hub] ErrorPrompt Detected in promptOverlay!")
                        task.wait(0.5)
                        local btn = child:FindFirstChildWhichIsA("GuiButton", true)
                        if btn and firesignal then
                            firesignal(btn.MouseButton1Click)
                        end
                        triggerAutoRejoin("ErrorPrompt ChildAdded")
                    end
                end)
            end
        end)
    end)

    -- [ SERVER SELECTION & AUTO-RESUME WATCHDOG ]
    -- เมื่ออยู่หน้าเลือกเซิร์ฟเวอร์ จะปิดทุกฟังก์ชันฟาร์ม และถ้าเข้าเซิร์ฟเวอร์หลักเสร็จสมบูรณ์ จะเปิดฟาร์มปกติตามการตั้งค่า
    task.spawn(function()
        local wasAtSelection = isAtServerSelectionScreen()
        if wasAtSelection then
            StatusText.Text = "สถานะ: อยู่หน้าเลือกเซิร์ฟเวอร์ (Lobby) — ปิดระบบฟาร์มชั่วคราว (จะเปิดอัตโนมัติเมื่อเข้าเซิร์ฟ)"
        end

        while myToken.running do
            local isCurrentlyAtSelection = isAtServerSelectionScreen()

            if wasAtSelection and not isCurrentlyAtSelection then
                -- เพิ่งเข้าเซิร์ฟเวอร์หลักและโหลดเสร็จสมบูรณ์ 100%!
                wasAtSelection = false
                cancelGameFarm()
                updateSafePlatform(nil, false)
                StatusText.Text = "เข้าเซิร์ฟเวอร์หลักเสร็จสมบูรณ์แล้ว! กำลังเริ่มระบบฟาร์มอัตโนมัติตามปกติ..."
                task.wait(2.0)

                -- ซิงก์ค่าการฟาร์มตามคอนฟิกที่ผู้ใช้ตั้งไว้ และเริ่มระบบฟาร์ม
                pcall(function()
                    loadConfig()
                    if syncUIFromState then syncUIFromState() end
                end)

            elseif not wasAtSelection and isCurrentlyAtSelection then
                -- กำลังหลุดไปหน้าเลือกเซิร์ฟเวอร์ หรือกำลังวาร์ปย้ายเซิร์ฟเวอร์
                wasAtSelection = true
                cancelGameFarm()
                updateSafePlatform(nil, false)
                StatusText.Text = "ตรวจพบอยู่หน้าเลือกเซิร์ฟเวอร์ — ปิดระบบฟาร์มทั้งหมดอัตโนมัติ"
            end

            task.wait(1.0)
        end
    end)

    -- 3. Auto-server selector loop (Runs automatically in Lobby place 73746968849439 or when server list is shown)
    task.spawn(function()
        while myToken.running do
            pcall(function()
                if state.autoLowestServer then
                    if game.PlaceId == LOBBY_PLACE_ID then
                        findAndJoinLowestServer()
                    end
                end
            end)
            task.wait(2)
        end
    end)

    -- [ PLAYER LIMIT AUTO-HOP WATCHDOG ]
    task.spawn(function()
        while myToken.running do
            pcall(function()
                local curCount = #Players:GetPlayers()
                if uiRefs.CurrentPlayersLabel and uiRefs.CurrentPlayersLabel.Parent then
                    uiRefs.CurrentPlayersLabel.Text = string.format("ผู้เล่นในเซิร์ฟเวอร์ปัจจุบัน: %d คน (ขีดจำกัด: %d คน)", curCount, state.maxPlayersLimit or 25)
                end

                if state.serverHopPlayerLimitEnabled and not isRejoining then
                    local limit = state.maxPlayersLimit or 25
                    if curCount > limit then
                        warn(string.format("[Nexus Hub] Server player count (%d) exceeded limit (%d)! Auto-hopping...", curCount, limit))
                        StatusText.Text = string.format("คนในเซิร์ฟเวอร์เกินกำหนด (%d/%d คน)! กำลังรีจอยหาเซิร์ฟใหม่...", curCount, limit)
                        state.autoLowestServer = true
                        pcall(saveConfig)
                        triggerAutoRejoin(string.format("Player count (%d) exceeded limit (%d)", curCount, limit))
                    end
                end
            end)
            task.wait(3)
        end
    end)

    pcall(function()
        Players.PlayerAdded:Connect(function()
            if state.serverHopPlayerLimitEnabled and not isRejoining then
                local curCount = #Players:GetPlayers()
                local limit = state.maxPlayersLimit or 25
                if curCount > limit then
                    StatusText.Text = string.format("มีคนเข้าใหม่จนเกินกำหนด (%d/%d คน)! กำลังรีจอยหาเซิร์ฟใหม่...", curCount, limit)
                    state.autoLowestServer = true
                    pcall(saveConfig)
                    triggerAutoRejoin(string.format("PlayerAdded (%d) exceeded limit (%d)", curCount, limit))
                end
            end
        end)
    end)

    -- Setting Tab Cards
    -- [ ANTI-AFK SYSTEM WATCHDOG ]
    task.spawn(function()
        local VirtualUser = game:GetService("VirtualUser")
        local VirtualInputManager = game:GetService("VirtualInputManager")

        local function keepAlive()
            pcall(function()
                if VirtualUser then
                    VirtualUser:CaptureController()
                    VirtualUser:ClickButton2(Vector2.new(0, 0))
                end
            end)
            pcall(function()
                if VirtualInputManager then
                    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                    task.wait(0.05)
                    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
                end
            end)
        end

        local idledConn = LocalPlayer.Idled:Connect(function()
            if state.antiAfk and myToken.running then
                keepAlive()
                warn("[Nexus Hub] Anti-AFK: Kept connection alive via Virtual Input!")
            end
        end)
        table.insert(_G.NexusConnections, idledConn)

        while myToken.running do
            task.wait(420)
            if state.antiAfk and myToken.running then
                keepAlive()
            end
        end
    end)

    local uiRefs = {}
    local AAToggle = nil
    local RJToggle = nil
    local SCToggle = nil
    local AutoSaveToggle = nil
    local CFGStatus = nil

    -- 1. Anti-AFK Card
    do
        local AntiAfkCard = Instance.new("Frame")
        AntiAfkCard.Size = UDim2.new(1, -10, 0, 72)
        AntiAfkCard.BackgroundColor3 = panel
        AntiAfkCard.BorderSizePixel = 0
        AntiAfkCard.Parent = setTab
        local AACorner = Instance.new("UICorner")
        AACorner.CornerRadius = UDim.new(0, 6)
        AACorner.Parent = AntiAfkCard
        local AAStroke = Instance.new("UIStroke")
        AAStroke.Color = borderColor
        AAStroke.Parent = AntiAfkCard

        local AATitle = Instance.new("TextLabel")
        AATitle.Text = "ระบบกันหลุด 24 ชม. (Anti-AFK Inactivity Bypass)"
        AATitle.Font = Enum.Font.GothamBold
        AATitle.TextSize = 11
        AATitle.TextColor3 = accent
        AATitle.Position = UDim2.new(0, 12, 0, 8)
        AATitle.Size = UDim2.new(1, -90, 0, 16)
        AATitle.TextXAlignment = Enum.TextXAlignment.Left
        AATitle.BackgroundTransparency = 1
        AATitle.Parent = AntiAfkCard

        local AADesc = Instance.new("TextLabel")
        AADesc.Text = "ป้องกันระบบ Roblox ตัดการเชื่อมต่อเมื่ออยู่เฉยๆ เกิน 20 นาที (Auto Virtual Input)"
        AADesc.Font = Enum.Font.Gotham
        AADesc.TextSize = 9
        AADesc.TextColor3 = muted
        AADesc.Position = UDim2.new(0, 12, 0, 26)
        AADesc.Size = UDim2.new(1, -90, 0, 16)
        AADesc.TextXAlignment = Enum.TextXAlignment.Left
        AADesc.BackgroundTransparency = 1
        AADesc.Parent = AntiAfkCard

        local AAStatus = Instance.new("TextLabel")
        AAStatus.Text = "สถานะ: ทำงานอัตโนมัติ (รีเซ็ตเวลา Idle ทุก 7 นาที)"
        AAStatus.Font = Enum.Font.GothamMedium
        AAStatus.TextSize = 9
        AAStatus.TextColor3 = white
        AAStatus.Position = UDim2.new(0, 12, 0, 46)
        AAStatus.Size = UDim2.new(1, -90, 0, 16)
        AAStatus.TextXAlignment = Enum.TextXAlignment.Left
        AAStatus.BackgroundTransparency = 1
        AAStatus.Parent = AntiAfkCard

        AAToggle = Instance.new("TextButton")
        AAToggle.Text = state.antiAfk and "เปิด" or "ปิด"
        AAToggle.Font = Enum.Font.GothamBold
        AAToggle.TextSize = 10
        AAToggle.TextColor3 = state.antiAfk and Color3.fromRGB(10, 20, 30) or white
        AAToggle.BackgroundColor3 = state.antiAfk and accent or Color3.fromRGB(45, 60, 75)
        AAToggle.Size = UDim2.new(0, 60, 0, 28)
        AAToggle.Position = UDim2.new(1, -72, 0.5, -14)
        AAToggle.BorderSizePixel = 0
        AAToggle.Parent = AntiAfkCard
        local AATCorner = Instance.new("UICorner")
        AATCorner.CornerRadius = UDim.new(0, 4)
        AATCorner.Parent = AAToggle

        makeButtonSmooth(AAToggle)
        AAToggle.MouseButton1Click:Connect(function()
            state.antiAfk = not state.antiAfk
            animateButtonToggle(AAToggle, state.antiAfk, "เปิด", "ปิด")
            -- manual save only (user must click Save Now)
        end)
    end

    -- 2. Rejoin Card
    do
        local RejoinCard = Instance.new("Frame")
        RejoinCard.Size = UDim2.new(1, -10, 0, 72)
        RejoinCard.BackgroundColor3 = panel
        RejoinCard.BorderSizePixel = 0
        RejoinCard.Parent = setTab
        local RJCorner = Instance.new("UICorner")
        RJCorner.CornerRadius = UDim.new(0, 6)
        RJCorner.Parent = RejoinCard
        local RJStroke = Instance.new("UIStroke")
        RJStroke.Color = borderColor
        RJStroke.Parent = RejoinCard

        local RJTitle = Instance.new("TextLabel")
        RJTitle.Text = "ระบบออโต้รีจอยอัตโนมัติ (Auto-Rejoin Watchdog)"
        RJTitle.Font = Enum.Font.GothamBold
        RJTitle.TextSize = 11
        RJTitle.TextColor3 = accent
        RJTitle.Position = UDim2.new(0, 12, 0, 8)
        RJTitle.Size = UDim2.new(1, -90, 0, 16)
        RJTitle.TextXAlignment = Enum.TextXAlignment.Left
        RJTitle.BackgroundTransparency = 1
        RJTitle.Parent = RejoinCard

        local RJDesc = Instance.new("TextLabel")
        RJDesc.Text = "เมื่อเซิร์ฟเวอร์รีเซ็ต, หลุด, หรือเกิด Error จะรอ 60 วินาทีก่อนเข้าเซิร์ฟ ป้องกันเกมเด้ง"
        RJDesc.Font = Enum.Font.Gotham
        RJDesc.TextSize = 9
        RJDesc.TextColor3 = muted
        RJDesc.Position = UDim2.new(0, 12, 0, 26)
        RJDesc.Size = UDim2.new(1, -90, 0, 16)
        RJDesc.TextXAlignment = Enum.TextXAlignment.Left
        RJDesc.BackgroundTransparency = 1
        RJDesc.Parent = RejoinCard

        local RJStatus = Instance.new("TextLabel")
        RJStatus.Text = "สถานะ: ทำงานตลอด 24 ชม. (ระบบหน่วงเวลาปลอดภัย 60 วิ ก่อนเข้าเซิร์ฟ)"
        RJStatus.Font = Enum.Font.GothamMedium
        RJStatus.TextSize = 9
        RJStatus.TextColor3 = white
        RJStatus.Position = UDim2.new(0, 12, 0, 46)
        RJStatus.Size = UDim2.new(1, -90, 0, 16)
        RJStatus.TextXAlignment = Enum.TextXAlignment.Left
        RJStatus.BackgroundTransparency = 1
        RJStatus.Parent = RejoinCard

        RJToggle = Instance.new("TextButton")
        RJToggle.Text = state.autoRejoin and "เปิด" or "ปิด"
        RJToggle.Font = Enum.Font.GothamBold
        RJToggle.TextSize = 10
        RJToggle.TextColor3 = state.autoRejoin and Color3.fromRGB(10, 20, 30) or white
        RJToggle.BackgroundColor3 = state.autoRejoin and accent or Color3.fromRGB(45, 60, 75)
        RJToggle.Size = UDim2.new(0, 60, 0, 28)
        RJToggle.Position = UDim2.new(1, -72, 0.5, -14)
        RJToggle.BorderSizePixel = 0
        RJToggle.Parent = RejoinCard
        local RJTCorner = Instance.new("UICorner")
        RJTCorner.CornerRadius = UDim.new(0, 4)
        RJTCorner.Parent = RJToggle

        makeButtonSmooth(RJToggle)
        RJToggle.MouseButton1Click:Connect(function()
            state.autoRejoin = not state.autoRejoin
            animateButtonToggle(RJToggle, state.autoRejoin, "เปิด", "ปิด")
            -- manual save only (user must click Save Now)
        end)
    end

    -- 3. Server Selector Card
    do
        local ServerCard = Instance.new("Frame")
        ServerCard.Size = UDim2.new(1, -10, 0, 105)
        ServerCard.BackgroundColor3 = panel
        ServerCard.BorderSizePixel = 0
        ServerCard.Parent = setTab
        local SCCorner = Instance.new("UICorner")
        SCCorner.CornerRadius = UDim.new(0, 6)
        SCCorner.Parent = ServerCard
        local SCStroke = Instance.new("UIStroke")
        SCStroke.Color = borderColor
        SCStroke.Parent = ServerCard

        local SCTitle = Instance.new("TextLabel")
        SCTitle.Text = "ระบบเลือกเซิร์ฟเวอร์คนน้อยที่สุด (Auto Lowest Server)"
        SCTitle.Font = Enum.Font.GothamBold
        SCTitle.TextSize = 11
        SCTitle.TextColor3 = accent
        SCTitle.Position = UDim2.new(0, 12, 0, 8)
        SCTitle.Size = UDim2.new(1, -90, 0, 16)
        SCTitle.TextXAlignment = Enum.TextXAlignment.Left
        SCTitle.BackgroundTransparency = 1
        SCTitle.Parent = ServerCard

        local SCDesc = Instance.new("TextLabel")
        SCDesc.Text = "เมื่อถึงหน้าเลือกเซิร์ฟเวอร์ จะสแกนหาห้องที่มีจำนวนผู้เล่นน้อยที่สุดและกดเข้าทันที"
        SCDesc.Font = Enum.Font.Gotham
        SCDesc.TextSize = 9
        SCDesc.TextColor3 = muted
        SCDesc.Position = UDim2.new(0, 12, 0, 26)
        SCDesc.Size = UDim2.new(1, -90, 0, 16)
        SCDesc.TextXAlignment = Enum.TextXAlignment.Left
        SCDesc.BackgroundTransparency = 1
        SCDesc.Parent = ServerCard

        SCToggle = Instance.new("TextButton")
        SCToggle.Text = state.autoLowestServer and "เปิด" or "ปิด"
        SCToggle.Font = Enum.Font.GothamBold
        SCToggle.TextSize = 10
        SCToggle.TextColor3 = state.autoLowestServer and Color3.fromRGB(10, 20, 30) or white
        SCToggle.BackgroundColor3 = state.autoLowestServer and accent or Color3.fromRGB(45, 60, 75)
        SCToggle.Size = UDim2.new(0, 60, 0, 28)
        SCToggle.Position = UDim2.new(1, -72, 0, 10)
        SCToggle.BorderSizePixel = 0
        SCToggle.Parent = ServerCard
        local SCTCorner = Instance.new("UICorner")
        SCTCorner.CornerRadius = UDim.new(0, 4)
        SCTCorner.Parent = SCToggle

        makeButtonSmooth(SCToggle)
        SCToggle.MouseButton1Click:Connect(function()
            state.autoLowestServer = not state.autoLowestServer
            animateButtonToggle(SCToggle, state.autoLowestServer, "เปิด", "ปิด")
            -- manual save only (user must click Save Now)
        end)

        local JoinLowestNowBtn = Instance.new("TextButton")
        JoinLowestNowBtn.Text = "สแกนหาและเข้าห้องคนน้อยที่สุดตอนนี้ (Scan & Join Lowest Now)"
        JoinLowestNowBtn.Font = Enum.Font.GothamBold
        JoinLowestNowBtn.TextSize = 10
        JoinLowestNowBtn.TextColor3 = Color3.fromRGB(10, 20, 30)
        JoinLowestNowBtn.BackgroundColor3 = accent
        JoinLowestNowBtn.Size = UDim2.new(1, -24, 0, 28)
        JoinLowestNowBtn.Position = UDim2.new(0, 12, 0, 65)
        JoinLowestNowBtn.BorderSizePixel = 0
        JoinLowestNowBtn.Parent = ServerCard
        local JLNCorner = Instance.new("UICorner")
        JLNCorner.CornerRadius = UDim.new(0, 4)
        JLNCorner.Parent = JoinLowestNowBtn

        makeButtonSmooth(JoinLowestNowBtn)

        JoinLowestNowBtn.MouseButton1Click:Connect(function()
            task.spawn(function()
                StatusText.Text = "กำลังสแกนหาห้องที่มีคนน้อยที่สุด..."
                local found = findAndJoinLowestServer()
                if not found then
                    StatusText.Text = "ยังไม่พบหน้าเลือกเซิร์ฟเวอร์ในหน้านี้ (จะทำงานอัตโนมัติเมื่ออยู่หน้าเลือกเซิร์ฟ)"
                end
            end)
        end)
    end

    -- 3.5. Player Limit Auto-Hop Card
    do
        local PLCard = Instance.new("Frame")
        PLCard.Size = UDim2.new(1, -10, 0, 140)
        PLCard.BackgroundColor3 = panel
        PLCard.BorderSizePixel = 0
        PLCard.Parent = setTab
        local PLCorner = Instance.new("UICorner")
        PLCorner.CornerRadius = UDim.new(0, 6)
        PLCorner.Parent = PLCard
        local PLStroke = Instance.new("UIStroke")
        PLStroke.Color = borderColor
        PLStroke.Parent = PLCard

        local PLTitle = Instance.new("TextLabel")
        PLTitle.Text = "ระบบจำกัดจำนวนคนในเซิร์ฟเวอร์ (Player Limit Auto-Hop)"
        PLTitle.Font = Enum.Font.GothamBold
        PLTitle.TextSize = 11
        PLTitle.TextColor3 = accent
        PLTitle.Position = UDim2.new(0, 12, 0, 8)
        PLTitle.Size = UDim2.new(1, -90, 0, 16)
        PLTitle.TextXAlignment = Enum.TextXAlignment.Left
        PLTitle.BackgroundTransparency = 1
        PLTitle.Parent = PLCard

        local PLDesc = Instance.new("TextLabel")
        PLDesc.Text = "หากคนในเซิร์ฟเวอร์เกินจำนวนที่ตั้งไว้ จะรอ 60 วิก่อนรีจอยหาเซิร์ฟเวอร์ใหม่คนน้อยทันที"
        PLDesc.Font = Enum.Font.Gotham
        PLDesc.TextSize = 9
        PLDesc.TextColor3 = muted
        PLDesc.Position = UDim2.new(0, 12, 0, 26)
        PLDesc.Size = UDim2.new(1, -90, 0, 16)
        PLDesc.TextXAlignment = Enum.TextXAlignment.Left
        PLDesc.BackgroundTransparency = 1
        PLDesc.Parent = PLCard

        do
            local toggle = Instance.new("TextButton")
            toggle.Text = state.serverHopPlayerLimitEnabled and "เปิด" or "ปิด"
            toggle.Font = Enum.Font.GothamBold
            toggle.TextSize = 10
            toggle.TextColor3 = state.serverHopPlayerLimitEnabled and Color3.fromRGB(10, 20, 30) or white
            toggle.BackgroundColor3 = state.serverHopPlayerLimitEnabled and accent or Color3.fromRGB(45, 60, 75)
            toggle.Size = UDim2.new(0, 60, 0, 28)
            toggle.Position = UDim2.new(1, -72, 0, 10)
            toggle.BorderSizePixel = 0
            toggle.Parent = PLCard
            local tCorner = Instance.new("UICorner")
            tCorner.CornerRadius = UDim.new(0, 4)
            tCorner.Parent = toggle
            uiRefs.PlayerLimitToggle = toggle

            makeButtonSmooth(toggle)
            toggle.MouseButton1Click:Connect(function()
                state.serverHopPlayerLimitEnabled = not state.serverHopPlayerLimitEnabled
                animateButtonToggle(toggle, state.serverHopPlayerLimitEnabled, "เปิด", "ปิด")
                if state.serverHopPlayerLimitEnabled then
                    StatusText.Text = string.format("เปิดระบบตรวจจับคนเกิน: ขีดจำกัด %d คน (ปัจจุบันมี %d คน)", state.maxPlayersLimit, #Players:GetPlayers())
                else
                    StatusText.Text = "ปิดระบบตรวจจับคนเกินในเซิร์ฟเวอร์"
                end
                -- manual save only (user must click Save Now)
            end)
        end

        do
            local StepRow = Instance.new("Frame")
            StepRow.Size = UDim2.new(1, -24, 0, 30)
            StepRow.Position = UDim2.new(0, 12, 0, 46)
            StepRow.BackgroundTransparency = 1
            StepRow.Parent = PLCard

            local StepTitle = Instance.new("TextLabel")
            StepTitle.Text = "จำนวนคนสูงสุดที่ยอมรับได้:"
            StepTitle.Font = Enum.Font.GothamMedium
            StepTitle.TextSize = 10
            StepTitle.TextColor3 = white
            StepTitle.Size = UDim2.new(0, 150, 1, 0)
            StepTitle.TextXAlignment = Enum.TextXAlignment.Left
            StepTitle.BackgroundTransparency = 1
            StepTitle.Parent = StepRow

            local MinusBtn = Instance.new("TextButton")
            MinusBtn.Text = "-"
            MinusBtn.Font = Enum.Font.GothamBold
            MinusBtn.TextSize = 14
            MinusBtn.TextColor3 = white
            MinusBtn.BackgroundColor3 = Color3.fromRGB(45, 60, 75)
            MinusBtn.Size = UDim2.new(0, 30, 0, 26)
            MinusBtn.Position = UDim2.new(1, -145, 0.5, -13)
            MinusBtn.BorderSizePixel = 0
            MinusBtn.Parent = StepRow
            local MBCorner = Instance.new("UICorner")
            MBCorner.CornerRadius = UDim.new(0, 4)
            MBCorner.Parent = MinusBtn
            makeButtonSmooth(MinusBtn)

            local valLabel = Instance.new("TextLabel")
            valLabel.Text = (state.maxPlayersLimit or 25) .. " คน"
            valLabel.Font = Enum.Font.GothamBold
            valLabel.TextSize = 11
            valLabel.TextColor3 = accent
            valLabel.Size = UDim2.new(0, 70, 0, 26)
            valLabel.Position = UDim2.new(1, -110, 0.5, -13)
            valLabel.BackgroundTransparency = 1
            valLabel.Parent = StepRow
            uiRefs.PlayerLimitValLabel = valLabel

            local PlusBtn = Instance.new("TextButton")
            PlusBtn.Text = "+"
            PlusBtn.Font = Enum.Font.GothamBold
            PlusBtn.TextSize = 14
            PlusBtn.TextColor3 = white
            PlusBtn.BackgroundColor3 = Color3.fromRGB(45, 60, 75)
            PlusBtn.Size = UDim2.new(0, 30, 0, 26)
            PlusBtn.Position = UDim2.new(1, -35, 0.5, -13)
            PlusBtn.BorderSizePixel = 0
            PlusBtn.Parent = StepRow
            local PBCorner = Instance.new("UICorner")
            PBCorner.CornerRadius = UDim.new(0, 4)
            PBCorner.Parent = PlusBtn
            makeButtonSmooth(PlusBtn)

            MinusBtn.MouseButton1Click:Connect(function()
                if state.maxPlayersLimit > 2 then
                    state.maxPlayersLimit = math.max(2, state.maxPlayersLimit - 1)
                    valLabel.Text = state.maxPlayersLimit .. " คน"
                    -- manual save only (user must click Save Now)
                end
            end)

            PlusBtn.MouseButton1Click:Connect(function()
                if state.maxPlayersLimit < 60 then
                    state.maxPlayersLimit = math.min(60, state.maxPlayersLimit + 1)
                    valLabel.Text = state.maxPlayersLimit .. " คน"
                    -- manual save only (user must click Save Now)
                end
            end)
        end

        do
            local curLabel = Instance.new("TextLabel")
            curLabel.Text = string.format("ผู้เล่นในเซิร์ฟเวอร์ปัจจุบัน: %d คน (ขีดจำกัด: %d คน)", #Players:GetPlayers(), state.maxPlayersLimit or 25)
            curLabel.Font = Enum.Font.Gotham
            curLabel.TextSize = 9
            curLabel.TextColor3 = muted
            curLabel.Position = UDim2.new(0, 12, 0, 78)
            curLabel.Size = UDim2.new(1, -24, 0, 16)
            curLabel.TextXAlignment = Enum.TextXAlignment.Left
            curLabel.BackgroundTransparency = 1
            curLabel.Parent = PLCard
            uiRefs.CurrentPlayersLabel = curLabel
        end

        do
            local HopNowBtn = Instance.new("TextButton")
            HopNowBtn.Text = "ตรวจจำนวนคนและเปลี่ยนเซิร์ฟทันที (Hop Server Now)"
            HopNowBtn.Font = Enum.Font.GothamBold
            HopNowBtn.TextSize = 10
            HopNowBtn.TextColor3 = Color3.fromRGB(10, 20, 30)
            HopNowBtn.BackgroundColor3 = accent
            HopNowBtn.Size = UDim2.new(1, -24, 0, 28)
            HopNowBtn.Position = UDim2.new(0, 12, 0, 102)
            HopNowBtn.BorderSizePixel = 0
            HopNowBtn.Parent = PLCard
            local HNBCorner = Instance.new("UICorner")
            HNBCorner.CornerRadius = UDim.new(0, 4)
            HNBCorner.Parent = HopNowBtn
            makeButtonSmooth(HopNowBtn)

            HopNowBtn.MouseButton1Click:Connect(function()
                task.spawn(function()
                    local count = #Players:GetPlayers()
                    StatusText.Text = string.format("กำลังเริ่มย้ายเซิร์ฟเวอร์ (คนปัจจุบัน: %d คน)...", count)
                    state.autoLowestServer = true
                    pcall(saveConfig)
                    triggerAutoRejoin("Manual Hop Request")
                end)
            end)
        end
    end

    -- 3.8. Anti-Lag & FPS Optimizer Card
    do
        local ALCard = Instance.new("Frame")
        ALCard.Size = UDim2.new(1, -10, 0, 195)
        ALCard.BackgroundColor3 = panel
        ALCard.BorderSizePixel = 0
        ALCard.Parent = setTab
        local ALCorner = Instance.new("UICorner")
        ALCorner.CornerRadius = UDim.new(0, 6)
        ALCorner.Parent = ALCard
        local ALStroke = Instance.new("UIStroke")
        ALStroke.Color = borderColor
        ALStroke.Parent = ALCard

        local ALTitle = Instance.new("TextLabel")
        ALTitle.Text = "ระบบกันหน่วง & ลด FPS (Anti-Lag & FPS Optimizer)"
        ALTitle.Font = Enum.Font.GothamBold
        ALTitle.TextSize = 11
        ALTitle.TextColor3 = accent
        ALTitle.Position = UDim2.new(0, 12, 0, 8)
        ALTitle.Size = UDim2.new(1, -24, 0, 16)
        ALTitle.TextXAlignment = Enum.TextXAlignment.Left
        ALTitle.BackgroundTransparency = 1
        ALTitle.Parent = ALCard

        local ALDesc = Instance.new("TextLabel")
        ALDesc.Text = "ลดภาระการ์ดจอ/CPU ปิดเอฟเฟกต์ภาพที่ไม่จำเป็น ป้องกันเครื่องร้อน/ค้างเมื่อฟาร์ม 24 ชม."
        ALDesc.Font = Enum.Font.Gotham
        ALDesc.TextSize = 9
        ALDesc.TextColor3 = muted
        ALDesc.Position = UDim2.new(0, 12, 0, 26)
        ALDesc.Size = UDim2.new(1, -24, 0, 16)
        ALDesc.TextXAlignment = Enum.TextXAlignment.Left
        ALDesc.BackgroundTransparency = 1
        ALDesc.Parent = ALCard

        -- Row 1: Low Graphics Toggle
        do
            local Row1 = Instance.new("Frame")
            Row1.Size = UDim2.new(1, -24, 0, 28)
            Row1.Position = UDim2.new(0, 12, 0, 46)
            Row1.BackgroundTransparency = 1
            Row1.Parent = ALCard

            local R1Title = Instance.new("TextLabel")
            R1Title.Text = "โหมดกันหน่วง (ปิดเอฟเฟกต์/เงา/อนุภาค):"
            R1Title.Font = Enum.Font.GothamMedium
            R1Title.TextSize = 10
            R1Title.TextColor3 = white
            R1Title.Size = UDim2.new(1, -75, 1, 0)
            R1Title.TextXAlignment = Enum.TextXAlignment.Left
            R1Title.BackgroundTransparency = 1
            R1Title.Parent = Row1

            local btn = Instance.new("TextButton")
            btn.Text = state.antiLag and "เปิด" or "ปิด"
            btn.Font = Enum.Font.GothamBold
            btn.TextSize = 10
            btn.TextColor3 = state.antiLag and Color3.fromRGB(10, 20, 30) or white
            btn.BackgroundColor3 = state.antiLag and accent or Color3.fromRGB(45, 60, 75)
            btn.Size = UDim2.new(0, 60, 0, 26)
            btn.Position = UDim2.new(1, -60, 0.5, -13)
            btn.BorderSizePixel = 0
            btn.Parent = Row1
            local bCorner = Instance.new("UICorner")
            bCorner.CornerRadius = UDim.new(0, 4)
            bCorner.Parent = btn
            uiRefs.ALToggle = btn

            makeButtonSmooth(btn)
            btn.MouseButton1Click:Connect(function()
                state.antiLag = not state.antiLag
                animateButtonToggle(btn, state.antiLag, "เปิด", "ปิด")
                if state.antiLag then
                    applyAntiLag(true)
                    StatusText.Text = "เปิดโหมดกันหน่วง (Low Graphics) เรียบร้อยแล้ว!"
                else
                    applyAntiLag(false)
                    StatusText.Text = "ปิดโหมดกันหน่วง คืนค่ากราฟิกปกติ"
                end
                -- manual save only (user must click Save Now)
            end)
        end

        -- Row 2: FPS Cap Stepper
        do
            local Row2 = Instance.new("Frame")
            Row2.Size = UDim2.new(1, -24, 0, 28)
            Row2.Position = UDim2.new(0, 12, 0, 78)
            Row2.BackgroundTransparency = 1
            Row2.Parent = ALCard

            local R2Title = Instance.new("TextLabel")
            R2Title.Text = "ลด FPS เพื่อประหยัด CPU/การ์ดจอ:"
            R2Title.Font = Enum.Font.GothamMedium
            R2Title.TextSize = 10
            R2Title.TextColor3 = white
            R2Title.Size = UDim2.new(1, -155, 1, 0)
            R2Title.TextXAlignment = Enum.TextXAlignment.Left
            R2Title.BackgroundTransparency = 1
            R2Title.Parent = Row2

            local FPS_PRESETS = {10, 15, 20, 30, 45, 60, 120, 240}
            local function getFpsIndex(val)
                for i, p in ipairs(FPS_PRESETS) do
                    if p >= val then return i end
                end
                return #FPS_PRESETS
            end

            local MinusFpsBtn = Instance.new("TextButton")
            MinusFpsBtn.Text = "-"
            MinusFpsBtn.Font = Enum.Font.GothamBold
            MinusFpsBtn.TextSize = 14
            MinusFpsBtn.TextColor3 = white
            MinusFpsBtn.BackgroundColor3 = Color3.fromRGB(45, 60, 75)
            MinusFpsBtn.Size = UDim2.new(0, 30, 0, 26)
            MinusFpsBtn.Position = UDim2.new(1, -145, 0.5, -13)
            MinusFpsBtn.BorderSizePixel = 0
            MinusFpsBtn.Parent = Row2
            local MFCorner = Instance.new("UICorner")
            MFCorner.CornerRadius = UDim.new(0, 4)
            MFCorner.Parent = MinusFpsBtn
            makeButtonSmooth(MinusFpsBtn)

            local valLabel = Instance.new("TextLabel")
            valLabel.Text = (state.fpsCap or 60) .. " FPS"
            valLabel.Font = Enum.Font.GothamBold
            valLabel.TextSize = 11
            valLabel.TextColor3 = accent
            valLabel.Size = UDim2.new(0, 70, 0, 26)
            valLabel.Position = UDim2.new(1, -110, 0.5, -13)
            valLabel.BackgroundTransparency = 1
            valLabel.Parent = Row2
            uiRefs.ALFpsVal = valLabel

            local PlusFpsBtn = Instance.new("TextButton")
            PlusFpsBtn.Text = "+"
            PlusFpsBtn.Font = Enum.Font.GothamBold
            PlusFpsBtn.TextSize = 14
            PlusFpsBtn.TextColor3 = white
            PlusFpsBtn.BackgroundColor3 = Color3.fromRGB(45, 60, 75)
            PlusFpsBtn.Size = UDim2.new(0, 30, 0, 26)
            PlusFpsBtn.Position = UDim2.new(1, -35, 0.5, -13)
            PlusFpsBtn.BorderSizePixel = 0
            PlusFpsBtn.Parent = Row2
            local PFCorner = Instance.new("UICorner")
            PFCorner.CornerRadius = UDim.new(0, 4)
            PFCorner.Parent = PlusFpsBtn
            makeButtonSmooth(PlusFpsBtn)

            MinusFpsBtn.MouseButton1Click:Connect(function()
                local idx = getFpsIndex(state.fpsCap or 60)
                if idx > 1 then
                    state.fpsCap = FPS_PRESETS[idx - 1]
                    valLabel.Text = state.fpsCap .. " FPS"
                    applyFpsCap(state.fpsCap)
                    StatusText.Text = string.format("จำกัด FPS เป็น %d FPS แล้ว", state.fpsCap)
                    -- manual save only (user must click Save Now)
                end
            end)

            PlusFpsBtn.MouseButton1Click:Connect(function()
                local idx = getFpsIndex(state.fpsCap or 60)
                if idx < #FPS_PRESETS then
                    state.fpsCap = FPS_PRESETS[idx + 1]
                    valLabel.Text = state.fpsCap .. " FPS"
                    applyFpsCap(state.fpsCap)
                    StatusText.Text = string.format("จำกัด FPS เป็น %d FPS แล้ว", state.fpsCap)
                    -- manual save only (user must click Save Now)
                end
            end)
        end

        -- Row 3: GPU Saver
        do
            local Row3 = Instance.new("Frame")
            Row3.Size = UDim2.new(1, -24, 0, 28)
            Row3.Position = UDim2.new(0, 12, 0, 110)
            Row3.BackgroundTransparency = 1
            Row3.Parent = ALCard

            local R3Title = Instance.new("TextLabel")
            R3Title.Text = "โหมดประหยัดการ์ดจอ (ปิดภาพ 3D ลดโหลดเหลือ 1%):"
            R3Title.Font = Enum.Font.GothamMedium
            R3Title.TextSize = 10
            R3Title.TextColor3 = white
            R3Title.Size = UDim2.new(1, -75, 1, 0)
            R3Title.TextXAlignment = Enum.TextXAlignment.Left
            R3Title.BackgroundTransparency = 1
            R3Title.Parent = Row3

            local gpuBtn = Instance.new("TextButton")
            gpuBtn.Text = state.gpuSaver and "เปิด" or "ปิด"
            gpuBtn.Font = Enum.Font.GothamBold
            gpuBtn.TextSize = 10
            gpuBtn.TextColor3 = state.gpuSaver and Color3.fromRGB(10, 20, 30) or white
            gpuBtn.BackgroundColor3 = state.gpuSaver and accent or Color3.fromRGB(45, 60, 75)
            gpuBtn.Size = UDim2.new(0, 60, 0, 26)
            gpuBtn.Position = UDim2.new(1, -60, 0.5, -13)
            gpuBtn.BorderSizePixel = 0
            gpuBtn.Parent = Row3
            local gCorner = Instance.new("UICorner")
            gCorner.CornerRadius = UDim.new(0, 4)
            gCorner.Parent = gpuBtn
            uiRefs.GPUToggle = gpuBtn

            makeButtonSmooth(gpuBtn)
            gpuBtn.MouseButton1Click:Connect(function()
                state.gpuSaver = not state.gpuSaver
                animateButtonToggle(gpuBtn, state.gpuSaver, "เปิด", "ปิด")
                if state.gpuSaver then
                    applyGpuSaver(true)
                    StatusText.Text = "เปิดโหมดประหยัดการ์ดจอ (ปิด 3D Rendering) ลดโหลดการ์ดจอสมบูรณ์!"
                else
                    applyGpuSaver(false)
                    StatusText.Text = "เปิดการเรนเดอร์ภาพ 3D ตามปกติ"
                end
                -- manual save only (user must click Save Now)
            end)
        end

        -- Row 4: Clean RAM Now Button
        do
            local CleanRamBtn = Instance.new("TextButton")
            CleanRamBtn.Text = "ล้างแคชและคืนหน่วยความจำทันที (Clean Memory Now)"
            CleanRamBtn.Font = Enum.Font.GothamBold
            CleanRamBtn.TextSize = 10
            CleanRamBtn.TextColor3 = Color3.fromRGB(10, 20, 30)
            CleanRamBtn.BackgroundColor3 = accent
            CleanRamBtn.Size = UDim2.new(1, -24, 0, 26)
            CleanRamBtn.Position = UDim2.new(0, 12, 0, 142)
            CleanRamBtn.BorderSizePixel = 0
            CleanRamBtn.Parent = ALCard
            local CRBCorner = Instance.new("UICorner")
            CRBCorner.CornerRadius = UDim.new(0, 4)
            CRBCorner.Parent = CleanRamBtn
            makeButtonSmooth(CleanRamBtn)

            CleanRamBtn.MouseButton1Click:Connect(function()
                local beforeMem = gcinfo()
                pcall(function() collectgarbage("collect") end)
                local afterMem = gcinfo()
                local freed = math.max(0, beforeMem - afterMem)
                StatusText.Text = string.format("ล้างหน่วยความจำสำเร็จ! คืนแรมแล้ว %.1f MB (ปัจจุบันใช้: %.1f MB)", freed / 1024, afterMem / 1024)
            end)
        end

        -- Row 5: Live Monitor
        do
            local monLabel = Instance.new("TextLabel")
            monLabel.Text = string.format("FPS ปัจจุบัน: -- FPS | ใช้ RAM: %.1f MB", gcinfo() / 1024)
            monLabel.Font = Enum.Font.Gotham
            monLabel.TextSize = 9
            monLabel.TextColor3 = muted
            monLabel.Position = UDim2.new(0, 12, 0, 172)
            monLabel.Size = UDim2.new(1, -24, 0, 16)
            monLabel.TextXAlignment = Enum.TextXAlignment.Left
            monLabel.BackgroundTransparency = 1
            monLabel.Parent = ALCard
            uiRefs.FPSMonitorLabel = monLabel
        end
    end

    -- [ FPS & MEMORY MONITOR BACKGROUND LOOP ]
    task.spawn(function()
        local frameCount = 0
        local lastTime = os.clock()
        local curFps = 60
        RunService.RenderStepped:Connect(function()
            frameCount = frameCount + 1
            local now = os.clock()
            if now - lastTime >= 1 then
                curFps = math.floor(frameCount / (now - lastTime))
                frameCount = 0
                lastTime = now
                if uiRefs.FPSMonitorLabel and uiRefs.FPSMonitorLabel.Parent then
                    uiRefs.FPSMonitorLabel.Text = string.format("FPS ปัจจุบัน: %d FPS (ขีดจำกัด: %s) | ใช้ RAM: %.1f MB", curFps, (state.fpsCap and tostring(state.fpsCap) .. " FPS") or "ไม่จำกัด", gcinfo() / 1024)
                end
            end
        end)
    end)

    -- 4. Configuration Management Card
    do
        local ConfigCard = Instance.new("Frame")
        ConfigCard.Size = UDim2.new(1, -10, 0, 138)
        ConfigCard.BackgroundColor3 = panel
        ConfigCard.BorderSizePixel = 0
        ConfigCard.Parent = setTab
        local CFGCorner = Instance.new("UICorner")
        CFGCorner.CornerRadius = UDim.new(0, 6)
        CFGCorner.Parent = ConfigCard
        local CFGStroke = Instance.new("UIStroke")
        CFGStroke.Color = borderColor
        CFGStroke.Parent = ConfigCard

        local CFGTitle = Instance.new("TextLabel")
        CFGTitle.Text = "ระบบบันทึกและจัดการคอนฟิก (Config Manager)"
        CFGTitle.Font = Enum.Font.GothamBold
        CFGTitle.TextSize = 11
        CFGTitle.TextColor3 = accent
        CFGTitle.Position = UDim2.new(0, 12, 0, 8)
        CFGTitle.Size = UDim2.new(1, -90, 0, 16)
        CFGTitle.TextXAlignment = Enum.TextXAlignment.Left
        CFGTitle.BackgroundTransparency = 1
        CFGTitle.Parent = ConfigCard

        local CFGDesc = Instance.new("TextLabel")
        CFGDesc.Text = "บันทึกค่าการตั้งค่าทั้งหมด (เปิดฟาร์ม, กินข้าว/น้ำ, รีจอย, ความสูง) ลงไฟล์เครื่อง"
        CFGDesc.Font = Enum.Font.Gotham
        CFGDesc.TextSize = 9
        CFGDesc.TextColor3 = muted
        CFGDesc.Position = UDim2.new(0, 12, 0, 26)
        CFGDesc.Size = UDim2.new(1, -90, 0, 16)
        CFGDesc.TextXAlignment = Enum.TextXAlignment.Left
        CFGDesc.BackgroundTransparency = 1
        CFGDesc.Parent = ConfigCard

        AutoSaveToggle = Instance.new("TextButton")
        AutoSaveToggle.Text = state.autoSaveConfig and "เปิด" or "ปิด"
        AutoSaveToggle.Font = Enum.Font.GothamBold
        AutoSaveToggle.TextSize = 10
        AutoSaveToggle.TextColor3 = state.autoSaveConfig and Color3.fromRGB(10, 20, 30) or white
        AutoSaveToggle.BackgroundColor3 = state.autoSaveConfig and accent or Color3.fromRGB(45, 60, 75)
        AutoSaveToggle.Size = UDim2.new(0, 60, 0, 28)
        AutoSaveToggle.Position = UDim2.new(1, -72, 0, 10)
        AutoSaveToggle.BorderSizePixel = 0
        AutoSaveToggle.Parent = ConfigCard
        local ASTCorner = Instance.new("UICorner")
        ASTCorner.CornerRadius = UDim.new(0, 4)
        ASTCorner.Parent = AutoSaveToggle

        makeButtonSmooth(AutoSaveToggle)
        AutoSaveToggle.MouseButton1Click:Connect(function()
            state.autoSaveConfig = not state.autoSaveConfig
            animateButtonToggle(AutoSaveToggle, state.autoSaveConfig, "เปิด", "ปิด")
            if state.autoSaveConfig then
                saveConfig()
            end
        end)

        CFGStatus = Instance.new("TextLabel")
        CFGStatus.Text = (isfile and isfile(CONFIG_PATH)) and "ไฟล์คอนฟิก: NexusHub/config.json (พร้อมใช้งาน)" or "ไฟล์คอนฟิก: ยังไม่มีไฟล์ (กดบันทึกเพื่อสร้าง)"
        CFGStatus.Font = Enum.Font.GothamMedium
        CFGStatus.TextSize = 9
        CFGStatus.TextColor3 = white
        CFGStatus.Position = UDim2.new(0, 12, 0, 48)
        CFGStatus.Size = UDim2.new(1, -24, 0, 16)
        CFGStatus.TextXAlignment = Enum.TextXAlignment.Left
        CFGStatus.BackgroundTransparency = 1
        CFGStatus.Parent = ConfigCard

        local SaveBtn = Instance.new("TextButton")
        SaveBtn.Text = "บันทึกคอนฟิกลงเครื่อง (Save Now)"
        SaveBtn.Font = Enum.Font.GothamBold
        SaveBtn.TextSize = 10
        SaveBtn.TextColor3 = Color3.fromRGB(10, 20, 30)
        SaveBtn.BackgroundColor3 = accent
        SaveBtn.Size = UDim2.new(0.48, -12, 0, 28)
        SaveBtn.Position = UDim2.new(0, 12, 0, 72)
        SaveBtn.BorderSizePixel = 0
        SaveBtn.Parent = ConfigCard
        local SBCorner = Instance.new("UICorner")
        SBCorner.CornerRadius = UDim.new(0, 4)
        SBCorner.Parent = SaveBtn
        makeButtonSmooth(SaveBtn)

        SaveBtn.MouseButton1Click:Connect(function()
            local ok = saveConfig()
            if ok then
                CFGStatus.Text = "บันทึกค่าคอนฟิกสำเร็จ! (" .. os.date("%X") .. ")"
                StatusText.Text = "บันทึกคอนฟิกเรียบร้อยแล้ว"
            else
                CFGStatus.Text = "บันทึกล้มเหลว (ตรวจสอบสิทธิ์ไฟล์)"
            end
        end)

        local LoadBtn = Instance.new("TextButton")
        LoadBtn.Text = "โหลดคอนฟิกจากเครื่อง (Reload)"
        LoadBtn.Font = Enum.Font.GothamBold
        LoadBtn.TextSize = 10
        LoadBtn.TextColor3 = white
        LoadBtn.BackgroundColor3 = Color3.fromRGB(45, 60, 75)
        LoadBtn.Size = UDim2.new(0.48, -12, 0, 28)
        LoadBtn.Position = UDim2.new(0.52, 0, 0, 72)
        LoadBtn.BorderSizePixel = 0
        LoadBtn.Parent = ConfigCard
        local LBCorner = Instance.new("UICorner")
        LBCorner.CornerRadius = UDim.new(0, 4)
        LBCorner.Parent = LoadBtn
        makeButtonSmooth(LoadBtn)

        LoadBtn.MouseButton1Click:Connect(function()
            local ok = loadConfig()
            if ok then
                if syncUIFromState then syncUIFromState() end
                CFGStatus.Text = "โหลดค่าคอนฟิกสำเร็จ! (" .. os.date("%X") .. ")"
                StatusText.Text = "โหลดคอนฟิกเรียบร้อยแล้ว"
            else
                CFGStatus.Text = "ยังไม่พบไฟล์คอนฟิกในเครื่อง"
            end
        end)

        local ResetBtn = Instance.new("TextButton")
        ResetBtn.Text = "รีเซ็ตค่าคอนฟิกเป็นค่าเริ่มต้น (Reset Defaults)"
        ResetBtn.Font = Enum.Font.GothamMedium
        ResetBtn.TextSize = 10
        ResetBtn.TextColor3 = muted
        ResetBtn.BackgroundColor3 = Color3.fromRGB(28, 42, 55)
        ResetBtn.Size = UDim2.new(1, -24, 0, 24)
        ResetBtn.Position = UDim2.new(0, 12, 0, 106)
        ResetBtn.BorderSizePixel = 0
        ResetBtn.Parent = ConfigCard
        local RBCorner = Instance.new("UICorner")
        RBCorner.CornerRadius = UDim.new(0, 4)
        RBCorner.Parent = ResetBtn
        makeButtonSmooth(ResetBtn)

        ResetBtn.MouseButton1Click:Connect(function()
            state.sandwich = false
            state.mangoRice = false
            state.bananaFarm = false
            state.fishFarm = false
            state.rockFarm = false
            state.svibFarm = false
            state.walkInDistance = 100.0
            state.undergroundDepth = 15.0
            state.autoEat = true
            state.autoDrink = true
            state.eatThreshold = 50
            state.drinkThreshold = 50
            state.antiAfk = true
            state.autoRejoin = true
            state.autoLowestServer = false
            state.serverHopPlayerLimitEnabled = false
            state.maxPlayersLimit = 25
            state.antiLag = false
            state.fpsCap = 60
            state.gpuSaver = false
            applyAntiLag(false)
            applyFpsCap(60)
            applyGpuSaver(false)
            state.autoSaveConfig = false
            if syncUIFromState then syncUIFromState() end
            CFGStatus.Text = "รีเซ็ตค่าคอนฟิกเป็นค่าเริ่มต้นเรียบร้อย! (กดบันทึกเพื่อยืนยัน)"
            StatusText.Text = "รีเซ็ตคอนฟิกเป็นค่าเริ่มต้นแล้ว"
        end)
    end
    -- Bypass Status Info Card
    do
        local BypassInfoCard = Instance.new("Frame")
        BypassInfoCard.Size = UDim2.new(1, -10, 0, 65)
        BypassInfoCard.BackgroundColor3 = panel
        BypassInfoCard.BorderSizePixel = 0
        BypassInfoCard.Parent = setTab
        local BICorner = Instance.new("UICorner")
        BICorner.CornerRadius = UDim.new(0, 6)
        BICorner.Parent = BypassInfoCard
        local BIStroke = Instance.new("UIStroke")
        BIStroke.Color = borderColor
        BIStroke.Parent = BypassInfoCard

        local BITitle = Instance.new("TextLabel")
        BITitle.Text = "สถานะระบบป้องกัน RedTownAntiX & Kick Bypass"
        BITitle.Font = Enum.Font.GothamBold
        BITitle.TextSize = 11
        BITitle.TextColor3 = accent
        BITitle.Position = UDim2.new(0, 12, 0, 8)
        BITitle.Size = UDim2.new(1, -24, 0, 16)
        BITitle.TextXAlignment = Enum.TextXAlignment.Left
        BITitle.BackgroundTransparency = 1
        BITitle.Parent = BypassInfoCard

        local BIDesc = Instance.new("TextLabel")
        BIDesc.Text = "ปลอดภัย 100% ไม่ใช้ Hook | เคลื่อนที่ใต้ดินปลอดภัย ลบวงสีขาวใต้เท้าเรียบร้อย"
        BIDesc.Font = Enum.Font.Gotham
        BIDesc.TextSize = 10
        BIDesc.TextColor3 = white
        BIDesc.Position = UDim2.new(0, 12, 0, 28)
        BIDesc.Size = UDim2.new(1, -24, 0, 16)
        BIDesc.TextXAlignment = Enum.TextXAlignment.Left
        BIDesc.BackgroundTransparency = 1
        BIDesc.Parent = BypassInfoCard
    end

    -- Define syncUIFromState to refresh all GUI widgets when config loads or resets
    syncUIFromState = function()
        pcall(function()
            if EatToggle then
                EatToggle.Text = state.autoEat and "เปิด" or "ปิด"
                EatToggle.BackgroundColor3 = state.autoEat and accent or Color3.fromRGB(45, 60, 75)
                EatToggle.TextColor3 = state.autoEat and Color3.fromRGB(10, 20, 30) or white
            end
            if EatVal then
                EatVal.Text = state.eatThreshold .. "%"
            end
            if DrinkToggle then
                DrinkToggle.Text = state.autoDrink and "เปิด" or "ปิด"
                DrinkToggle.BackgroundColor3 = state.autoDrink and accent or Color3.fromRGB(45, 60, 75)
                DrinkToggle.TextColor3 = state.autoDrink and Color3.fromRGB(10, 20, 30) or white
            end
            if DrinkVal then
                DrinkVal.Text = state.drinkThreshold .. "%"
            end
            if ValLabel then
                ValLabel.Text = (state.moveSpeed or 36) .. " studs/s"
            end
            if WalkValLabel then
                WalkValLabel.Text = (state.walkInDistance or 100.0) .. " studs"
            end
            if AAToggle then
                AAToggle.Text = state.antiAfk and "เปิด" or "ปิด"
                AAToggle.BackgroundColor3 = state.antiAfk and accent or Color3.fromRGB(45, 60, 75)
                AAToggle.TextColor3 = state.antiAfk and Color3.fromRGB(10, 20, 30) or white
            end
            if RJToggle then
                RJToggle.Text = state.autoRejoin and "เปิด" or "ปิด"
                RJToggle.BackgroundColor3 = state.autoRejoin and accent or Color3.fromRGB(45, 60, 75)
                RJToggle.TextColor3 = state.autoRejoin and Color3.fromRGB(10, 20, 30) or white
            end
            if SCToggle then
                SCToggle.Text = state.autoLowestServer and "เปิด" or "ปิด"
                SCToggle.BackgroundColor3 = state.autoLowestServer and accent or Color3.fromRGB(45, 60, 75)
                SCToggle.TextColor3 = state.autoLowestServer and Color3.fromRGB(10, 20, 30) or white
            end
            if uiRefs.PlayerLimitToggle then
                uiRefs.PlayerLimitToggle.Text = state.serverHopPlayerLimitEnabled and "เปิด" or "ปิด"
                uiRefs.PlayerLimitToggle.BackgroundColor3 = state.serverHopPlayerLimitEnabled and accent or Color3.fromRGB(45, 60, 75)
                uiRefs.PlayerLimitToggle.TextColor3 = state.serverHopPlayerLimitEnabled and Color3.fromRGB(10, 20, 30) or white
            end
            if uiRefs.PlayerLimitValLabel then
                uiRefs.PlayerLimitValLabel.Text = (state.maxPlayersLimit or 25) .. " คน"
            end
            if uiRefs.ALToggle then
                uiRefs.ALToggle.Text = state.antiLag and "เปิด" or "ปิด"
                uiRefs.ALToggle.BackgroundColor3 = state.antiLag and accent or Color3.fromRGB(45, 60, 75)
                uiRefs.ALToggle.TextColor3 = state.antiLag and Color3.fromRGB(10, 20, 30) or white
            end
            if uiRefs.ALFpsVal then
                uiRefs.ALFpsVal.Text = (state.fpsCap or 60) .. " FPS"
            end
            if uiRefs.GPUToggle then
                uiRefs.GPUToggle.Text = state.gpuSaver and "เปิด" or "ปิด"
                uiRefs.GPUToggle.BackgroundColor3 = state.gpuSaver and accent or Color3.fromRGB(45, 60, 75)
                uiRefs.GPUToggle.TextColor3 = state.gpuSaver and Color3.fromRGB(10, 20, 30) or white
            end
            if AutoSaveToggle then
                AutoSaveToggle.Text = state.autoSaveConfig and "เปิด" or "ปิด"
                AutoSaveToggle.BackgroundColor3 = state.autoSaveConfig and accent or Color3.fromRGB(45, 60, 75)
                AutoSaveToggle.TextColor3 = state.autoSaveConfig and Color3.fromRGB(10, 20, 30) or white
            end
            if swSection and swSection.setVisualOnly then
                swSection.setVisualOnly(state.sandwich)
            end
            if mrSection and mrSection.setVisualOnly then
                mrSection.setVisualOnly(state.mangoRice)
            end
            if bananaSection and bananaSection.setVisualOnly then
                bananaSection.setVisualOnly(state.bananaFarm)
            end
            if fishingSection and fishingSection.setVisualOnly then
                fishingSection.setVisualOnly(state.fishFarm)
            end
            if rockSection and rockSection.setVisualOnly then
                rockSection.setVisualOnly(state.rockFarm)
            end
            if svibSection and svibSection.setVisualOnly then
                svibSection.setVisualOnly(state.svibFarm)
            end
            if vaultSection and vaultSection.setVisualOnly then
                vaultSection.setVisualOnly(state.autoVaultOres)
            end
        end)
    end

    -- Initial visual sync
    syncUIFromState()

    _G.NexusHubState = state
    _G.NexusHubControl = {
        saveConfig = saveConfig,
        loadConfig = loadConfig,
        swSection = swSection,
        mrSection = mrSection,
        bananaSection = bananaSection,
        fishingSection = fishingSection,
        rockSection = rockSection,
        svibSection = svibSection,
        vaultSection = vaultSection,
        syncUIFromState = syncUIFromState,
        StatusText = StatusText
    }

    return {success = true}
end)

if not success then
    warn("[NEXUS HUB ERROR]: " .. tostring(err))
else
    print("[NEXUS HUB]: Loaded successfully!")
end


-- ==============================================================================
-- NEXUS HUB - LIVE SERVER RESTART & KICK LISTENER (MAP 2: TYPER)
-- ดักจับสัญญาณรีสตาร์ทสคริปต์จากแดชบอร์ดแอดมิน เพื่อเตะผู้เล่นออกจากเกมทันที
-- ==============================================================================
task.spawn(function()
    local RESTART_API = "https://admin-menu-api.ushshkzwyy.workers.dev/api/system/restart"
    local initialBootTimestamp = 0
    local hasKicked = false

    pcall(function()
        local ok, res = pcall(function() return game:HttpGet(RESTART_API .. "?t=" .. tick()) end)
        if ok and res then
            local ts = res:match('"timestamp":(%d+)')
            if ts then initialBootTimestamp = tonumber(ts) or 0 end
        end
    end)

    if initialBootTimestamp == 0 then initialBootTimestamp = os.time() * 1000 end

    while not hasKicked do
        task.wait(5)
        pcall(function()
            local ok, res = pcall(function() return game:HttpGet(RESTART_API .. "?t=" .. tick()) end)
            if ok and res then
                local currentTs = tonumber(res:match('"timestamp":(%d+)'))
                if currentTs and currentTs > initialBootTimestamp then
                    hasKicked = true
                    local reason = res:match('"reason":"([^"]+)"') or "แอดมินสั่งรีสตาร์ทสคริปต์จากระบบหลังบ้าน"

                    pcall(function()
                        local CoreGui = game:GetService("CoreGui")
                        local Players = game:GetService("Players")
                        local lp = Players.LocalPlayer
                        if CoreGui:FindFirstChild("ModernGamingUI") then CoreGui.ModernGamingUI:Destroy() end
                        if CoreGui:FindFirstChild("NexusHub_GUI") then CoreGui.NexusHub_GUI:Destroy() end
                        if CoreGui:FindFirstChild("NexusHubKeySystem") then CoreGui.NexusHubKeySystem:Destroy() end
                        if lp and lp:FindFirstChild("PlayerGui") then
                            if lp.PlayerGui:FindFirstChild("ModernGamingUI") then lp.PlayerGui.ModernGamingUI:Destroy() end
                            if lp.PlayerGui:FindFirstChild("NexusHub_GUI") then lp.PlayerGui.NexusHub_GUI:Destroy() end
                        end
                    end)

                    task.wait(0.2)
                    pcall(function()
                        local kickMessage = "[ForceKick]\n\n========================================\n[ NEXUS HUB - สั่งรีสตาร์ทสคริปต์ ]\n========================================\n\n📌 เหตุผล: " .. reason .. "\n\n💡 กรุณาเข้าเกมใหม่และรันสคริปต์อีกครั้งครับ"
                        game:GetService("Players").LocalPlayer:Kick(kickMessage)
                    end)
                end
            end
        end)
    end
end)


return {success = success, err = tostring(err)}
