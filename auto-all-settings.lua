-- 🔹 รอเกมและ PlayerGui พร้อม
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- รอจน PlayerGui พร้อม
repeat task.wait() until LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("Windows")

-- 🔹 ค่า OFF ของ X.Scale
local OFF_X = 0.211999997

-- 🔹 ฟังก์ชันเปิด toggle ถ้า OFF
local function toggleIfOff(pathList, name, tolerance, retry, waitTime)
    local gui = LocalPlayer.PlayerGui
    for _, child in ipairs(pathList) do
        gui = gui:WaitForChild(child)
    end
    local ball = gui
    tolerance = tolerance or 0.01
    retry = retry or 0
    waitTime = waitTime or 0
    for i = 0, retry do
        if waitTime > 0 then task.wait(waitTime) end
        local currentX = ball.Position.X.Scale
        if math.abs(currentX - OFF_X) < tolerance then
            local args = { "Toggle", name }
            local success, err = pcall(function()
                ReplicatedStorage:WaitForChild("Networking")
                    :WaitForChild("Settings")
                    :WaitForChild("SettingsEvent")
                    :FireServer(unpack(args))
            end)
            if not success then
                warn("เปิด setting "..name.." ไม่สำเร็จ: "..tostring(err))
            end
        else
            break
        end
    end
end

-- 🔹 รายการ settings (ยกเว้น AutoSkipWaves)
local settingsList = {
    -- Units
    {name="HideOthersUnits", path={"Windows","Settings","Holder","Main","ScrollingFrame","Units","HideOthersUnits","Slider","Ball"}},
    {name="DisableVisualEffects", path={"Windows","Settings","Holder","Main","ScrollingFrame","Units","DisableVisualEffects","Slider","Ball"}},
    {name="DisableStatMultiplierPopups", path={"Windows","Settings","Holder","Main","ScrollingFrame","Units","DisableStatMultiplierPopups","Slider","Ball"}},
    {name="DisableDamageIndicators", path={"Windows","Settings","Holder","Main","ScrollingFrame","Units","DisableDamageIndicators","Slider","Ball"}},
    -- Enemies
    {name="DisableEnemyTags", path={"Windows","Settings","Holder","Main","ScrollingFrame","Enemies","DisableEnemyTags","Slider","Ball"}},
    {name="SimplifiedEnemyGui", path={"Windows","Settings","Holder","Main","ScrollingFrame","Enemies","SimplifiedEnemyGui","Slider","Ball"}},
    -- Graphics
    {name="DisableCameraShake", path={"Windows","Settings","Holder","Main","ScrollingFrame","Graphics","DisableCameraShake","Slider","Ball"}},
    {name="DisableDepthOfField", path={"Windows","Settings","Holder","Main","ScrollingFrame","Graphics","DisableDepthOfField","Slider","Ball"}},
    {name="LowDetailMode", path={"Windows","Settings","Holder","Main","ScrollingFrame","Graphics","LowDetailMode","Slider","Ball"}},
    {name="DisableViewCutscenes", path={"Windows","Settings","Holder","Main","ScrollingFrame","Graphics","DisableViewCutscenes","Slider","Ball"}}
}

-- 🔹 ตรวจและเปิดทุก setting
for _, setting in ipairs(settingsList) do
    toggleIfOff(setting.path, setting.name, setting.tolerance, setting.retry, setting.waitTime)
end
