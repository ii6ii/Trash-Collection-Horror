--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GoodSignal = require(ReplicatedStorage.Packages.GoodSignal)
local InventoryTypes = require(ReplicatedStorage.Shared.Inventroy.InventoryTypes)
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

local networker = Networker.new("Inventory")

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

function Inventory.addItem(self: Inventory, item: InventoryTypes.Item): boolean
	return self.controller:addItem(item)
end

function Inventory.removeItem(self: Inventory, item: InventoryTypes.Item): boolean
	return self.controller:removeItem(item)
end

function Inventory.moveItem(self: Inventory, fromId: number, toId: number): boolean
	return self.controller:moveItem(fromId, toId)
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

function Inventory.sync(self: Inventory): ()
	self.controller:sync()
end

function Inventory.destroy(self: Inventory): ()
	allInventories[self.owner] = nil

	self.controller:destroy()
	self.view:destroy()
	self.model:destroy()
end

function Inventory.moveItemFromClient(self: Inventory, player: Player, fromId: number, toId: number): boolean
	local inventory = allInventories[player]

	if not inventory then
		return false
	end

	return inventory:moveItem(fromId, toId)
end

networker:addClientAccess(Inventory, {
	Inventory.moveItemFromClient,
})

return Inventory
