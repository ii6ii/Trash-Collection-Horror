--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GoodSignal = require(ReplicatedStorage.Packages.GoodSignal)
local InstanceRegistry = require(ReplicatedStorage.Shared.Utils.InstanceRegistry)
local InventoryTypes = require(ReplicatedStorage.Shared.Types.InventoryTypes)

-- Узкий интерфейс вместо конкретного ItemBin: избегает цикла require
-- (ItemBin сам зависит от BinRegistry ради PickedUp) и описывает только то,
-- что реально дёргается через реестр (см. BinService).
export type Bin = {
	addItem: (self: Bin, player: Player, item: InventoryTypes.Item) -> boolean,
	removeItem: (self: Bin, player: Player, item: InventoryTypes.Item) -> boolean,
	getItems: (self: Bin) -> { InventoryTypes.Item },
	isFull: (self: Bin) -> boolean,
	playerInZone: (self: Bin, player: Player) -> boolean,
	drop: (self: Bin, player: Player) -> boolean,
	destroy: (self: Bin) -> (),
}

local registry = InstanceRegistry.new() :: InstanceRegistry.InstanceRegistry<Bin>

local BinRegistry = {
	Register = registry.register,
	Unregister = registry.unregister,
	Get = registry.get,

	PickedUp = GoodSignal.new() :: GoodSignal.Signal<Player, Model>,
}

return BinRegistry
