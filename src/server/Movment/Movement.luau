--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local CameraController = require(ServerScriptService.Server.Camera.CameraController)
local InventoryTypes = require(ReplicatedStorage.Shared.Inventroy.InventoryTypes)

local BASE_WALK_SPEED = 16
local SPEED_LOSS_PER_WEIGHT = 0.05
local SPRINT_MULTIPLIER = 1.5
local MAX_SPRINT_WEIGHT = 2
local CAMERA_SHAKE_WEIGHT = 12

local DISABLED_WALK_SPEED = 0

local Movement = {}
Movement.__index = Movement

export type Movement = typeof(setmetatable(
	{} :: {
		player: Player,
		baseSpeed: number,
		totalWeight: number,
		isSprinting: boolean,
		isMovementEnabled: boolean,
	},
	Movement
))

function Movement.new(player: Player): Movement
	return setmetatable({
		player = player,
		baseSpeed = BASE_WALK_SPEED,
		totalWeight = 0,
		isSprinting = false,
		isMovementEnabled = true,
	}, Movement)
end

function Movement.updateWeight(self: Movement, items: { InventoryTypes.Item }): ()
	local totalWeight = 0

	for _, item in items do
		totalWeight += item:getItemData().weight
	end

	self.totalWeight = totalWeight
	self.baseSpeed = BASE_WALK_SPEED * math.max(1 - totalWeight * SPEED_LOSS_PER_WEIGHT, 0)

	if totalWeight > MAX_SPRINT_WEIGHT then
		self.isSprinting = false
	end

	if totalWeight >= CAMERA_SHAKE_WEIGHT then
		print("TRUE STATE")
		CameraController.startShake(self.player)
	else
		CameraController.stopShake(self.player)
	end

	self:updateSpeed()
end

function Movement.updateSpeed(self: Movement): ()
	local character = self.player.Character
	if not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	if not self.isMovementEnabled then
		humanoid.WalkSpeed = DISABLED_WALK_SPEED
		return
	end

	humanoid.WalkSpeed = self.isSprinting and self.baseSpeed * SPRINT_MULTIPLIER or self.baseSpeed
end

function Movement.disableMovement(self: Movement): ()
	if not self.isMovementEnabled then
		return
	end

	self.isMovementEnabled = false
	self.isSprinting = false

	self:updateSpeed()
end

function Movement.enableMovement(self: Movement): ()
	if self.isMovementEnabled then
		return
	end

	self.isMovementEnabled = true

	self:updateSpeed()
end

function Movement.startSprint(self: Movement): ()
	if not self.isMovementEnabled then
		return
	end

	if self.totalWeight > MAX_SPRINT_WEIGHT then
		return
	end

	if self.isSprinting then
		return
	end

	self.isSprinting = true
	self:updateSpeed()
end

function Movement.stopSprint(self: Movement): ()
	if not self.isSprinting then
		return
	end

	self.isSprinting = false
	self:updateSpeed()
end

return Movement
