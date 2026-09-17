--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local Movement = require(script.Parent.Movement)
local InputSystem = require(ServerScriptService.Server.InputSystem.InputSystem)

local movements: { [Player]: Movement.Movement } = {}

local MovementController = {}

function MovementController.initPlayer(player: Player): ()
	local movement = Movement.new(player)
	movements[player] = movement

	local sprintInput = InputSystem.getInput(player, "SprintInput")

	sprintInput.Started:Connect(function()
		movement:startSprint()
	end)

	sprintInput.Ended:Connect(function()
		movement:stopSprint()
	end)
end

function MovementController.getMovement(player: Player): Movement.Movement
	if not movements[player] then
		MovementController.initPlayer(player)
	end

	return movements[player]
end

function MovementController.destroyPlayer(player: Player): ()
	movements[player] = nil
end

return MovementController
