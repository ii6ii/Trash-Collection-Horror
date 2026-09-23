--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Inventory = require(ServerScriptService.Server.Features.Inventory.Inventory)
local TrashBagTyer = require(script.Parent.TrashBagTyer)
local InputSystemTypes = require(ReplicatedStorage.Shared.Types.InputSystemTypes)
local InventoryTypes = require(ReplicatedStorage.Shared.Types.InventoryTypes)
local SoundConfig = require(ReplicatedStorage.Shared.Config.SoundConfig)
local TrashBagConfig = require(ReplicatedStorage.Shared.Config.TrashBagConfig)
local TrashBagTypes = require(script.Parent.TrashBagTypes)
local InventoryItemRegistry = require(ServerScriptService.Server.Features.Inventory.InventoryItemRegistry)
local MovementController = require(ServerScriptService.Server.Core.Movement.MovementController)
local SoundService = require(ServerScriptService.Server.Core.Sound.SoundService)
local UsableItemsRegistry = require(ServerScriptService.Server.Core.UsableItems.UsableItemsRegistry)

local TrashBagEmptyState = require(ServerScriptService.Server.Features.Items.TrashBag.States.TrashBagEmptyState)
local TrashBagOnGroundState = require(ServerScriptService.Server.Features.Items.TrashBag.States.TrashBagOnGroundState)
local TrashBagOpenedState = require(ServerScriptService.Server.Features.Items.TrashBag.States.TrashBagOpenedState)
local TrashBagTiedState = require(ServerScriptService.Server.Features.Items.TrashBag.States.TrashBagTiedState)
local TrashBagTyingState = require(ServerScriptService.Server.Features.Items.TrashBag.States.TrashBagTyingState)
local TrashBagUntyingState = require(ServerScriptService.Server.Features.Items.TrashBag.States.TrashBagUntyingState)
local TrashBagWithTrashState = require(ServerScriptService.Server.Features.Items.TrashBag.States.TrashBagWithTrashState)

local CAPACITY = TrashBagConfig.Capacity
local WEIGHT_PRE_TRASH = TrashBagConfig.WeightPerTrash

local EMPTY_SIZE_SCALE = TrashBagConfig.EmptySizeScale
local TRASH_SIZE_SCALE = TrashBagConfig.TrashSizeScale

local TrashBag = {}
TrashBag.__index = TrashBag
TrashBag.allBags = {}

function TrashBag.new(instance: Model): TrashBagTypes.TrashBag
	local model = instance:FindFirstChild("Model") :: BasePart
	local self = setmetatable({
		instance = instance,
		originalSize = model.Size,
		capacity = CAPACITY,
		trashInside = 0,
		tieProgress = 0,
		owner = nil,
		attachment = instance:FindFirstChildOfClass("Attachment"),
	}, TrashBag) :: any

	self.allStates = {
		empty = TrashBagEmptyState.new(self),
		opened = TrashBagOpenedState.new(self),
		withTrash = TrashBagWithTrashState.new(self),
		tying = TrashBagTyingState.new(self),
		tied = TrashBagTiedState.new(self),
		untying = TrashBagUntyingState.new(self),
		onGround = TrashBagOnGroundState.new(self),
	}

	self.lastState = self.allStates.opened
	self.currentState = self.allStates.opened
	self.currentState:onEnter()

	UsableItemsRegistry.register(instance, self :: any)
	InventoryItemRegistry.register(instance, self :: any)
	TrashBagTyer.addBag(self)

	self:updateSize()

	TrashBag.allBags[instance] = self

	return self :: TrashBagTypes.TrashBag
end

function TrashBag.updateSize(self: TrashBagTypes.TrashBag): ()
	local scale = EMPTY_SIZE_SCALE + self.trashInside * TRASH_SIZE_SCALE

	local model = self.instance:FindFirstChild("Model") :: BasePart
	model.Size = Vector3.new(self.originalSize.X * scale, self.originalSize.Y, self.originalSize.Z)
end

function TrashBag.switchState(self: TrashBagTypes.TrashBag, newState: TrashBagTypes.TrashBagState)
	self.currentState:onExit()
	self.lastState = self.currentState
	self.currentState = newState
	self.currentState:onEnter()
end

function TrashBag.tryCollectTrash(self: TrashBagTypes.TrashBag, context: InputSystemTypes.InputContext): boolean
	if not self.owner then
		return false
	end

	if self.trashInside >= self.capacity then
		return false
	end

	local character = self.owner.Character
	if not character then
		return false
	end

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = { character }

	local result = workspace:Raycast(context.cameraCFrame.Position, context.cameraCFrame.LookVector * 10, raycastParams)

	if not result or not CollectionService:HasTag(result.Instance.Parent, "Trash") then
		return false
	end

	local trash = result.Instance.Parent
	local size = trash:GetAttribute("TrashSize") :: number

	if self.trashInside + size > self.capacity then
		return false
	end

	trash:Destroy()

	self.trashInside += size
	self:updateSize()

	local playerInventory = Inventory.getPlayerInventory(self.owner)
	MovementController.getMovement(self.owner):updateWeight(playerInventory:getItemsInHands())
	SoundService.Play(self.owner, SoundConfig.trashPickup)

	return true
end

function TrashBag.getWeight(self: TrashBagTypes.TrashBag): number
	return self.trashInside * WEIGHT_PRE_TRASH + 1
end

function TrashBag.getItemData(self: TrashBagTypes.TrashBag): InventoryTypes.ItemData
	return self.currentState:getItemData()
end

function TrashBag.setOwner(self: TrashBagTypes.TrashBag, owner: Player?)
	self.owner = owner
end

function TrashBag.getOwner(self: TrashBagTypes.TrashBag): Player?
	return self.owner
end

function TrashBag.onEquipped(self: TrashBagTypes.TrashBag)
	if not self.owner then
		return
	end
	SoundService.Play(self.owner, SoundConfig.trashPickup)
	self.currentState:onEquipped()
end

function TrashBag.onUnequipped(self: TrashBagTypes.TrashBag)
	self.currentState:onUnequipped()
end

function TrashBag.onInventoryCleared(self: TrashBagTypes.TrashBag, reason: InventoryTypes.ClearReason)
	-- Переиспользуем штатный переход "на землю": он сам решает, можно ли
	-- разместить пакет (PartUtils.CanPlace) и снимает его с владельца.
	if self.owner then
		self:switchState(self.allStates.onGround)
	end
end

function TrashBag.handleInputStart(self: TrashBagTypes.TrashBag, context: InputSystemTypes.InputContext)
	self.currentState:handleInputStart(context)
end

function TrashBag.handleInputEnd(self: TrashBagTypes.TrashBag, context: InputSystemTypes.InputContext)
	self.currentState:handleInputEnd(context)
end

function TrashBag.handleInputSwitch(self: TrashBagTypes.TrashBag, context: InputSystemTypes.InputContext)
	self.currentState:handleInputSwitch(context)
end

function TrashBag.canHandleInput(self: TrashBagTypes.TrashBag, context: InputSystemTypes.InputContext): boolean
	return self.currentState:canHandleInput(context)
end

return TrashBag
