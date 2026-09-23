--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ItemStorage = require(ServerScriptService.Server.Features.Inventory.ItemStorage)
local GoodSignal = require(ReplicatedStorage.Packages.GoodSignal)
local InventoryTypes = require(ReplicatedStorage.Shared.Types.InventoryTypes)
local InventoryConfig = require(ReplicatedStorage.Shared.Config.InventoryConfig)

local HANDS_CAPACITY = InventoryConfig.HandsCapacity
local TOTAL_SLOTS = InventoryConfig.TotalSlots

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

-- Слот, приведённый к конкретному хранилищу (руки/рюкзак) и его внутреннему id.
type SlotRef = {
	storage: ItemStorage.ItemStorage,
	storageId: number,
	kind: InventoryTypes.SlotKind,
}

local function resolveSlot(self: InventoryModel, slotId: number): SlotRef?
	if slotId < 1 or slotId > TOTAL_SLOTS or slotId % 1 ~= 0 then
		return nil
	end

	if slotId <= HANDS_CAPACITY then
		return { storage = self.handsStorage, storageId = slotId, kind = "Hands" }
	end

	return { storage = self.backpackStorage, storageId = slotId - HANDS_CAPACITY, kind = "Backpack" }
end

local function isAllowedInKind(item: InventoryTypes.Item, kind: InventoryTypes.SlotKind): boolean
	local data = item:getItemData()

	if kind == "Hands" then
		return data.canTakeInHands
	end

	return data.canPutInBackpack
end

-- Кладёт предмет в пустой слот с учётом правила "руки/рюкзак". Ничего не меняет при неудаче.
local function tryPlace(item: InventoryTypes.Item, slot: SlotRef): boolean
	if not isAllowedInKind(item, slot.kind) then
		return false
	end

	return slot.storage:putItem(item, slot.storageId)
end

function InventoryModel.new(): InventoryModel
	return setmetatable({
		handsStorage = ItemStorage.new(InventoryConfig.HandsCapacity),
		backpackStorage = ItemStorage.new(InventoryConfig.BackpackCapacity),

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

-- Переносит предмет из занятого слота (from) в пустой (to). Порядок операций
-- («сначала положить в пустой to, потом освободить from») исключает необходимость
-- отдельного отката: to гарантированно свободен до и после неудачной попытки.
function InventoryModel.moveToEmptySlot(
	self: InventoryModel,
	item: InventoryTypes.Item,
	from: SlotRef,
	to: SlotRef,
	fromId: number,
	toId: number
): boolean
	if not tryPlace(item, to) then
		return false
	end

	from.storage:removeItem(from.storageId)

	self.ItemMoved:Fire(item, fromId, toId)

	return true
end

-- Меняет местами предметы в двух занятых слотах. Оба слота освобождаются заранее,
-- чтобы проверка вместимости (canPutItem) не спотыкалась о собственный старый предмет.
function InventoryModel.swapSlots(
	self: InventoryModel,
	fromItem: InventoryTypes.Item,
	toItem: InventoryTypes.Item,
	from: SlotRef,
	to: SlotRef,
	fromId: number,
	toId: number
): boolean
	if not isAllowedInKind(toItem, from.kind) or not isAllowedInKind(fromItem, to.kind) then
		return false
	end

	from.storage:removeItem(from.storageId)
	to.storage:removeItem(to.storageId)

	local fits = from.storage:canPutItem(toItem, from.storageId) and to.storage:canPutItem(fromItem, to.storageId)

	if not fits then
		from.storage:putItem(fromItem, from.storageId)
		to.storage:putItem(toItem, to.storageId)
		return false
	end

	from.storage:putItem(toItem, from.storageId)
	to.storage:putItem(fromItem, to.storageId)

	self.ItemMoved:Fire(fromItem, fromId, toId)
	self.ItemMoved:Fire(toItem, toId, fromId)

	return true
end

function InventoryModel.moveItem(self: InventoryModel, fromId: number, toId: number): boolean
	if fromId == toId then
		return false
	end

	local from = resolveSlot(self, fromId)
	local to = resolveSlot(self, toId)

	if not from or not to then
		return false
	end

	local fromItem = from.storage:getItem(from.storageId)
	local toItem = to.storage:getItem(to.storageId)

	if not fromItem and not toItem then
		return false
	end

	if not fromItem and toItem then
		return self:moveToEmptySlot(toItem, to, from, toId, fromId)
	end

	if fromItem and not toItem then
		return self:moveToEmptySlot(fromItem, from, to, fromId, toId)
	end

	return self:swapSlots(fromItem :: InventoryTypes.Item, toItem :: InventoryTypes.Item, from, to, fromId, toId)
end

function InventoryModel.getItem(self: InventoryModel, slotId: number): InventoryTypes.Item?
	local slot = resolveSlot(self, slotId)

	if not slot then
		return nil
	end

	return slot.storage:getItem(slot.storageId)
end

function InventoryModel.getItemsInHands(self: InventoryModel): { InventoryTypes.Item }
	return self.handsStorage:getAllItems()
end

function InventoryModel.getAllItems(self: InventoryModel): { InventoryTypes.Item }
	local items = self.handsStorage:getAllItems()

	for _, item in self.backpackStorage:getAllItems() do
		table.insert(items, item)
	end

	return items
end

function InventoryModel.getHandSlots(self: InventoryModel): { [number]: InventoryTypes.Item? }
	return self.handsStorage:getSlotItems()
end

function InventoryModel.isHandSlot(self: InventoryModel, slotId: number): boolean
	return slotId >= 1 and slotId <= HANDS_CAPACITY
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
		local slotRef = resolveSlot(self, id) :: SlotRef

		local slot = slotRef.storage:getSlot(slotRef.storageId)
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
