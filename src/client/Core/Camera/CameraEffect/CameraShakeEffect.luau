--!strict

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CameraConfig = require(ReplicatedStorage.Shared.Config.CameraConfig)

local CameraShakeEffect = {}

local connection: RBXScriptConnection?
local time = 0

local TIME_SPEED = CameraConfig.ShakeTimeSpeed

local POSITION_AMPLITUDE_X = CameraConfig.ShakePositionAmplitudeX
local POSITION_AMPLITUDE_Y = CameraConfig.ShakePositionAmplitudeY
local POSITION_OFFSET_X = CameraConfig.ShakePositionOffsetX

local ROTATION_AMPLITUDE = CameraConfig.ShakeRotationAmplitude

function CameraShakeEffect.Start(): ()
	if connection then
		return
	end

	time = 0

	connection = RunService.RenderStepped:Connect(function(deltaTime: number)
		local camera = workspace.CurrentCamera

		if not camera then
			return
		end

		time += deltaTime * TIME_SPEED

		local x = math.sin(time) * POSITION_AMPLITUDE_X + POSITION_OFFSET_X
		local y = math.sin(time * 2) * POSITION_AMPLITUDE_Y

		local pitch = math.sin(time * 2) * ROTATION_AMPLITUDE
		local roll = math.sin(time) * ROTATION_AMPLITUDE

		camera.CFrame *= CFrame.new(x, y, 0) * CFrame.Angles(pitch, 0, roll)
	end)
end

function CameraShakeEffect.Stop(): ()
	if not connection then
		return
	end

	connection:Disconnect()
	connection = nil
end

return CameraShakeEffect
