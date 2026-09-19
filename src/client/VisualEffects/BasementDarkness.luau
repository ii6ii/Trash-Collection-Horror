--!strict

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Zone = require(ReplicatedStorage.Packages.ZonePlus)

local BasementDarkness = {}

local TWEEN_INFO = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

local DARKNESS_DENSITY = 1
local DARKNESS_COLOR = Color3.new(0, 0, 0)

local initialized = false

local atmosphere: Atmosphere
local basementZone: any

local originalDensity: number
local originalColor: Color3

local currentTween: Tween?

local function tweenAtmosphere(density: number, color: Color3): ()
	if currentTween then
		currentTween:Cancel()
		currentTween = nil
	end

	currentTween = TweenService:Create(atmosphere, TWEEN_INFO, {
		Density = density,
		Color = color,
	})

	currentTween:Play()
end

local function onEntered(): ()
	tweenAtmosphere(DARKNESS_DENSITY, DARKNESS_COLOR)
end

local function onExited(): ()
	tweenAtmosphere(originalDensity, originalColor)
end

function BasementDarkness.init(): ()
	if initialized then
		return
	end

	initialized = true

	atmosphere = Lighting:WaitForChild("Atmosphere") :: Atmosphere

	local basementZoneFolder = workspace:WaitForChild("BasementZone")

	basementZone = Zone.new(basementZoneFolder)

	-- Запоминаем исходное состояние Atmosphere.
	originalDensity = atmosphere.Density
	originalColor = atmosphere.Color

	basementZone.localPlayerEntered:Connect(onEntered)

	basementZone.localPlayerExited:Connect(onExited)
end

return BasementDarkness
