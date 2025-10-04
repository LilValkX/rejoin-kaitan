-- 📦 ดึง Service สำคัญจากเกม
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- 🎮 รอจนกว่าเกมโหลดเสร็จและมี LocalPlayer
repeat task.wait() until game:IsLoaded() and Players.LocalPlayer
local player = Players.LocalPlayer

-- 🛡️ Anti-AFK System
player.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-- =====================================================
-- ⚙️ CONFIG : ค่าการตั้งค่าพื้นฐานทั้งหมดของระบบ
-- =====================================================
local CONFIG = {
    FIRST_MAP_ID = 16146832113,      -- Map 1 : Lobby
    SECOND_MAP_ID = 16277809958,     -- Map 2 : Gameplay

    SPAWN_TIME = 34,                 -- เวลาที่เริ่มวางตัว
    SPAWN_DELAY = 0.7,               -- หน่วงเวลาระหว่างการวางแต่ละตัว
    UPGRADE_DELAY = 1,               -- หน่วงเวลาระหว่างอัปเกรดแต่ละตัว
    UPGRADE_COOLDOWN = 5,            -- เวลาระหว่างการอัปเกรดรอบถัดไป
    VOTE_WAIT = 1,                   -- หน่วงเวลาก่อนโหวตรีสตาร์ท
    HEARTBEAT_INTERVAL = 0.5,        -- จังหวะในการเช็กสถานะทุกๆ รอบ

    UNIT_LEVEL = 264,                -- เลเวลของยูนิตที่จะวาง
    UNIT_NAMES = {"Hei", "Quetzalcoatl", "Leo", "Newsman", "Ali"}, -- ชื่อตัวที่จะวาง
    SPAWN_POSITION = Vector3.new(-367.024, 14.299, -204.871),       -- จุดวางยูนิต

    CARD_WAVES = {3, 6, 9},          -- Wave ที่จะเลือกการ์ด
    FINAL_WAVE = 10,                 -- Wave สุดท้าย

    SKIP_WAVE_TIMEOUT = 30,          -- เวลารอ Skip Wave
    WAITFORCHILD_TIMEOUT = 10        -- เวลารอ UI/Instance
}

-- =====================================================
-- 🧠 STATE : ตัวแปรเก็บสถานะระหว่างเล่นเกม
-- =====================================================
local GameState = {
    hasSpawned = false,              -- เคยวางยูนิตหรือยัง
    missedSpawnTime = false,         -- พลาดเวลาวางไหม
    lastUpgradeTime = 0,             -- เวลาอัปเกรดล่าสุด
    lastHeartbeatCheck = 0,          -- เวลาเช็กสถานะล่าสุด
    processedWaves = {},             -- Wave ที่เคยทำไปแล้ว
    currentWave = 0,                 -- Wave ปัจจุบัน
    currentAction = "Idle"           -- การกระทำปัจจุบัน
}

-- 🔌 เก็บ Connection เพื่อให้สามารถ Disconnect ได้
local heartbeatConnection = nil

-- 📊 เก็บ GUI Labels เพื่อใช้อัปเดตสถานะ
local GUILabels = {
    wave = nil,
    doing = nil
}

-- =====================================================
-- 🖥️ GUI SYSTEM : สร้าง Farming Status GUI
-- =====================================================
local GUI = {}

function GUI.create()
    local playerGui = player:WaitForChild("PlayerGui")
    
    -- Remove existing GUI if present
    if playerGui:FindFirstChild("FarmingStatusGui") then
        playerGui.FarmingStatusGui:Destroy()
    end

    -- Create main ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "FarmingStatusGui"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.IgnoreGuiInset = true
    screenGui.DisplayOrder = 999999
    screenGui.Parent = playerGui

    -- Semi-transparent black background
    local backgroundFrame = Instance.new("Frame")
    backgroundFrame.Name = "Background"
    backgroundFrame.Size = UDim2.new(1, 0, 1, 0)
    backgroundFrame.Position = UDim2.new(0, 0, 0, 0)
    backgroundFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    backgroundFrame.BackgroundTransparency = 0.05
    backgroundFrame.BorderSizePixel = 0
    backgroundFrame.ZIndex = 1
    backgroundFrame.Parent = screenGui

    -- Name text
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameId"
    nameLabel.Size = UDim2.new(1, 0, 0, 50)
    nameLabel.Position = UDim2.new(0, 0, 0, 40)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextSize = 38
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextXAlignment = Enum.TextXAlignment.Center
    nameLabel.TextStrokeTransparency = 0.7
    nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    nameLabel.Parent = backgroundFrame

    -- Status text with typing animation
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "Status"
    statusLabel.Size = UDim2.new(1, 0, 0, 50)
    statusLabel.Position = UDim2.new(0, 0, 0, 100)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "Status: "
    statusLabel.TextColor3 = Color3.fromRGB(150, 255, 150)
    statusLabel.TextSize = 38
    statusLabel.Font = Enum.Font.GothamBold
    statusLabel.TextXAlignment = Enum.TextXAlignment.Center
    statusLabel.TextStrokeTransparency = 0.7
    statusLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    statusLabel.Parent = backgroundFrame

    -- Wave text
    local waveLabel = Instance.new("TextLabel")
    waveLabel.Name = "Wave"
    waveLabel.Size = UDim2.new(1, 0, 0, 45)
    waveLabel.Position = UDim2.new(0, 0, 0, 160)
    waveLabel.BackgroundTransparency = 1
    waveLabel.Text = "Wave: 0"
    waveLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
    waveLabel.TextSize = 34
    waveLabel.Font = Enum.Font.GothamBold
    waveLabel.TextXAlignment = Enum.TextXAlignment.Center
    waveLabel.TextStrokeTransparency = 0.7
    waveLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    waveLabel.Parent = backgroundFrame
    GUILabels.wave = waveLabel

    -- Doing text
    local doingLabel = Instance.new("TextLabel")
    doingLabel.Name = "Doing"
    doingLabel.Size = UDim2.new(1, 0, 0, 45)
    doingLabel.Position = UDim2.new(0, 0, 0, 215)
    doingLabel.BackgroundTransparency = 1
    doingLabel.Text = "Doing: Idle"
    doingLabel.TextColor3 = Color3.fromRGB(150, 200, 255)
    doingLabel.TextSize = 34
    doingLabel.Font = Enum.Font.GothamBold
    doingLabel.TextXAlignment = Enum.TextXAlignment.Center
    doingLabel.TextStrokeTransparency = 0.7
    doingLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    doingLabel.Parent = backgroundFrame
    GUILabels.doing = doingLabel

    -- Typing animation function
    local function animateTyping()
        local prefix = "Status: "
        local fullText = "Farming..."
        local displayText = ""
        
        while statusLabel and statusLabel.Parent do
            statusLabel.Text = prefix
            for i = 1, #fullText do
                displayText = string.sub(fullText, 1, i)
                statusLabel.Text = prefix .. displayText
                wait(0.15)
            end
            wait(2)
            for i = #fullText, 0, -1 do
                displayText = string.sub(fullText, 1, i)
                statusLabel.Text = prefix .. displayText
                wait(0.07)
            end
            wait(0.5)
        end
    end
    spawn(animateTyping)

    -- Center image (logo)
    local centerImage = Instance.new("ImageLabel")
    centerImage.Name = "CenterImage"
    centerImage.Size = UDim2.new(0, 150, 0, 150)
    centerImage.Position = UDim2.new(0.5, -75, 0.5, -75)
    centerImage.Image = "rbxassetid://82367645016830"
    centerImage.BackgroundTransparency = 1
    centerImage.ZIndex = 3
    centerImage.Parent = screenGui

    local imageCorner = Instance.new("UICorner")
    imageCorner.CornerRadius = UDim.new(0, 20)
    imageCorner.Parent = centerImage

    -- Toggle button
    local toggleButton = Instance.new("ImageButton")
    toggleButton.Name = "ToggleButton"
    toggleButton.Size = UDim2.new(0, 150, 0, 150)
    toggleButton.Position = centerImage.Position
    toggleButton.BackgroundTransparency = 1
    toggleButton.Image = ""
    toggleButton.ZIndex = 4
    toggleButton.Parent = screenGui

    -- FPS Counter
    local fpsLabel = Instance.new("TextLabel")
    fpsLabel.Name = "FPSLabel"
    fpsLabel.Size = UDim2.new(0, 300, 0, 60)
    fpsLabel.Position = UDim2.new(0.5, -150, 1, -150)
    fpsLabel.BackgroundTransparency = 1
    fpsLabel.Text = "FPS: --"
    fpsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    fpsLabel.TextSize = 48
    fpsLabel.Font = Enum.Font.GothamBold
    fpsLabel.TextStrokeTransparency = 0.5
    fpsLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    fpsLabel.ZIndex = 2
    fpsLabel.Parent = backgroundFrame

    -- FPS Counter Loop
    spawn(function()
        while screenGui.Parent do
            local fps = math.floor(1 / RunService.RenderStepped:Wait())
            fpsLabel.Text = "FPS: " .. fps
            wait(0.5)
        end
    end)

    -- Logo click functionality
    local isMinimized = false
    toggleButton.MouseButton1Click:Connect(function()
        isMinimized = not isMinimized
        if isMinimized then
            -- Hide all text elements
            nameLabel.Visible = false
            statusLabel.Visible = false
            waveLabel.Visible = false
            doingLabel.Visible = false
            fpsLabel.Visible = false
            
            -- Move to top-right and scale down
            local tween = TweenService:Create(centerImage, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Position = UDim2.new(1, -85, 0, 100),
                Size = UDim2.new(0, 75, 0, 75)
            })
            local buttonTween = TweenService:Create(toggleButton, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Position = UDim2.new(1, -85, 0, 100),
                Size = UDim2.new(0, 75, 0, 75)
            })
            tween:Play()
            buttonTween:Play()
            backgroundFrame.BackgroundTransparency = 0.9
        else
            -- Show all text elements
            nameLabel.Visible = true
            statusLabel.Visible = true
            waveLabel.Visible = true
            doingLabel.Visible = true
            fpsLabel.Visible = true
            
            -- Return to center
            local tween = TweenService:Create(centerImage, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Position = UDim2.new(0.5, -75, 0.5, -75),
                Size = UDim2.new(0, 150, 0, 150)
            })
            local buttonTween = TweenService:Create(toggleButton, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Position = UDim2.new(0.5, -75, 0.5, -75),
                Size = UDim2.new(0, 150, 0, 150)
            })
            tween:Play()
            buttonTween:Play()
            backgroundFrame.BackgroundTransparency = 0.05
        end
    end)

    -- P key to toggle GUI
    screenGui.Enabled = true
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.P then
            screenGui.Enabled = not screenGui.Enabled
        end
    end)

    print("✅ Farming Status GUI Loaded!")
end

-- อัปเดต GUI สถานะ
function GUI.updateStatus(action)
    GameState.currentAction = action
    if GUILabels.doing then
        GUILabels.doing.Text = "Doing: " .. action
    end
end

-- อัปเดต Wave
function GUI.updateWave(wave)
    if GUILabels.wave then
        GUILabels.wave.Text = "Wave: " .. tostring(wave)
    end
end

-- =====================================================
-- 🔧 UTILS : ฟังก์ชันช่วยเหลือทั่วไป
-- =====================================================
local Utils = {}

-- แปลงเวลาในรูปแบบ HH:MM:SS → วินาที
function Utils.parseTime(timeStr)
    local h, m, s = timeStr:match("(%d+):(%d+):(%d+)")
    if not h or not m or not s then return 0 end
    return (tonumber(h) * 3600) + (tonumber(m) * 60) + tonumber(s)
end

-- ตัด tag HTML ออกจากข้อความ (ใช้กับ Wave Label)
function Utils.stripHTMLTags(text)
    local waveNum = text:match('<font transparency="0">(%d+)</font>')
    if waveNum then return waveNum end
    return text:gsub("<[^>]*>", "")
end

-- รอให้ Child ปรากฏโดยมี Timeout ปลอดภัย
function Utils.safeWaitForChild(parent, name, timeout)
    timeout = timeout or CONFIG.WAITFORCHILD_TIMEOUT
    local child = parent:WaitForChild(name, timeout)
    return child
end

-- =====================================================
-- 🌐 NETWORK : ฟังก์ชันส่งคำสั่ง FireServer ไปยังเซิร์ฟเวอร์
-- =====================================================
local Network = {}

-- ส่งคำสั่งไปยัง Event ตาม path ที่กำหนด
function Network.fireServer(path, args)
    local success = pcall(function()
        local event = ReplicatedStorage:WaitForChild("Networking", 5)
        for part in string.gmatch(path, "[^%.]+") do
            event = event:WaitForChild(part, 3)
        end
        event:FireServer(table.unpack(args))
    end)
    return success
end

-- สั่งวางยูนิต
function Network.spawnUnit(name)
    return Network.fireServer("UnitEvent", {"Render", {name, CONFIG.UNIT_LEVEL, CONFIG.SPAWN_POSITION, 0}})
end

-- สั่งอัปเกรดยูนิต
function Network.upgradeUnit(unitName)
    return Network.fireServer("UnitEvent", {"Upgrade", unitName})
end

-- เลือกการ์ดเมื่อถึง Wave ที่กำหนด
function Network.chooseCards()
    ReplicatedStorage:WaitForChild("Networking"):WaitForChild("ModifierEvent"):FireServer("Choose", "Evolution")
    task.wait(0.1)
    ReplicatedStorage:WaitForChild("Networking"):WaitForChild("ModifierEvent"):FireServer("Choose", "Nighttime")
end

-- โหวต Restart เกม
function Network.voteRestart()
    pcall(function()
        ReplicatedStorage:WaitForChild("Networking"):WaitForChild("MatchRestartSettingEvent"):FireServer("Vote")
    end)
end

-- กด Skip Wave
function Network.skipWave()
    return Network.fireServer("SkipWaveEvent", {"Skip"})
end

-- =====================================================
-- 🎯 GAME LOGIC : ตรรกะหลักระหว่างเล่นเกม
-- =====================================================
local GameLogic = {}

-- ✅ รอจนกว่าจะเจอปุ่ม SkipWave แล้วกดข้าม
function GameLogic.waitForSkipWave()
    GUI.updateStatus("Waiting for skip wave...")
    local playerGui = player:WaitForChild("PlayerGui", CONFIG.WAITFORCHILD_TIMEOUT)
    if not playerGui then return end
    local start = tick()
    while tick() - start < CONFIG.SKIP_WAVE_TIMEOUT do
        local skipWave = playerGui:FindFirstChild("SkipWave")
        if skipWave and skipWave:FindFirstChild("Holder") then
            local yesBtn = skipWave.Holder:FindFirstChild("Yes")
            if yesBtn and yesBtn.Visible then
                GUI.updateStatus("Skipping wave...")
                Network.skipWave()
                return true
            end
        end
        task.wait(0.3)
    end
end

-- ⚔️ วางยูนิตทั้งหมดตามรายชื่อใน CONFIG
function GameLogic.spawnAllUnits()
    GUI.updateStatus("Spawning units...")
    for _, name in ipairs(CONFIG.UNIT_NAMES) do
        Network.spawnUnit(name)
        task.wait(CONFIG.SPAWN_DELAY)
    end
    GameState.hasSpawned = true
    GUI.updateStatus("Units spawned")
end

-- 💎 อัปเกรดยูนิตทั้งหมดในแผนที่
function GameLogic.upgradeAllUnits()
    if tick() - GameState.lastUpgradeTime < CONFIG.UPGRADE_COOLDOWN then return end
    GUI.updateStatus("Upgrading units...")
    GameState.lastUpgradeTime = tick()
    local unitFolder = Workspace:FindFirstChild("Units")
    if not unitFolder then return end
    for _, unit in ipairs(unitFolder:GetChildren()) do
        if unit:IsA("Model") then
            Network.upgradeUnit(unit.Name)
            task.wait(CONFIG.UPGRADE_DELAY)
        end
    end
    GUI.updateStatus("Idle")
end

-- 🔄 รีเซ็ตสถานะเกมเพื่อเริ่มรอบใหม่
function GameLogic.resetGameState()
    GameState.hasSpawned = false
    GameState.missedSpawnTime = false
    GameState.processedWaves = {}
    GameState.lastUpgradeTime = 0
    GameState.currentWave = 0
    GUI.updateWave(0)
    GUI.updateStatus("Restarting...")
end

-- 🌊 จัดการเหตุการณ์ต่างๆ ในแต่ละ Wave
function GameLogic.handleWave(wave)
    if GameState.processedWaves[wave] then return end

    -- เลือกการ์ดใน Wave ที่กำหนด
    if table.find(CONFIG.CARD_WAVES, wave) then
        GUI.updateStatus("Choosing cards...")
        Network.chooseCards()
        GameState.processedWaves[wave] = true
        task.wait(0.5)
        GUI.updateStatus("Idle")
    end

    -- เมื่อถึง Wave สุดท้าย → โหวต Restart และเริ่มใหม่
    if wave == CONFIG.FINAL_WAVE then
        GameState.processedWaves[wave] = true
        GUI.updateStatus("Voting restart...")
        Network.voteRestart()
        task.wait(CONFIG.VOTE_WAIT)
        GameLogic.resetGameState()
        task.wait(2)
        runGameplayScript()  -- เริ่มใหม่ (จะ Disconnect เก่าก่อนอัตโนมัติ)
    end
end

-- 🧹 ตัดการเชื่อมต่อ Heartbeat เก่า (ถ้ามี)
function GameLogic.disconnectHeartbeat()
    if heartbeatConnection then
        heartbeatConnection:Disconnect()
        heartbeatConnection = nil
    end
end

-- =====================================================
-- 🛠️ AUTO SETTINGS : โหลด script เสริมจาก GitHub
-- =====================================================
local AutoSettings = {}

-- โหลดและรัน AutoSkipWaves script
function AutoSettings.enableAutoSkipWaves()
    task.spawn(function()
        local success, err = pcall(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/LilValkX/teafram/refs/heads/main/autoskipwave.lua", true))()
            print("✅ โหลด AutoSkipWaves สำเร็จ")
        end)
        if not success then 
            warn("⚠️ โหลด AutoSkipWaves ไม่สำเร็จ: "..tostring(err)) 
        end
    end)
end

-- โหลดและรัน Auto All Settings script
function AutoSettings.enableAllSettings()
    task.spawn(function()
        local success, err = pcall(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/LilValkX/teafram/refs/heads/main/auto-all-settings.lua", true))()
            print("✅ โหลด Auto All Settings สำเร็จ")
        end)
        if not success then
            warn("⚠️ โหลด Auto All Settings ไม่สำเร็จ: "..tostring(err))
        end
    end)
end

-- =====================================================
-- 🗺️ MAP LOGIC : สคริปต์แยกระหว่าง Lobby / Gameplay
-- =====================================================
-- 🏠 โหมด Lobby : กดเริ่ม Summer Event
function runLobbyScript()
    task.wait(7)
    local networking = ReplicatedStorage:WaitForChild("Networking", 5)
    if not networking then return end

    local summer = networking:WaitForChild("Summer", 5)
    if summer then
        local summerEvent = summer:WaitForChild("SummerLTMEvent", 5)
        if summerEvent then
            summerEvent:FireServer("Create")
        end
    end

    task.wait(2)
    local lobbyEvent = networking:WaitForChild("LobbyEvent", 5)
    if lobbyEvent then
        lobbyEvent:FireServer("StartMatch")
    end
end

-- ⚔️ โหมด Gameplay : จัดการระบบวาง / อัปเกรด / เช็ก Wave
function runGameplayScript()
    -- 🧹 ลบ Connection เก่าก่อนสร้างใหม่ (สำคัญมาก!)
    GameLogic.disconnectHeartbeat()
    
    -- 🖥️ สร้าง GUI เมื่อเข้า Map 2
    GUI.create()
    GUI.updateStatus("Initializing...")
    
    -- 🛠️ เปิดระบบ Auto Settings (ทำงานแบบ async)
    AutoSettings.enableAutoSkipWaves()
    AutoSettings.enableAllSettings()
    
    GameLogic.waitForSkipWave()

    local playerGui = player:WaitForChild("PlayerGui", CONFIG.WAITFORCHILD_TIMEOUT)
    local hud = Utils.safeWaitForChild(playerGui, "HUD")
    local mapFrame = Utils.safeWaitForChild(hud, "Map")
    local sessionTimer = Utils.safeWaitForChild(mapFrame, "SessionTimer")
    local timerLabel = Utils.safeWaitForChild(sessionTimer, "Label")
    local wavesAmountLabel = Utils.safeWaitForChild(mapFrame, "WavesAmount")

    GUI.updateStatus("Waiting for spawn time...")

    -- 🩺 Loop เช็กสถานะทุก HEARTBEAT_INTERVAL
    heartbeatConnection = RunService.Heartbeat:Connect(function()
        local now = tick()
        if now - GameState.lastHeartbeatCheck < CONFIG.HEARTBEAT_INTERVAL then return end
        GameState.lastHeartbeatCheck = now

        -- เวลาในเกม (ใช้จับจังหวะวางยูนิต)
        local timeText = timerLabel.Text
        local seconds = Utils.parseTime(timeText)

        -- วางยูนิตตามเวลาที่กำหนด
        if not GameState.hasSpawned and not GameState.missedSpawnTime then
            if seconds >= CONFIG.SPAWN_TIME and seconds < CONFIG.SPAWN_TIME + 1 then
                GameLogic.spawnAllUnits()
            elseif seconds > CONFIG.SPAWN_TIME + 1 then
                GameState.missedSpawnTime = true
                GUI.updateStatus("Missed spawn time")
            end
        end

        -- ตรวจ Wave ปัจจุบัน
        local waveText = wavesAmountLabel.Text
        local cleanText = Utils.stripHTMLTags(waveText)
        local currentWave = tonumber(cleanText)

        if currentWave and currentWave ~= GameState.currentWave then
            GameState.currentWave = currentWave
            GUI.updateWave(currentWave)
            GameLogic.handleWave(currentWave)
        end

        -- อัปเกรดยูนิตระหว่างเล่น
        if GameState.hasSpawned and GameState.currentAction == "Idle" then
            GameLogic.upgradeAllUnits()
        end
    end)
end

-- =====================================================
-- 🚀 ENTRY POINT : เริ่มสคริปต์ตาม Map ที่อยู่
-- =====================================================
if game.PlaceId == CONFIG.FIRST_MAP_ID then
    runLobbyScript()
elseif game.PlaceId == CONFIG.SECOND_MAP_ID then
    runGameplayScript()
end
