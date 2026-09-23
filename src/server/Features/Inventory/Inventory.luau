--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GoodSignal = require(ReplicatedStorage.Packages.GoodSignal)
local InventoryTypes = require(ReplicatedStorage.Shared.Types.InventoryTypes)
local Networker = require(ReplicatedStorage.Packages.Networker).server

local InventoryModel = require(script.Parent.InventoryModel)
local InventoryView = require(script.Parent.InventoryView)
local InventoryController = require(script.Parent.InventoryController)

local allInventories: { [Player]: Inventory } = {}

local Inventory = {}
Inventory.__index = Inventory

export type Inventory = typeof(setmetatable(
	{} :: {
		model: InventoryModel.InventoryModel,
		view: InventoryView.InventoryView,
		controller: InventoryController.InventoryController,
		owner: Player,

		ItemAdded: GoodSignal.Signal<InventoryTypes.Item>,
		ItemRemoved: GoodSignal.Signal<InventoryTypes.Item, boolean>,
		ItemMoved: GoodSignal.Signal<InventoryTypes.Item, number, number>,
	},
	Inventory
))

local networker: any

local function isValidSlotId(value: any): boolean
	return typeof(value) == "number" and value % 1 == 0
end

function Inventory.init(): ()
	networker = Networker.new("Inventory")
	networker:addClientAccess(Inventory, {
		Inventory.moveItemFromClient,
	})
end

function Inventory.new(player: Player): Inventory
	local model = InventoryModel.new()
	local view = InventoryView.new(player)

	local controller = InventoryController.new(player, model, view, function()
		networker:fire(player, "UpdateGui", model:getSlotData())
	end)

	local self = setmetatable({
		owner = player,
		model = model,
		view = view,
		controller = controller,

		ItemAdded = model.ItemAdded,
		ItemRemoved = model.ItemRemoved,
		ItemMoved = model.ItemMoved,
	}, Inventory)

	allInventories[player] = self

	return self
end

function Inventory.getPlayerInventory(player: Player): Inventory
	return allInventories[player] or Inventory.new(player)
end

-- Мутации идут напрямую в модель: контроллер не добавляет ничего на пути вызова,
-- он реагирует на её сигналы (ItemAdded/ItemRemoved/ItemMoved) независимо от того,
-- кто вызвал мутацию, и этим обновляет View/анимации/вес/networker.
function Inventory.addItem(self: Inventory, item: InventoryTypes.Item): boolean
	return self.model:addItem(item)
end

function Inventory.removeItem(self: Inventory, item: InventoryTypes.Item): boolean
	return self.model:removeItem(item)
end

function Inventory.moveItem(self: Inventory, fromId: number, toId: number): boolean
	return self.model:moveItem(fromId, toId)
end

function Inventory.getItem(self: Inventory, slotId: number): InventoryTypes.Item?
	return self.model:getItem(slotId)
end

function Inventory.getItemsInHands(self: Inventory): { InventoryTypes.Item }
	return self.model:getItemsInHands()
end

function Inventory.getHandSlots(self: Inventory): { [number]: InventoryTypes.Item? }
	return self.model:getHandSlots()
end

function Inventory.getSlotData(self: Inventory): { InventoryTypes.SlotData }
	return self.model:getSlotData()
end

-- Принудительно изымает все предметы из инвентаря, дав каждому шанс отреагировать
-- по-своему (см. InventoryTypes.Item.onInventoryCleared) до того, как он будет
-- изъят обычным путём (уронен в мир, если предмет не решил иначе сам).
function Inventory.clear(self: Inventory, reason: InventoryTypes.ClearReason): ()
	for _, item in self.model:getAllItems() do
		item:onInventoryCleared(reason)

		if self.model:getItemSlot(item) then
			self:removeItem(item)
		end
	end
end

function Inventory.clearPlayerInventory(player: Player, reason: InventoryTypes.ClearReason): ()
	local inventory = allInventories[player]

	if inventory then
		inventory:clear(reason)
	end
end

function Inventory.destroy(self: Inventory): ()
	self:clear("PlayerLeaving")

	allInventories[self.owner] = nil

	self.controller:destroy()
	self.view:destroy()
	self.model:destroy()
end

function Inventory.moveItemFromClient(self: Inventory, player: Player, fromId: any, toId: any): boolean
	if not isValidSlotId(fromId) or not isValidSlotId(toId) then
		return false
	end

	local inventory = allInventories[player]

	if not inventory then
		return false
	end

	return inventory:moveItem(fromId, toId)
end

return Inventory
