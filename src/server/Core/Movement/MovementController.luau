--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Networker = require(ReplicatedStorage.Packages.Networker)
local GoodSignal = require(ReplicatedStorage.Packages.GoodSignal)
local Movement = require(script.Parent.Movement)
local InputSystem = require(ServerScriptService.Server.Core.InputSystem.InputSystem)

local movements: { [Player]: Movement.Movement } = {}
local connections: { [Player]: { GoodSignal.Connection } } = {}

local MovementController = {}

function MovementController.init(): ()
	local networker = Networker.server.new("Movment")
	-- :: any на каждом элементе: setBinOpen отличается арностью от
	-- enableMovement/disableMovement, Luau не сводит их к одной сигнатуре
	-- при выводе типа литерала массива (см. BinService.luau).
	networker:addClientAccess(MovementController, {
		MovementController.enableMovement :: any,
		MovementController.disableMovement :: any,
		MovementController.setBinOpen :: any,
	})
end

function MovementController.initPlayer(player: Player): ()
	local movement = Movement.new(player)
	movements[player] = movement

	local sprintInput = InputSystem.getInput(player, "SprintInput")

	connections[player] = {
		sprintInput.Started:Connect(function()
			movement:startSprint()
		end),

		sprintInput.Ended:Connect(function()
			movement:stopSprint()
		end),
	}
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

function MovementController:setBinOpen(player: Player, isOpen: boolean): ()
	local movement = MovementController.getMovement(player)
	movement:setBinOpen(isOpen)
end

function MovementController.destroyPlayer(player: Player): ()
	local playerConnections = connections[player]

	if playerConnections then
		for _, connection in playerConnections do
			connection:Disconnect()
		end
	end

	connections[player] = nil
	movements[player] = nil
end

return MovementController
