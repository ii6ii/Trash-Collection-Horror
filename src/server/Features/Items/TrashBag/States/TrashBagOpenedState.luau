--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local InputSystemTypes = require(ReplicatedStorage.Shared.Types.InputSystemTypes)
local BaseTrashBagState = require(ServerScriptService.Server.Features.Items.TrashBag.States.BaseTrashBagState)
local TrashBagTypes = require(ServerScriptService.Server.Features.Items.TrashBag.TrashBagTypes)

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

function TrashBagOpenedState.onUnequipped(self: TrashBagOpenedState): ()
	self.context:switchState(self.context.allStates.empty)
end

function TrashBagOpenedState.collectTrash(self: TrashBagOpenedState, context: InputSystemTypes.InputContext)
	if not self.context:tryCollectTrash(context) then
		return
	end
	self.context:switchState(self.context.allStates.withTrash)
end

return TrashBagOpenedState
