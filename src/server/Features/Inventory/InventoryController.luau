--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GoodSignal = require(ReplicatedStorage.Packages.GoodSignal)
local InventoryTypes = require(ReplicatedStorage.Shared.Types.InventoryTypes)

local MovementController = require(ServerScriptService.Server.Core.Movement.MovementController)

local InventoryModel = require(script.Parent.InventoryModel)
local InventoryView = require(script.Parent.InventoryView)

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

	if slotId and self.model:isHandSlot(slotId) then
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
	local wasInHands = self.model:isHandSlot(fromId)
	local isInHands = self.model:isHandSlot(toId)

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

-- Вызывается из onItemAdded/onItemRemoved/onItemMoved: мутации приходят из
-- модели напрямую (см. Inventory.addItem/removeItem/moveItem), контроллер лишь
-- реагирует на её сигналы и не дублирует эти методы как passthrough.
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
