--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local InputSystemTypes = require(ReplicatedStorage.Shared.InputSystem.InputSystemTypes)
local Networker = require(ReplicatedStorage.Packages.Networker).client

local InputSystem = {}

function InputSystem.init()
	local networker = Networker.new("InputSystem", InputSystem)

	ReplicatedStorage.Input.EInput.Pressed:Connect(function()
		networker:fire("beginInput", InputSystem.createInputContext("EInput"))
	end)

	ReplicatedStorage.Input.EInput.Released:Connect(function()
		networker:fire("endInput", InputSystem.createInputContext("EInput"))
	end)

	ReplicatedStorage.Input.GInput.Pressed:Connect(function()
		networker:fire("beginInput", InputSystem.createInputContext("GInput"))
	end)

	ReplicatedStorage.Input.GInput.Released:Connect(function()
		networker:fire("endInput", InputSystem.createInputContext("GInput"))
	end)

	ReplicatedStorage.Input.FInput.Pressed:Connect(function()
		networker:fire("beginInput", InputSystem.createInputContext("FInput"))
	end)

	ReplicatedStorage.Input.FInput.Released:Connect(function()
		networker:fire("endInput", InputSystem.createInputContext("FInput"))
	end)

	ReplicatedStorage.Input.SprintInput.Pressed:Connect(function()
		networker:fire("beginInput", InputSystem.createInputContext("SprintInput"))
	end)

	ReplicatedStorage.Input.SprintInput.Released:Connect(function()
		networker:fire("endInput", InputSystem.createInputContext("SprintInput"))
	end)
end

function InputSystem.getLookDirection(): Vector3
	local camera = workspace.CurrentCamera
	if not camera then
		return Vector3.zero
	end

	return camera.CFrame.LookVector
end

function InputSystem.getCameraCFrame(): CFrame
	local camera = workspace.CurrentCamera
	if not camera then
		return CFrame.new()
	end
	return camera.CFrame
end

function InputSystem.createInputContext(name: string): InputSystemTypes.InputContext
	return {
		lookDirection = InputSystem.getLookDirection(),
		cameraCFrame = InputSystem.getCameraCFrame(),
		name = name,
	}
end

return InputSystem
