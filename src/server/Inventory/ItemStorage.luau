--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InventoryTypes = require(ReplicatedStorage.Shared.Inventroy.InventoryTypes)
local InventorySlot = require(script.Parent.InventorySlot)

local ItemStorage = {}
ItemStorage.__index = ItemStorage

export type ItemStorage = typeof(setmetatable(
	{} :: {
		capacity: number,
		slots: { [number]: InventorySlot.InventorySlot },
	},
	ItemStorage
))

function ItemStorage.new(capacity: number): ItemStorage
	local slots = {}

	for id = 1, capacity do
		slots[id] = InventorySlot.new()
	end

	return setmetatable({
		capacity = capacity,
		slots = slots,
	}, ItemStorage)
end

function ItemStorage.addItem(self: ItemStorage, item: InventoryTypes.Item): boolean
	local size = item:getItemData().size
	local slotId = self:getFreeSlotId(size)

	if not slotId then
		return false
	end

	return self:putItem(item, slotId)
end

function ItemStorage.putItem(self: ItemStorage, item: InventoryTypes.Item, slotId: number): boolean
	local size = item:getItemData().size

	if not self:canPutItem(item, slotId) then
		return false
	end

	self.slots[slotId]:putItem(item)

	for id = slotId - 1, slotId - size + 1, -1 do
		self.slots[id]:lockSlot(item)
	end

	return true
end

function ItemStorage.canPutItem(self: ItemStorage, item: InventoryTypes.Item, slotId: number): boolean
	local size = item:getItemData().size

	if slotId < size or slotId > self.capacity then
		return false
	end

	for id = slotId - size + 1, slotId do
		local slot = self.slots[id]

		if slot:getItem() or slot.lockData.locked then
			return false
		end
	end

	return true
end

function ItemStorage.getFreeSpace(self: ItemStorage): number
	local freeSpace = 0

	for id = 1, self.capacity do
		if not self.slots[id]:getItem() and not self.slots[id].lockData.locked then
			freeSpace += 1
		end
	end

	return freeSpace
end

function ItemStorage.removeItem(self: ItemStorage, position: number): InventoryTypes.Item?
	local item = self.slots[position]:getItem()

	if not item then
		return nil
	end

	local size = item:getItemData().size

	for id = position, position - size + 1, -1 do
		self.slots[id]:removeItem()
		self.slots[id]:unlockSlot()
	end

	return item
end

function ItemStorage.getItemPosition(self: ItemStorage, item: InventoryTypes.Item): number?
	for id = 1, self.capacity do
		if self.slots[id]:getItem() == item then
			return id
		end
	end

	return nil
end

function ItemStorage.getItem(self: ItemStorage, position: number): InventoryTypes.Item?
	return self.slots[position]:getItem()
end

function ItemStorage.getAllItems(self: ItemStorage): { InventoryTypes.Item }
	local items = {}

	for id = 1, self.capacity do
		local item = self.slots[id]:getItem()

		if item then
			table.insert(items, item)
		end
	end

	return items
end

function ItemStorage.getSlotItems(self: ItemStorage): { [number]: InventoryTypes.Item? }
	local items: { [number]: InventoryTypes.Item? } = {}

	for id = 1, self.capacity do
		items[id] = self.slots[id]:getItem()
	end

	return items
end

function ItemStorage.getSlot(self: ItemStorage, id: number): InventorySlot.InventorySlot
	return self.slots[id]
end

function ItemStorage.getFreeSlotId(self: ItemStorage, size: number): number?
	for endId = self.capacity, size, -1 do
		local available = true

		for id = endId - size + 1, endId do
			local slot = self.slots[id]

			if slot:getItem() or slot.lockData.locked then
				available = false
				break
			end
		end

		if available then
			return endId
		end
	end

	return nil
end

return ItemStorage
