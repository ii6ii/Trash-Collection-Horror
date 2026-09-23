--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local InventoryTypes = require(ReplicatedStorage.Shared.Types.InventoryTypes)
local BaseTrashBagState = require(ServerScriptService.Server.Features.Items.TrashBag.States.BaseTrashBagState)
local TrashBagTypes = require(ServerScriptService.Server.Features.Items.TrashBag.TrashBagTypes)

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

function TrashBagTiedState.getItemData(self: TrashBagTiedState): InventoryTypes.ItemData
	return self:buildItemData(false)
end

return TrashBagTiedState
