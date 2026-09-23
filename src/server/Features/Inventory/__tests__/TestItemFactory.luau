--!strict

-- Не спека: фабрика фейковых Item для тестов Inventory-модулей.
-- TestEz подбирает только ModuleScript'ы с именем "*.spec", так что этот
-- файл в прогон тестов не попадёт.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InventoryTypes = require(ReplicatedStorage.Shared.Types.InventoryTypes)

local TestItemFactory = {}

export type FakeItemOverrides = {
	type: string?,
	weight: number?,
	size: number?,
	canTakeInHands: boolean?,
	canPutInBackpack: boolean?,
}

export type FakeItem = InventoryTypes.Item & {
	clearedReason: InventoryTypes.ClearReason?,
	equipped: boolean,
}

function TestItemFactory.new(overrides: FakeItemOverrides?): FakeItem
	overrides = overrides or {}

	local data: InventoryTypes.ItemData = {
		type = overrides.type or "test",
		weight = overrides.weight or 0,
		size = overrides.size or 1,
		canTakeInHands = if overrides.canTakeInHands == nil then true else overrides.canTakeInHands :: boolean,
		canPutInBackpack = if overrides.canPutInBackpack == nil then true else overrides.canPutInBackpack :: boolean,
		instance = nil :: any,
		attachment = nil,
	}

	local owner: Player? = nil

	local item = {} :: FakeItem

	item.equipped = false
	item.clearedReason = nil

	function item:getItemData(): InventoryTypes.ItemData
		return data
	end

	function item:setOwner(newOwner: Player?): ()
		owner = newOwner
	end

	function item:getOwner(): Player?
		return owner
	end

	function item:onEquipped(): ()
		self.equipped = true
	end

	function item:onUnequipped(): ()
		self.equipped = false
	end

	function item:onInventoryCleared(reason: InventoryTypes.ClearReason): ()
		self.clearedReason = reason
	end

	return item
end

return TestItemFactory
