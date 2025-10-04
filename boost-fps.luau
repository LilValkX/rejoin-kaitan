-- 🧭 ตั้งค่า FPS Limit เพื่อประหยัดทรัพยากร
setfpscap(7)

-- 📦 ดึง Service สำคัญจากเกม
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

-- 🎮 รอจนกว่าเกมโหลดเสร็จและมี LocalPlayer
repeat task.wait() until game:IsLoaded() and Players.LocalPlayer
local player = Players.LocalPlayer

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
    currentWave = 0                  -- Wave ปัจจุบัน
}

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
    local playerGui = player:WaitForChild("PlayerGui", CONFIG.WAITFORCHILD_TIMEOUT)
    if not playerGui then return end
    local start = tick()
    while tick() - start < CONFIG.SKIP_WAVE_TIMEOUT do
        local skipWave = playerGui:FindFirstChild("SkipWave")
        if skipWave and skipWave:FindFirstChild("Holder") then
            local yesBtn = skipWave.Holder:FindFirstChild("Yes")
            if yesBtn and yesBtn.Visible then
                Network.skipWave()
                return true
            end
        end
        task.wait(0.3)
    end
end

-- ⚔️ วางยูนิตทั้งหมดตามรายชื่อใน CONFIG
function GameLogic.spawnAllUnits()
    for _, name in ipairs(CONFIG.UNIT_NAMES) do
        Network.spawnUnit(name)
        task.wait(CONFIG.SPAWN_DELAY)
    end
    GameState.hasSpawned = true
end

-- 💎 อัปเกรดยูนิตทั้งหมดในแผนที่
function GameLogic.upgradeAllUnits()
    if tick() - GameState.lastUpgradeTime < CONFIG.UPGRADE_COOLDOWN then return end
    GameState.lastUpgradeTime = tick()
    local unitFolder = Workspace:FindFirstChild("Units")
    if not unitFolder then return end
    for _, unit in ipairs(unitFolder:GetChildren()) do
        if unit:IsA("Model") then
            Network.upgradeUnit(unit.Name)
            task.wait(CONFIG.UPGRADE_DELAY)
        end
    end
end

-- 🔄 รีเซ็ตสถานะเกมเพื่อเริ่มรอบใหม่
function GameLogic.resetGameState()
    GameState.hasSpawned = false
    GameState.missedSpawnTime = false
    GameState.processedWaves = {}
    GameState.lastUpgradeTime = 0
    GameState.currentWave = 0
end

-- 🌊 จัดการเหตุการณ์ต่างๆ ในแต่ละ Wave
function GameLogic.handleWave(wave)
    if GameState.processedWaves[wave] then return end

    -- เลือกการ์ดใน Wave ที่กำหนด
    if table.find(CONFIG.CARD_WAVES, wave) then
        Network.chooseCards()
        GameState.processedWaves[wave] = true
    end

    -- เมื่อถึง Wave สุดท้าย → โหวต Restart และเริ่มใหม่
    if wave == CONFIG.FINAL_WAVE then
        GameState.processedWaves[wave] = true
        Network.voteRestart()
        task.wait(CONFIG.VOTE_WAIT)
        GameLogic.resetGameState()
        task.wait(2)
        runGameplayScript()
    end
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
    GameLogic.waitForSkipWave()

    local playerGui = player:WaitForChild("PlayerGui", CONFIG.WAITFORCHILD_TIMEOUT)
    local hud = Utils.safeWaitForChild(playerGui, "HUD")
    local mapFrame = Utils.safeWaitForChild(hud, "Map")
    local sessionTimer = Utils.safeWaitForChild(mapFrame, "SessionTimer")
    local timerLabel = Utils.safeWaitForChild(sessionTimer, "Label")
    local wavesAmountLabel = Utils.safeWaitForChild(mapFrame, "WavesAmount")

    -- 🩺 Loop เช็กสถานะทุก HEARTBEAT_INTERVAL
    RunService.Heartbeat:Connect(function()
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
            end
        end

        -- ตรวจ Wave ปัจจุบัน
        local waveText = wavesAmountLabel.Text
        local cleanText = Utils.stripHTMLTags(waveText)
        local currentWave = tonumber(cleanText)

        if currentWave and currentWave ~= GameState.currentWave then
            GameState.currentWave = currentWave
            GameLogic.handleWave(currentWave)
        end

        -- อัปเกรดยูนิตระหว่างเล่น
        if GameState.hasSpawned then
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
