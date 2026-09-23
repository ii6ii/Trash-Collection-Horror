--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InputSystemTypes = require(ReplicatedStorage.Shared.Types.InputSystemTypes)
local InputConfig = require(ReplicatedStorage.Shared.Config.InputConfig)
local Networker = require(ReplicatedStorage.Packages.Networker).client

local InputSystem = {}

function InputSystem.init()
	local networker = Networker.new("InputSystem", InputSystem)

	local inputFolder = ReplicatedStorage:WaitForChild("Input")

	for _, name in InputConfig do
		local input = inputFolder:WaitForChild(name)

		input.Pressed:Connect(function()
			networker:fire("beginInput", InputSystem.createInputContext(name))
		end)

		input.Released:Connect(function()
			networker:fire("endInput", InputSystem.createInputContext(name))
		end)
	end
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
