--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local InventoryTypes = require(ReplicatedStorage.Shared.Inventroy.InventoryTypes)
local ItemConfig = require(ReplicatedStorage.Shared.Inventroy.ItemConfig)
local BaseTrashBagState = require(ServerScriptService.Server.UsableItems.TrashBag.States.BaseTrashBagState)
local TrashBagTypes = require(ServerScriptService.Server.UsableItems.TrashBag.TrashBagTypes)

local TrashBagTiedState = {}
TrashBagTiedState.__index = TrashBagTiedState

setmetatable(TrashBagTiedState, BaseTrashBagState)

export type TrashBagTiedState = typeof(setmetatable({} :: TrashBagTypes.TrashBagState, TrashBagTiedState))

function TrashBagTiedState.new(trashBag: TrashBagTypes.TrashBag): TrashBagTypes.TrashBagState
	local self: any
	self = BaseTrashBagState.new(trashBag, {
		EInputStart = function()
			if self.context.trashInside >= self.context.capacity then
				return
			end
			self.context:switchState(self.context.allStates.untying)
		end,
		GInputStart = function()
			self.context:switchState(self.context.allStates.onGround)
		end,
	})
	return setmetatable(self, TrashBagTiedState)
end

function TrashBagTiedState.onEnter(self: TrashBagTiedState)
	print("===switched to TIED state===")
end

function TrashBagTiedState.getItemData(self: TrashBagTiedState): InventoryTypes.ItemData
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

return TrashBagTiedState
