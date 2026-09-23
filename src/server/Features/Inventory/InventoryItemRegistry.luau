--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InstanceRegistry = require(ReplicatedStorage.Shared.Utils.InstanceRegistry)
local InventoryTypes = require(ReplicatedStorage.Shared.Types.InventoryTypes)

return InstanceRegistry.new() :: InstanceRegistry.InstanceRegistry<InventoryTypes.Item>
