--!strict

-- Чистая state machine выбора слота для drag-less "select two slots to swap" UX.
-- Не знает про Roblox GUI и Instance'ы — только про номер слота.

local InventorySelection = {}
InventorySelection.__index = InventorySelection

export type InventorySelection = typeof(setmetatable(
	{} :: {
		selected: number?,
	},
	InventorySelection
))

function InventorySelection.new(): InventorySelection
	return setmetatable({
		selected = nil,
	}, InventorySelection)
end

function InventorySelection.get(self: InventorySelection): number?
	return self.selected
end

function InventorySelection.select(self: InventorySelection, id: number): ()
	self.selected = id
end

function InventorySelection.clear(self: InventorySelection): ()
	self.selected = nil
end

return InventorySelection
