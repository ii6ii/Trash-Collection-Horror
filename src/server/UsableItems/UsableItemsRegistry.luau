--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InputSystemTypes = require(ReplicatedStorage.Shared.InputSystem.InputSystemTypes)

export type UsableItem = {
	handleInputStart: (self: UsableItem, context: InputSystemTypes.InputContext) -> (),
	handleInputEnd: (self: UsableItem, context: InputSystemTypes.InputContext) -> (),
	handleInputSwitch: (self: UsableItem, context: InputSystemTypes.InputContext) -> (),
	canHandleInput: (self: UsableItem, context: InputSystemTypes.InputContext) -> boolean,
}

local UsableItemsRegistry = {}

local items: { [Model]: UsableItem } = {}

function UsableItemsRegistry.register(instance: Model, item: UsableItem): ()
	items[instance] = item
end

function UsableItemsRegistry.unregister(instance: Model): ()
	items[instance] = nil
end

function UsableItemsRegistry.get(instance: Model): UsableItem?
	return items[instance]
end

return UsableItemsRegistry
