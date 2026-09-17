--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local Networker = require(ReplicatedStorage.Packages.Networker).server
local GoodSignal = require(ReplicatedStorage.Packages.GoodSignal)
local MovementController = require(ServerScriptService.Server.Movment.MovementController)
local InventoryTypes = require(ReplicatedStorage.Shared.Inventroy.InventoryTypes)
local InventorySlot = require(script.Parent.InventorySlot)
local ItemStorage = require(script.Parent.ItemStorage)

local allInventories: { [Player]: Inventory } = {}

local animatorNetworker = Networker.new("Animator")
local guiNetworker = Networker.new("Inventory")

local HANDS_CAPACITY = 2
local BACKPACK_CAPACITY = 3

local RIGHT_HAND_ANGLE_OFFSET = CFrame.Angles(math.rad(-90), 0, 0)

local ITEM_STORAGE = Instance.new("Folder")
ITEM_STORAGE.Name = "ItemStorage"
ITEM_STORAGE.Parent = ServerStorage

local function destroyWeld(item: InventoryTypes.Item): ()
	local instance = item:getItemData().instance
	local weld = instance:FindFirstChildOfClass("WeldConstraint")

	if weld then
		weld:Destroy()
	end
end

local function moveToStorage(item: InventoryTypes.Item): ()
	local instance = item:getItemData().instance

	destroyWeld(item)
	instance.Parent = ITEM_STORAGE
end

local function moveToWorkspace(item: InventoryTypes.Item): ()
	local instance = item:getItemData().instance

	destroyWeld(item)
	instance.Parent = workspace
end

local Inventory = {}
Inventory.__index = Inventory

export type Inventory = typeof(setmetatable(
	{} :: {
		handsStorage: ItemStorage.ItemStorage,
		backpackStorage: ItemStorage.ItemStorage,
		owner: Player,

		ItemMoved: GoodSignal.Signal<InventoryTypes.Item, number, number>,
		ItemAdded: GoodSignal.Signal<InventoryTypes.Item>,
		ItemRemoved: GoodSignal.Signal<InventoryTypes.Item>,
	},
	Inventory
))

function Inventory.new(player: Player): Inventory
	local self = setmetatable({
		handsStorage = ItemStorage.new(HANDS_CAPACITY),
		backpackStorage = ItemStorage.new(BACKPACK_CAPACITY),
		owner = player,

		ItemMoved = GoodSignal.new(),
		ItemAdded = GoodSignal.new(),
		ItemRemoved = GoodSignal.new(),
	}, Inventory)

	allInventories[player] = self

	self:updateGui()

	return self
end

function Inventory.equipItem(self: Inventory, item: InventoryTypes.Item, slotId: number): boolean
	local character = self.owner.Character
	if not character then
		return false
	end

	local handName = slotId == 1 and "LeftHand" or "RightHand"
	local hand = character:FindFirstChild(handName)

	if not hand or not hand:IsA("BasePart") then
		return false
	end

	local data = item:getItemData()
	local instance = data.instance
	local attachment = data.attachment

	if not attachment then
		return false
	end

	destroyWeld(item)

	instance.Anchored = false
	instance.CanCollide = false
	instance.Massless = true

	for _, descendant in instance:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = false
			descendant.CanCollide = false
			descendant.Massless = true
		end
	end

	instance.Parent = character

	local targetCFrame = hand.CFrame * RIGHT_HAND_ANGLE_OFFSET
	instance.CFrame = targetCFrame * attachment.CFrame:Inverse()

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = hand
	weld.Part1 = instance
	weld.Parent = instance

	return true
end

function Inventory.moveItem(self: Inventory, player: Player, fromId: number, toId: number): boolean
	local inventory = self.getPlayerInventory(player)

	if fromId == toId then
		return false
	end

	local fromStorage: ItemStorage.ItemStorage
	local toStorage: ItemStorage.ItemStorage
	local fromStorageId: number
	local toStorageId: number

	if fromId <= 2 then
		fromStorage = inventory.handsStorage
		fromStorageId = fromId
	elseif fromId <= 5 then
		fromStorage = inventory.backpackStorage
		fromStorageId = fromId - 2
	else
		return false
	end

	if toId <= 2 then
		toStorage = inventory.handsStorage
		toStorageId = toId
	elseif toId <= 5 then
		toStorage = inventory.backpackStorage
		toStorageId = toId - 2
	else
		return false
	end

	local item = fromStorage:getItem(fromStorageId)
	if not item then
		return false
	end

	local data = item:getItemData()

	if toStorage == inventory.handsStorage and not data.canTakeInHands then
		return false
	end

	if toStorage == inventory.backpackStorage and not data.canPutInBackpack then
		return false
	end

	if not toStorage:canPutItem(item, toStorageId) then
		return false
	end

	fromStorage:removeItem(fromStorageId)
	toStorage:putItem(item, toStorageId)

	if toStorage == inventory.handsStorage then
		if not inventory:equipItem(item, toStorageId) then
			toStorage:removeItem(toStorageId)
			fromStorage:putItem(item, fromStorageId)
			return false
		end
	else
		moveToStorage(item)
	end

	inventory:updateAnimations()

	MovementController.getMovement(inventory.owner):updateWeight(inventory:getItemsInHands())

	inventory:updateGui()

	return true
end

function Inventory.getSlotData(self: Inventory): { InventoryTypes.SlotData }
	local slots = {}

	for id = 1, 5 do
		local slot: InventorySlot.InventorySlot

		if id <= 2 then
			slot = self.handsStorage:getSlot(id)
		else
			slot = self.backpackStorage:getSlot(id - 2)
		end

		local item = slot:getItem()
		local lockedBy = slot.lockData.lockedBy

		table.insert(slots, {
			type = item and item:getItemData().type or lockedBy and lockedBy:getItemData().type or nil,

			isLock = item == nil and slot.lockData.locked,
		})
	end

	return slots
end

function Inventory.updateGui(self: Inventory)
	guiNetworker:fire(self.owner, "UpdateGui", self:getSlotData())
end

function Inventory.getPlayerInventory(player: Player): Inventory
	if not allInventories[player] then
		Inventory.new(player)
	end

	return allInventories[player]
end

function Inventory.getItemsInHands(self: Inventory): { InventoryTypes.Item }
	return self.handsStorage:getAllItems()
end

function Inventory.destroy(self: Inventory): ()
	allInventories[self.owner] = nil
end

function Inventory.updateAnimations(self: Inventory): ()
	animatorNetworker:fire(self.owner, "StopHandAnimations")

	local leftItem = self.handsStorage:getItem(1)
	local rightItem = self.handsStorage:getItem(2)

	if leftItem then
		animatorNetworker:fire(self.owner, "HoldLeftHand")
	end

	if rightItem then
		animatorNetworker:fire(self.owner, "HoldRightHand")
	end

	if rightItem and rightItem:getItemData().size >= 2 then
		animatorNetworker:fire(self.owner, "HoldLeftHand")
	end
end

function Inventory.addItem(self: Inventory, item: InventoryTypes.Item): boolean
	local data = item:getItemData()

	if data.canTakeInHands then
		local slotId = self.handsStorage:getFreeSlotId(data.size)

		if not slotId then
			return false
		end

		if not self.handsStorage:addItem(item) then
			return false
		end

		if not self:equipItem(item, slotId) then
			self.handsStorage:removeItem(slotId)
			return false
		end

		item:setOwner(self.owner)
		item:onEquipped()

		self:updateAnimations()

		MovementController.getMovement(self.owner):updateWeight(self:getItemsInHands())
		self:updateGui()

		return true
	end

	if data.canPutInBackpack then
		if not self.backpackStorage:addItem(item) then
			return false
		end

		item:setOwner(self.owner)
		item:onEquipped()

		moveToStorage(item)

		self:updateAnimations()
		self:updateGui()

		return true
	end

	return false
end

function Inventory.removeItem(self: Inventory, item: InventoryTypes.Item): ()
	local position = self.handsStorage:getItemPosition(item)

	if position then
		self.handsStorage:removeItem(position)

		moveToWorkspace(item)

		item:setOwner(nil)
		item:onUnequipped()

		self:updateAnimations()

		MovementController.getMovement(self.owner):updateWeight(self:getItemsInHands())

		self:updateGui()

		return
	end

	position = self.backpackStorage:getItemPosition(item)

	if position then
		self.backpackStorage:removeItem(position)

		moveToWorkspace(item)

		item:setOwner(nil)
		item:onUnequipped()

		self:updateAnimations()
		self:updateGui()
	end
end

guiNetworker:addClientAccess(Inventory, { Inventory.moveItem })

return Inventory
