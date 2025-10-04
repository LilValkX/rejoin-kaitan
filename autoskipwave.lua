local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- รอจน LocalPlayer พร้อมและมี PlayerGui
local LocalPlayer
repeat
    task.wait()
    LocalPlayer = Players.LocalPlayer
until LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")

-- ฟังก์ชันเปิด AutoSkipWaves
local function toggleAutoSkip()
    local success, err = pcall(function()
        local gui = LocalPlayer.PlayerGui
        local pathList = {"Windows","Settings","Holder","Main","ScrollingFrame","Gameplay","AutoSkipWaves","Slider"}
        for _, name in ipairs(pathList) do
            gui = gui:WaitForChild(name)
        end
        local ball = gui:WaitForChild("Ball")
        
        -- รอให้ Ball ตำแหน่งนิ่ง
        task.wait(0.3)

        local OFF_X = 0.211999997
        local TOLERANCE = 0.05
        if math.abs(ball.Position.X.Scale - OFF_X) < TOLERANCE then
            ReplicatedStorage:WaitForChild("Networking")
                :WaitForChild("Settings")
                :WaitForChild("SettingsEvent")
                :FireServer("Toggle", "AutoSkipWaves")
        end
    end)
    if not success then warn("เปิด AutoSkipWaves ไม่สำเร็จ: "..tostring(err)) end
end

toggleAutoSkip()
