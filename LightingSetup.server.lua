-- Sky Coin Rush | LightingSetup
-- Golden-hour cinematic lighting rig.

local Lighting = game:GetService("Lighting")

pcall(function()
	Lighting.Technology = Enum.Technology.Future
end)

Lighting.ClockTime = 15.5
Lighting.GeographicLatitude = 30
Lighting.Brightness = 2.2
Lighting.Ambient = Color3.fromRGB(90, 100, 120)
Lighting.OutdoorAmbient = Color3.fromRGB(120, 110, 100)
Lighting.GlobalShadows = true
Lighting.ShadowSoftness = 0.3
Lighting.EnvironmentDiffuseScale = 0.6
Lighting.EnvironmentSpecularScale = 0.6
Lighting.ExposureCompensation = 0.1

local sky = Instance.new("Sky")
sky.Name = "SkyCoinSky"
sky.SunAngularSize = 18
sky.MoonAngularSize = 12
sky.StarCount = 1500
sky.Parent = Lighting

local rays = Instance.new("SunRaysEffect")
rays.Intensity = 0.12
rays.Spread = 1.2
rays.Parent = Lighting

local bloom = Instance.new("BloomEffect")
bloom.Intensity = 0.6
bloom.Size = 32
bloom.Threshold = 1.2
bloom.Parent = Lighting

local cc = Instance.new("ColorCorrectionEffect")
cc.Brightness = 0.02
cc.Contrast = 0.12
cc.Saturation = 0.18
cc.TintColor = Color3.fromRGB(255, 244, 229)
cc.Parent = Lighting

local dof = Instance.new("DepthOfFieldEffect")
dof.Enabled = true
dof.FarIntensity = 0.15
dof.FocusDistance = 60
dof.InFocusRadius = 180
dof.NearIntensity = 0.1
dof.Parent = Lighting

local atmo = Instance.new("Atmosphere")
atmo.Density = 0.3
atmo.Offset = 0.4
atmo.Color = Color3.fromRGB(199, 199, 199)
atmo.Decay = Color3.fromRGB(106, 112, 125)
atmo.Glare = 0.2
atmo.Haze = 1.2
atmo.Parent = Lighting

print("[SkyCoinRush] Lighting rig applied.")
