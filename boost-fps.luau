local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

repeat task.wait() until game:IsLoaded()

local player = Players.LocalPlayer
if not player then
    local ok, p = pcall(function() return Players.PlayerAdded:Wait() end)
    if ok and p then
        player = p
    else
        repeat task.wait() until Players.LocalPlayer
        player = Players.LocalPlayer
    end
end

if player then
    if not player.Character then
        local ok, c = pcall(function() return player.CharacterAdded:Wait() end)
        if not (ok and c) then
            repeat task.wait() until player.Character
        end
    end
end

if setfpscap then pcall(setfpscap, 15) end

pcall(function()
    local ok, us = pcall(function() return UserSettings() end)
    if ok and us then
        local gs = us.GameSettings
        if gs then
            pcall(function() gs.MasterVolume = 0 end)
            pcall(function() gs.SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel1 end)
        end
    end
end)

if setfflag then
    pcall(function()
        pcall(setfflag, "RenderShadowIntensity", "0")
        pcall(setfflag, "RenderShadowmapBias", "0.05")
        pcall(setfflag, "DebugForceFutureIsBrightPhase2", "False")
        pcall(setfflag, "DFFlagDebugRenderForceTechnologyVoxel", "True")
        pcall(setfflag, "DFFlagRenderFixFog", "False")
        pcall(setfflag, "FFlagTerrainMeshPartHeightfields", "False")
        pcall(setfflag, "DFIntTerrainArraySliceSize", "4")
        pcall(setfflag, "RenderVoxelUpgradeEnabled", "False")
        pcall(setfflag, "DFFlagPostProcessDistortion", "False")
        pcall(setfflag, "DFIntMaxActiveParticleCount", "100")
        pcall(setfflag, "DFIntParticleSystemMaxCount", "50")
        pcall(setfflag, "GuiService3DEnabled", "False")
        pcall(setfflag, "DFFlagUserShowGuiHideToggles", "False")
        pcall(setfflag, "AbuseReportScreenshotPercentage", "0")
        pcall(setfflag, "DFIntCanHideGuiGroupId", "999999999")
        pcall(setfflag, "DFIntAnimationLodFacsDistanceMax", "25")
        pcall(setfflag, "DFIntAnimationLodFacsDistanceMin", "10")
        pcall(setfflag, "DFFlagDebugPause", "False")
        pcall(setfflag, "FFlagEnableInGameMenuControls", "False")
        pcall(setfflag, "TextChatServiceEnabled", "False")
    end)
end

pcall(function()
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, false)
end)

pcall(function()
    pcall(function() SoundService.Volume = 0 end)
    pcall(function() SoundService.RespectFilteringEnabled = false end)
end)

pcall(function()
    Lighting.Technology = Enum.Technology.Compatibility
    Lighting.ShadowSoftness = 0
    Lighting.EnvironmentDiffuseScale = 0
    Lighting.EnvironmentSpecularScale = 0
    Lighting.GlobalShadows = false
    Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
    for _, effect in ipairs(Lighting:GetChildren()) do
        if effect:IsA("PostEffect") then
            pcall(function() effect:Destroy() end)
        end
    end
end)

local all = {}
local ok, desc = pcall(function() return game:GetDescendants() end)
if ok and desc then all = desc end

for _, obj in pairs(all) do
    if obj:IsA("Sound") then
        pcall(function()
            obj.Volume = 0
            if rawget(obj, "Enabled") ~= nil then obj.Enabled = false end
        end)
    end

    if obj:IsA("ParticleEmitter") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
        pcall(function()
            if rawget(obj, "Enabled") ~= nil then obj.Enabled = false end
            if obj.Parent then pcall(function() obj:Destroy() end) end
        end)
    end

    if obj:IsA("BasePart") then
        pcall(function()
            obj.Material = Enum.Material.SmoothPlastic
            if rawget(obj, "TopSurface") ~= nil then obj.TopSurface = Enum.SurfaceType.Smooth end
            if rawget(obj, "BottomSurface") ~= nil then obj.BottomSurface = Enum.SurfaceType.Smooth end
        end)
    end

    if obj:IsA("Decal") or obj:IsA("Texture") then
        pcall(function()
            if obj:IsDescendantOf(Workspace:FindFirstChild("Terrain") or Workspace) then
                pcall(function() obj:Destroy() end)
            else
                obj.Transparency = 1
            end
        end)
    end
end

pcall(function()
    local t = Workspace:FindFirstChild("Terrain")
    if t then
        pcall(function() t.WaterWaveSize = 0 end)
        pcall(function() t.WaterWaveSpeed = 0 end)
        pcall(function() t.WaterReflectance = 0 end)
        pcall(function() t.WaterTransparency = 1 end)
    end
end)
