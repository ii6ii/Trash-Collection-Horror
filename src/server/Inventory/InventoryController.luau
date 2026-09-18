--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GoodSignal = require(ReplicatedStorage.Packages.GoodSignal)
local InventoryTypes = require(ReplicatedStorage.Shared.Inventroy.InventoryTypes)

local MovementController = require(ServerScriptService.Server.Movment.MovementController)

local InventoryModel = require(script.Parent.InventoryModel)
local InventoryView = require(script.Parent.InventoryView)

local HANDS_CAPACITY = 2

local InventoryController = {}
InventoryController.__index = InventoryController

export type InventoryController = typeof(setmetatable(
	{} :: {
		model: InventoryModel.InventoryModel,
		view: InventoryView.InventoryView,
		owner: Player,
		connections: { GoodSignal.Connection },
		onSync: () -> (),
	},
	InventoryController
))

function InventoryController.new(
	player: Player,
	model: InventoryModel.InventoryModel,
	view: InventoryView.InventoryView,
	onSync: () -> ()
): InventoryController
	local self = setmetatable({
		model = model,
		view = view,
		owner = player,
		connections = {},
		onSync = onSync,
	}, InventoryController) :: InventoryController

	table.insert(
		self.connections,
		model.ItemAdded:Connect(function(item)
			self:onItemAdded(item)
		end)
	)

	table.insert(
		self.connections,
		model.ItemRemoved:Connect(function(item, wasInHands)
			self:onItemRemoved(item, wasInHands)
		end)
	)

	table.insert(
		self.connections,
		model.ItemMoved:Connect(function(item, fromId, toId)
			self:onItemMoved(item, fromId, toId)
		end)
	)

	return self
end

function InventoryController.onItemAdded(self: InventoryController, item: InventoryTypes.Item): ()
	item:setOwner(self.owner)

	local slotId = self.model:getItemSlot(item)

	if slotId and slotId <= HANDS_CAPACITY then
		item:onEquipped()
		self.view:equipItem(item, slotId)
	else
		self.view.moveToStorage(item)
	end

	self:sync()
end

function InventoryController.onItemRemoved(
	self: InventoryController,
	item: InventoryTypes.Item,
	wasInHands: boolean
): ()
	self.view.moveToWorkspace(item)

	if wasInHands then
		item:onUnequipped()
	end

	item:setOwner(nil)

	self:sync()
end

function InventoryController.onItemMoved(
	self: InventoryController,
	item: InventoryTypes.Item,
	fromId: number,
	toId: number
): ()
	local wasInHands = fromId <= HANDS_CAPACITY
	local isInHands = toId <= HANDS_CAPACITY

	if wasInHands and not isInHands then
		item:onUnequipped()
	elseif not wasInHands and isInHands then
		item:onEquipped()
	end

	if isInHands then
		self.view:equipItem(item, toId)
	else
		self.view.moveToStorage(item)
	end

	self:sync()
end

function InventoryController.moveItem(self: InventoryController, fromId: number, toId: number): boolean
	return self.model:moveItem(fromId, toId)
end

function InventoryController.addItem(self: InventoryController, item: InventoryTypes.Item): boolean
	return self.model:addItem(item)
end

function InventoryController.removeItem(self: InventoryController, item: InventoryTypes.Item): boolean
	return self.model:removeItem(item)
end

function InventoryController.sync(self: InventoryController): ()
	self.view:updateAnimations(self.model:getHandSlots())

	MovementController.getMovement(self.owner):updateWeight(self.model:getItemsInHands())

	self.onSync()
end

function InventoryController.destroy(self: InventoryController): ()
	for _, connection in self.connections do
		connection:Disconnect()
	end

	table.clear(self.connections)
end

return InventoryController
