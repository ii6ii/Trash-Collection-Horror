--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local InputSystemTypes = require(ReplicatedStorage.Shared.InputSystem.InputSystemTypes)
local BaseTrashBagState = require(ServerScriptService.Server.UsableItems.TrashBag.States.BaseTrashBagState)
local TrashBagTypes = require(ServerScriptService.Server.UsableItems.TrashBag.TrashBagTypes)

local TrashBagOpenedState = {}
TrashBagOpenedState.__index = TrashBagOpenedState

setmetatable(TrashBagOpenedState, BaseTrashBagState)

export type TrashBagOpenedState = typeof(setmetatable({} :: TrashBagTypes.TrashBagState, TrashBagOpenedState))

function TrashBagOpenedState.new(trashBag: TrashBagTypes.TrashBag): TrashBagTypes.TrashBagState
	local self: any
	self = BaseTrashBagState.new(trashBag, {
		FInputStart = function(trashBag: TrashBagTypes.TrashBag, context: InputSystemTypes.InputContext)
			self:collectTrash(context)
		end,
	})
	return setmetatable(self, TrashBagOpenedState)
end

function TrashBagOpenedState.onEnter(self: TrashBagOpenedState): ()
	print("===switched to OPENED state===")
end

function TrashBagOpenedState.onUnequipped(self: TrashBagOpenedState): ()
	self.context:switchState(self.context.allStates.empty)
end

function TrashBagOpenedState.collectTrash(self: TrashBagOpenedState, context: InputSystemTypes.InputContext)
	local result = self.context:tryCollectTrash(context)
	if not result then
		return
	end
	print(`---Trash Collected ({self.context.trashInside})---`)
	self.context:switchState(self.context.allStates.withTrash)
end

return TrashBagOpenedState
