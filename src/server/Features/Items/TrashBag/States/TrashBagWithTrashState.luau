--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local InputSystemTypes = require(ReplicatedStorage.Shared.Types.InputSystemTypes)
local InventoryTypes = require(ReplicatedStorage.Shared.Types.InventoryTypes)
local BaseTrashBagState = require(ServerScriptService.Server.Features.Items.TrashBag.States.BaseTrashBagState)
local TrashBagTypes = require(ServerScriptService.Server.Features.Items.TrashBag.TrashBagTypes)

local TrashBagWithTrashState = {}
TrashBagWithTrashState.__index = TrashBagWithTrashState

setmetatable(TrashBagWithTrashState, BaseTrashBagState)

export type TrashBagWithTrashState = typeof(setmetatable({} :: TrashBagTypes.TrashBagState, TrashBagWithTrashState))

function TrashBagWithTrashState.new(trashBag: TrashBagTypes.TrashBag): TrashBagTypes.TrashBagState
	local self: any
	self = BaseTrashBagState.new(trashBag, {
		FInputStart = function(bag: TrashBagTypes.TrashBag, context: InputSystemTypes.InputContext)
			self:collectTrash(context)
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

function TrashBagWithTrashState.collectTrash(self: TrashBagWithTrashState, context: InputSystemTypes.InputContext)
	self.context:tryCollectTrash(context)

	if self.context.trashInside == self.context.capacity then
		self.context:switchState(self.context.allStates.tying)
	end
end

function TrashBagWithTrashState.getItemData(self: TrashBagWithTrashState): InventoryTypes.ItemData
	local base: TrashBagTypes.TrashBagState = self :: any
	return base:buildItemData(false)
end

return TrashBagWithTrashState
