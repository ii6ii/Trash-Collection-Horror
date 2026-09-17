--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local InputSystemTypes = require(ReplicatedStorage.Shared.InputSystem.InputSystemTypes)
local InventoryTypes = require(ReplicatedStorage.Shared.Inventroy.InventoryTypes)
local ItemConfig = require(ReplicatedStorage.Shared.Inventroy.ItemConfig)
local BaseTrashBagState = require(ServerScriptService.Server.UsableItems.TrashBag.States.BaseTrashBagState)
local TrashBagTypes = require(ServerScriptService.Server.UsableItems.TrashBag.TrashBagTypes)

local TrashBagWithTrashState = {}
TrashBagWithTrashState.__index = TrashBagWithTrashState

setmetatable(TrashBagWithTrashState, BaseTrashBagState)

export type TrashBagWithTrashState = typeof(setmetatable({} :: TrashBagTypes.TrashBagState, TrashBagWithTrashState))

function TrashBagWithTrashState.new(trashBag: TrashBagTypes.TrashBag): TrashBagTypes.TrashBagState
	local self: any
	self = BaseTrashBagState.new(trashBag, {
		FInputStart = function(bag: TrashBagTypes.TrashBag, conetx: InputSystemTypes.InputContext)
			self:collectTrash(conetx)
		end,
		EInputStart = function()
			self.context:switchState(self.context.allStates.tying)
		end,
		GInputStart = function()
			self.context:switchState(self.context.allStates.onGround)
		end,
	})
	return setmetatable(self, TrashBagWithTrashState)
end

function TrashBagWithTrashState.collectTrash(self: TrashBagWithTrashState, conetx: InputSystemTypes.InputContext)
	local result = self.context:tryCollectTrash(conetx)
	if result then
		print(`---Trash Collected ({self.context.trashInside})---`)
	end
	if self.context.trashInside == self.context.capacity then
		self.context:switchState(self.context.allStates.tying)
	end
end

function TrashBagWithTrashState.onEnter(self: TrashBagWithTrashState)
	print("===switched to WITH TRASH state===")
end

function TrashBagWithTrashState.getItemData(self: TrashBagWithTrashState): InventoryTypes.ItemData
	local config = ItemConfig.trashBag
	return {
		attachment = self.context.attachment,
		instance = self.context.instance,
		type = config.type,
		weight = self.context:getWeight(),
		size = config.size,
		canTakeInHands = true,
		canPutInBackpack = false,
	}
end

return TrashBagWithTrashState
