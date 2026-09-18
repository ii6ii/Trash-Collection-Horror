--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InventoryTypes = require(ReplicatedStorage.Shared.Inventroy.InventoryTypes)

local InventoryItemRegistry = {}

local items: { [Model]: InventoryTypes.Item } = {}

function InventoryItemRegistry.register(instance: Model, item: InventoryTypes.Item): ()
	items[instance] = item
end

function InventoryItemRegistry.unregister(instance: Model): ()
	items[instance] = nil
end

function InventoryItemRegistry.get(instance: Model): InventoryTypes.Item?
	return items[instance]
end

return InventoryItemRegistry
