--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local InventoryTypes = require(ReplicatedStorage.Shared.Inventroy.InventoryTypes)
local Inventory = require(ServerScriptService.Server.Inventory.Inventory)
local InventoryItemRegistry = require(ServerScriptService.Server.Inventory.InventoryItemRegistry)
local SoundService = require(ServerScriptService.Server.Sound.SoundService)
local PartUtils = require(ReplicatedStorage.Shared.PartUtils)
local SoundConfig = require(ReplicatedStorage.Shared.Sound.SoundConfig)
local BaseTrashBagState = require(ServerScriptService.Server.UsableItems.TrashBag.States.BaseTrashBagState)
local TrashBagTypes = require(ServerScriptService.Server.UsableItems.TrashBag.TrashBagTypes)

local TrashBagOnGroundState = {}
TrashBagOnGroundState.__index = TrashBagOnGroundState

setmetatable(TrashBagOnGroundState, BaseTrashBagState)

export type TrashBagOnGroundState = typeof(setmetatable({} :: TrashBagTypes.TrashBagState, TrashBagOnGroundState))

function TrashBagOnGroundState.new(trashBag: TrashBagTypes.TrashBag): TrashBagTypes.TrashBagState
	local self = BaseTrashBagState.new(trashBag, {}) :: any
	return setmetatable(self, TrashBagOnGroundState)
end

function TrashBagOnGroundState.onEnter(self: TrashBagOnGroundState)
	print("===switched to GROUND state===")
	local item = InventoryItemRegistry.get(self.context.instance) :: InventoryTypes.Item
	if not self.context.owner then
		return
	end
	SoundService.Play(self.context.owner, SoundConfig.trashDrop)
	Inventory.getPlayerInventory(self.context.owner):removeItem(item)
	PartUtils.placeOnGround(self.context.instance.Model, 1)
end

function TrashBagOnGroundState.onEquipped(self: TrashBagOnGroundState): ()
	self.context:switchState(self.context.lastState)
end

function TrashBagOnGroundState.getItemData(self: TrashBagOnGroundState)
	return self.context.lastState:getItemData()
end

return TrashBagOnGroundState
