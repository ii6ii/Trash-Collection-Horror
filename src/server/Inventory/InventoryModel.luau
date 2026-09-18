--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ItemStorage = require(ServerScriptService.Server.Inventory.ItemStorage)
local GoodSignal = require(ReplicatedStorage.Packages.GoodSignal)
local InventoryTypes = require(ReplicatedStorage.Shared.Inventroy.InventoryTypes)

local HANDS_CAPACITY = 2
local BACKPACK_CAPACITY = 3
local TOTAL_SLOTS = HANDS_CAPACITY + BACKPACK_CAPACITY

local InventoryModel = {}
InventoryModel.__index = InventoryModel

export type InventoryModel = typeof(setmetatable(
	{} :: {
		handsStorage: ItemStorage.ItemStorage,
		backpackStorage: ItemStorage.ItemStorage,

		ItemAdded: GoodSignal.Signal<InventoryTypes.Item>,
		ItemRemoved: GoodSignal.Signal<InventoryTypes.Item, boolean>,
		ItemMoved: GoodSignal.Signal<InventoryTypes.Item, number, number>,
	},
	InventoryModel
))

local function getStorage(self: InventoryModel, slotId: number): (ItemStorage.ItemStorage?, number?)
	if slotId < 1 or slotId > TOTAL_SLOTS then
		return nil, nil
	end

	if slotId <= HANDS_CAPACITY then
		return self.handsStorage, slotId
	end

	return self.backpackStorage, slotId - HANDS_CAPACITY
end

local function canPutItem(
	item: InventoryTypes.Item,
	storage: ItemStorage.ItemStorage,
	position: number,
	handsStorage: ItemStorage.ItemStorage
): boolean
	local data = item:getItemData()

	if storage == handsStorage then
		if not data.canTakeInHands then
			return false
		end
	elseif not data.canPutInBackpack then
		return false
	end

	return storage:canPutItem(item, position)
end

function InventoryModel.new(): InventoryModel
	return setmetatable({
		handsStorage = ItemStorage.new(HANDS_CAPACITY),
		backpackStorage = ItemStorage.new(BACKPACK_CAPACITY),

		ItemAdded = GoodSignal.new(),
		ItemRemoved = GoodSignal.new(),
		ItemMoved = GoodSignal.new(),
	}, InventoryModel)
end

function InventoryModel.addItem(self: InventoryModel, item: InventoryTypes.Item): boolean
	local data = item:getItemData()

	if data.canTakeInHands and self.handsStorage:addItem(item) then
		self.ItemAdded:Fire(item)
		return true
	end

	if data.canPutInBackpack and self.backpackStorage:addItem(item) then
		self.ItemAdded:Fire(item)
		return true
	end

	return false
end

function InventoryModel.removeItem(self: InventoryModel, item: InventoryTypes.Item): boolean
	local position = self.handsStorage:getItemPosition(item)

	if position then
		self.handsStorage:removeItem(position)
		self.ItemRemoved:Fire(item, true)
		return true
	end

	position = self.backpackStorage:getItemPosition(item)

	if position then
		self.backpackStorage:removeItem(position)
		self.ItemRemoved:Fire(item, false)
		return true
	end

	return false
end

function InventoryModel.moveItem(self: InventoryModel, fromId: number, toId: number): boolean
	if fromId == toId then
		return false
	end

	local fromStorage, fromStorageId = getStorage(self, fromId)
	local toStorage, toStorageId = getStorage(self, toId)

	if not fromStorage or not fromStorageId then
		return false
	end

	if not toStorage or not toStorageId then
		return false
	end

	local fromItem = fromStorage:getItem(fromStorageId)
	local toItem = toStorage:getItem(toStorageId)

	-- Оба слота пустые.
	if not fromItem and not toItem then
		return false
	end

	-- Первый слот пустой, второй занят.
	if not fromItem and toItem then
		if not canPutItem(toItem, fromStorage, fromStorageId, self.handsStorage) then
			return false
		end

		toStorage:removeItem(toStorageId)

		if not fromStorage:putItem(toItem, fromStorageId) then
			toStorage:putItem(toItem, toStorageId)
			return false
		end

		self.ItemMoved:Fire(toItem, toId, fromId)

		return true
	end

	-- Первый слот занят, второй пустой.
	if fromItem and not toItem then
		if not canPutItem(fromItem, toStorage, toStorageId, self.handsStorage) then
			return false
		end

		fromStorage:removeItem(fromStorageId)

		if not toStorage:putItem(fromItem, toStorageId) then
			fromStorage:putItem(fromItem, fromStorageId)
			return false
		end

		self.ItemMoved:Fire(fromItem, fromId, toId)

		return true
	end

	-- Оба слота заняты: SWAP.
	if not fromItem or not toItem then
		return false
	end

	local fromData = fromItem:getItemData()
	local toData = toItem:getItemData()

	-- Проверяем разрешение находиться в соответствующем хранилище.
	if fromStorage == self.handsStorage and not toData.canTakeInHands then
		return false
	end

	if fromStorage == self.backpackStorage and not toData.canPutInBackpack then
		return false
	end

	if toStorage == self.handsStorage and not fromData.canTakeInHands then
		return false
	end

	if toStorage == self.backpackStorage and not fromData.canPutInBackpack then
		return false
	end

	-- Освобождаем оба места перед проверкой вместимости.
	fromStorage:removeItem(fromStorageId)
	toStorage:removeItem(toStorageId)

	-- Проверяем, помещаются ли предметы
	-- в освободившиеся места.
	if not fromStorage:canPutItem(toItem, fromStorageId) then
		fromStorage:putItem(fromItem, fromStorageId)
		toStorage:putItem(toItem, toStorageId)

		return false
	end

	if not toStorage:canPutItem(fromItem, toStorageId) then
		fromStorage:putItem(fromItem, fromStorageId)
		toStorage:putItem(toItem, toStorageId)

		return false
	end

	-- Выполняем swap.
	if not fromStorage:putItem(toItem, fromStorageId) then
		fromStorage:putItem(fromItem, fromStorageId)
		toStorage:putItem(toItem, toStorageId)

		return false
	end

	if not toStorage:putItem(fromItem, toStorageId) then
		fromStorage:removeItem(fromStorageId)

		fromStorage:putItem(fromItem, fromStorageId)
		toStorage:putItem(toItem, toStorageId)

		return false
	end

	self.ItemMoved:Fire(fromItem, fromId, toId)
	self.ItemMoved:Fire(toItem, toId, fromId)

	return true
end

function InventoryModel.getItem(self: InventoryModel, slotId: number): InventoryTypes.Item?
	local storage, storageId = getStorage(self, slotId)

	if not storage or not storageId then
		return nil
	end

	return storage:getItem(storageId)
end

function InventoryModel.getItemsInHands(self: InventoryModel): { InventoryTypes.Item }
	return self.handsStorage:getAllItems()
end

function InventoryModel.getHandSlots(self: InventoryModel): { [number]: InventoryTypes.Item? }
	return self.handsStorage:getSlotItems()
end

function InventoryModel.getItemSlot(self: InventoryModel, item: InventoryTypes.Item): number?
	local position = self.handsStorage:getItemPosition(item)

	if position then
		return position
	end

	position = self.backpackStorage:getItemPosition(item)

	if position then
		return position + HANDS_CAPACITY
	end

	return nil
end

function InventoryModel.getSlotData(self: InventoryModel): { InventoryTypes.SlotData }
	local slots: { InventoryTypes.SlotData } = {}

	for id = 1, TOTAL_SLOTS do
		local storage, storageId = getStorage(self, id)

		if not storage or not storageId then
			continue
		end

		local slot = storage:getSlot(storageId)
		local item = slot:getItem()
		local lockedBy = slot.lockData.lockedBy

		table.insert(slots, {
			type = item and item:getItemData().type or lockedBy and lockedBy:getItemData().type or nil,

			isLock = item == nil and slot.lockData.locked,
		})
	end

	return slots
end

function InventoryModel.destroy(self: InventoryModel): () end

return InventoryModel
