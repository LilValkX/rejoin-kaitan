local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- รอ Slider และ Ball โหลดครบ
local slider = LocalPlayer.PlayerGui:WaitForChild("Windows")
    :WaitForChild("Settings")
    :WaitForChild("Holder")
    :WaitForChild("Main")
    :WaitForChild("ScrollingFrame")
    :WaitForChild("Gameplay")
    :WaitForChild("AutoSkipWaves")
    :WaitForChild("Slider")

local ball = slider:WaitForChild("Ball")

-- รอให้ Ball อัปเดตตำแหน่งนิ่ง
task.wait(0.2)

-- ค่า OFF ของ X.Scale
local OFF_X = 0.211999997
local TOLERANCE = 0.05 -- tolerance กว้างขึ้น

-- ถ้าอยู่ตำแหน่ง OFF ให้ FireServer
if math.abs(ball.Position.X.Scale - OFF_X) < TOLERANCE then
    local args = { "Toggle", "AutoSkipWaves" }
    ReplicatedStorage:WaitForChild("Networking")
        :WaitForChild("Settings")
        :WaitForChild("SettingsEvent")
        :FireServer(unpack(args))
end
