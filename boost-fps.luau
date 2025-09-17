repeat task.wait() until game:IsLoaded()

if setfpscap then pcall(setfpscap, 15) end

local function optimizeGraphics()
    local UserSettings = UserSettings()
    local GameSettings = UserSettings.GameSettings
    if GameSettings then
        pcall(function()
            GameSettings.MasterVolume = 0
            GameSettings.SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel1
        end)
    end
end

local function setLowQualityFlags()
    if setfflag then
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
    end
end

local function removeUnnecessaryGUI()
    pcall(function()
        game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
        game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
        game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
        game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)
        game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, false)
    end)
end

local function disableAudio()
    pcall(function()
        game:GetService("SoundService").Volume = 0
        game:GetService("SoundService").RespectFilteringEnabled = false
        for _, sound in pairs(game:GetDescendants()) do
            if sound:IsA("Sound") then
                sound.Volume = 0
                sound.Enabled = false
            end
        end
    end)
end

local function optimizeLighting()
    pcall(function()
        local Lighting = game:GetService("Lighting")
        Lighting.Technology = Enum.Technology.Compatibility
        Lighting.ShadowSoftness = 0
        Lighting.EnvironmentDiffuseScale = 0
        Lighting.EnvironmentSpecularScale = 0
        Lighting.GlobalShadows = false
        Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
        for _, effect in pairs(Lighting:GetChildren()) do
            if effect:IsA("PostEffect") then
                effect:Destroy()
            end
        end
    end)
end

local function removeParticleEffects()
    pcall(function()
        for _, obj in pairs(game:GetDescendants()) do
            if obj:IsA("ParticleEmitter") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
                obj.Enabled = false
                obj:Destroy()
            end
        end
    end)
end

local function reduceMaterials()
    pcall(function()
        for _, obj in pairs(game:GetDescendants()) do
            if obj:IsA("BasePart") then
                obj.Material = Enum.Material.SmoothPlastic
                obj.TopSurface = Enum.SurfaceType.Smooth
                obj.BottomSurface = Enum.SurfaceType.Smooth
            end
            if obj:IsA("Decal") or obj:IsA("Texture") then
                obj.Transparency = 1
            end
        end
    end)
end

optimizeGraphics()
setLowQualityFlags()
removeUnnecessaryGUI()
disableAudio()
optimizeLighting()
removeParticleEffects()
reduceMaterials()
