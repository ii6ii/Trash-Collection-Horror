--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local BaseTrashBagState = require(ServerScriptService.Server.UsableItems.TrashBag.States.BaseTrashBagState)

local TrashBagTypes = require(ServerScriptService.Server.UsableItems.TrashBag.TrashBagTypes)

local TrashBagEmptyState = {}
TrashBagEmptyState.__index = TrashBagEmptyState

setmetatable(TrashBagEmptyState, BaseTrashBagState)

export type TrashBagEmptyState = typeof(setmetatable({}, TrashBagEmptyState)) & BaseTrashBagState.BaseTrashBagState

function TrashBagEmptyState.new(trashBag: TrashBagTypes.TrashBag): TrashBagTypes.TrashBagState
	local self = BaseTrashBagState.new(trashBag, {}) :: any
	return setmetatable(self, TrashBagEmptyState)
end

function TrashBagEmptyState.onEnter(self: TrashBagEmptyState): ()
	print("===switched to EPMTY state===")
end

function TrashBagEmptyState.onEquipped(self: TrashBagEmptyState): ()
	self.context:switchState(self.context.allStates.opened)
end

return TrashBagEmptyState
