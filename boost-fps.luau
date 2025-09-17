local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

repeat task.wait() until game:IsLoaded()

local player = Players.LocalPlayer
if not player then
    player = Players.PlayerAdded:Wait()
end

local function waitForCharacter()
    if player.Character then return end
    local connection
    local timeout = 30
    local startTime = tick()
    connection = player.CharacterAdded:Connect(function()
        if connection then connection:Disconnect() end
    end)
    repeat task.wait(0.1) until player.Character or (tick() - startTime) > timeout
    if connection then connection:Disconnect() end
end

waitForCharacter()

if setfpscap then pcall(setfpscap, 15) end

if setfflag then
    local performanceFlags = {
        "RenderShadowIntensity", "0",
        "RenderVoxelUpgradeEnabled", "False",
        "DFIntMaxActiveParticleCount", "25",
        "DFIntParticleSystemMaxCount", "10",
        "GuiService3DEnabled", "False",
        "DFIntTaskSchedulerTargetFps", "15"
    }
    for i = 1, #performanceFlags, 2 do
        pcall(setfflag, performanceFlags[i], performanceFlags[i + 1])
    end
end

pcall(function()
    local userSettings = UserSettings()
    if userSettings then
        local gs = userSettings.GameSettings
        if gs then
            gs.MasterVolume = 0
            gs.SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel1
            gs.GraphicsMode = Enum.GraphicsMode.Manual
            gs.QualityLevel = 1
        end
    end
end)

pcall(function()
    local coreGuiTypes = {
        Enum.CoreGuiType.PlayerList,
        Enum.CoreGuiType.Health,
        Enum.CoreGuiType.Backpack,
        Enum.CoreGuiType.Chat,
        Enum.CoreGuiType.EmotesMenu,
    }
    for _, guiType in pairs(coreGuiTypes) do
        StarterGui:SetCoreGuiEnabled(guiType, false)
    end
end)

pcall(function()
    SoundService.Volume = 0
    SoundService.AmbientReverb = Enum.ReverbType.NoReverb
    if SoundService:FindFirstChild("RespectFilteringEnabled") then
        SoundService.RespectFilteringEnabled = false
    end
end)

pcall(function()
    Lighting.Technology = Enum.Technology.Compatibility
    Lighting.ShadowSoftness = 0
    Lighting.EnvironmentDiffuseScale = 0
    Lighting.EnvironmentSpecularScale = 0
    Lighting.GlobalShadows = false
    Lighting.FogStart = 0
    Lighting.FogEnd = 100000
    Lighting.OutdoorAmbient = Color3.new(0.5, 0.5, 0.5)
    for _, effect in pairs(Lighting:GetChildren()) do
        if effect:IsA("PostEffect") then
            pcall(function() effect:Destroy() end)
        end
    end
end)

local function optimizeObject(obj)
    if not obj or not obj.Parent then return end
    pcall(function()
        if obj:IsA("Sound") then
            obj.Volume = 0
            obj:Stop()
            obj.PlayOnRemove = false
        elseif obj:IsA("ParticleEmitter") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
            obj.Enabled = false
        elseif obj:IsA("MeshPart") then
            obj.TextureID = ""
            obj.Material = Enum.Material.SmoothPlastic
            obj.CastShadow = false
        elseif obj:IsA("SpecialMesh") or obj:IsA("FileMesh") or obj:IsA("BlockMesh") then
            obj.TextureId = ""
        elseif obj:IsA("Decal") or obj:IsA("Texture") then
            obj.Texture = ""
            obj.Transparency = 1
        elseif obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
            obj.Image = ""
        elseif obj:IsA("Accessory") or obj:IsA("Hat") then
            local handle = obj:FindFirstChild("Handle")
            if handle then
                handle.Transparency = 1
                handle.CanCollide = false
            end
        elseif obj:IsA("BasePart") then
            obj.Material = Enum.Material.SmoothPlastic
            obj.TopSurface = Enum.SurfaceType.Smooth
            obj.BottomSurface = Enum.SurfaceType.Smooth
            obj.CastShadow = false
            obj.Reflectance = 0
        end
    end)
end

local function batchOptimize()
    local processed = 0
    local maxPerBatch = 100
    for _, obj in pairs(Workspace:GetDescendants()) do
        if processed >= maxPerBatch then
            task.wait()
            processed = 0
        end
        optimizeObject(obj)
        processed = processed + 1
    end
end

pcall(batchOptimize)

task.delay(15, function()
    pcall(batchOptimize)
end)

pcall(function()
    local terrain = Workspace:FindFirstChild("Terrain")
    if terrain then
        terrain.WaterWaveSize = 0
        terrain.WaterWaveSpeed = 0
        terrain.WaterReflectance = 0
        terrain.WaterTransparency = 1
        terrain.Decoration = false
        if sethiddenproperty then
            pcall(function()
                sethiddenproperty(terrain, "MaxExtents", Vector3.new(512, 512, 512))
            end)
        end
    end
end)

pcall(function()
    if not player then return end
    local playerGui = player:FindFirstChild("PlayerGui")
    if playerGui then
        for _, gui in pairs(playerGui:GetDescendants()) do
            optimizeObject(gui)
        end
        playerGui.DescendantAdded:Connect(optimizeObject)
    end
    if player.Character then
        for _, part in pairs(player.Character:GetDescendants()) do
            optimizeObject(part)
        end
    end
    player.CharacterAdded:Connect(function(char)
        task.wait(1)
        for _, part in pairs(char:GetDescendants()) do
            optimizeObject(part)
        end
    end)
end)

local counter = 0
local connection
pcall(function()
    connection = Workspace.DescendantAdded:Connect(function(obj)
        optimizeObject(obj)
        counter += 1
        if counter >= 100 then
            counter = 0
            collectgarbage("collect")
        end
    end)
end)

game:BindToClose(function()
    if connection then
        connection:Disconnect()
    end
    pcall(function() collectgarbage("collect") end)
end)
