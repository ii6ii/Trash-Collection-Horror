--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Networker = require(ReplicatedStorage.Packages.Networker)
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

function MovementController:disableMovement(player: Player): ()
	local movement = MovementController.getMovement(player)

	movement:disableMovement()
end

function MovementController:enableMovement(player: Player): ()
	local movement = MovementController.getMovement(player)

	movement:enableMovement()
end

function MovementController.destroyPlayer(player: Player): ()
	movements[player] = nil
end

Networker.server.new(
	"Movment",
	MovementController,
	{ MovementController.enableMovement, MovementController.disableMovement }
)

return MovementController
