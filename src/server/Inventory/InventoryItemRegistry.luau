--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InventoryTypes = require(ReplicatedStorage.Shared.Inventroy.InventoryTypes)

local InventoryItemRegistry = {}

local items: { [BasePart]: InventoryTypes.Item } = {}

function InventoryItemRegistry.register(instance: BasePart, item: InventoryTypes.Item): ()
	items[instance] = item
end

function InventoryItemRegistry.unregister(instance: BasePart): ()
	items[instance] = nil
end

function InventoryItemRegistry.get(instance: BasePart): InventoryTypes.Item?
	return items[instance]
end

return InventoryItemRegistry
