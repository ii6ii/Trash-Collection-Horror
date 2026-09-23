--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InputSystemTypes = require(ReplicatedStorage.Shared.Types.InputSystemTypes)
local InstanceRegistry = require(ReplicatedStorage.Shared.Utils.InstanceRegistry)

export type UsableItem = {
	handleInputStart: (self: UsableItem, context: InputSystemTypes.InputContext) -> (),
	handleInputEnd: (self: UsableItem, context: InputSystemTypes.InputContext) -> (),
	handleInputSwitch: (self: UsableItem, context: InputSystemTypes.InputContext) -> (),
	canHandleInput: (self: UsableItem, context: InputSystemTypes.InputContext) -> boolean,
}

return InstanceRegistry.new() :: InstanceRegistry.InstanceRegistry<UsableItem>
