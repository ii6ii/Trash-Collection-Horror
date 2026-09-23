--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ZonePlus = require(ReplicatedStorage.Shared.Utils.TypedZone)
local InventoryTypes = require(ReplicatedStorage.Shared.Types.InventoryTypes)
local BinConfig = require(ReplicatedStorage.Shared.Config.BinConfig)

local Inventory = require(ServerScriptService.Server.Features.Inventory.Inventory)
local CharacterAnimator = require(ServerScriptService.Server.Core.Animator.CharacterAnimator)
local MovementController = require(ServerScriptService.Server.Core.Movement.MovementController)

local BinCarryRig = require(script.Parent.BinCarryRig)
local BinGuiView = require(script.Parent.BinGuiView)
local BinRegistry = require(script.Parent.BinRegistry)

local ItemBin = {}
ItemBin.__index = ItemBin

local OFFSET_X = BinConfig.ItemScatterOffsetX
local OFFSET_Y_MIN = BinConfig.ItemScatterOffsetYMin
local OFFSET_Y_MAX = BinConfig.ItemScatterOffsetYMax
local OFFSET_Z = BinConfig.ItemScatterOffsetZ

local ROTATION_X = BinConfig.ItemScatterRotationX
local ROTATION_Y = BinConfig.ItemScatterRotationY
local ROTATION_Z = BinConfig.ItemScatterRotationZ

-- BinGuiView.BinGuiModel уже несёт полную вложенную структуру BillboardGui
-- (ProgressBar/Filler/UIGradient/ProgressText/GrabText) - пересечение вместо
-- повторного объявления той же иерархии здесь.
export type BinModel = BinCarryRig.BinModel & BinGuiView.BinGuiModel & {
	Model: Model & {
		PushZone: Part,
	},
	CameraPosition: BasePart,
	ItemSpawnPosition: BasePart,
	Zone: Part,
}

export type ItemBin = typeof(setmetatable(
	{} :: {
		model: BinModel,
		items: { InventoryTypes.Item },

		zone: ZonePlus.Zone,
		pushZone: ZonePlus.Zone,
		carryRig: BinCarryRig.BinCarryRig,

		trashAmount: number,
		trashGoal: number,
	},
	ItemBin
))

function ItemBin.new(model: BinModel, trashGoal: number): ItemBin
	local self = setmetatable({
		model = model,
		items = {},

		zone = ZonePlus.new(model.Zone),
		pushZone = ZonePlus.new(model.Model.PushZone),
		carryRig = BinCarryRig.new(model),

		trashAmount = 0,
		trashGoal = trashGoal,
	}, ItemBin)

	self.pushZone.playerEntered:Connect(function(player: Player)
		self:tryAttachToPlayer(player)
	end)

	self:updateGui()

	return self
end

function ItemBin.addItem(self: ItemBin, player: Player, item: InventoryTypes.Item): boolean
	if not self:canAddItem(item) then
		return false
	end

	local inventory = Inventory.getPlayerInventory(player)

	if not inventory or not inventory:removeItem(item) then
		return false
	end

	local instance = item:getItemData().instance

	table.insert(self.items, item)
	self.trashAmount += self:getTrashAmount(item)

	local spawn = self.model.ItemSpawnPosition

	instance:PivotTo(
		spawn.CFrame
			* CFrame.new(
				math.random(-OFFSET_X * 100, OFFSET_X * 100) / 100,
				math.random(OFFSET_Y_MIN * 100, OFFSET_Y_MAX * 100) / 100,
				math.random(-OFFSET_Z * 100, OFFSET_Z * 100) / 100
			)
			* CFrame.Angles(
				math.rad(math.random(-ROTATION_X, ROTATION_X)),
				math.rad(math.random(0, ROTATION_Y)),
				math.rad(math.random(-ROTATION_Z, ROTATION_Z))
			)
	)

	for _, part in instance:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = false
			part.CanCollide = true
		end
	end

	self:onItemAdded(item)
	self:updateGui()

	return true
end

function ItemBin.removeItem(self: ItemBin, player: Player, item: InventoryTypes.Item): boolean
	if self:isFull() then
		return false
	end

	local index = table.find(self.items, item)

	if not index then
		return false
	end

	local inventory = Inventory.getPlayerInventory(player)

	if not inventory or not inventory:addItem(item) then
		return false
	end

	table.remove(self.items, index)
	self.trashAmount -= self:getTrashAmount(item)

	self:onItemRemoved(item)
	self:updateGui()

	return true
end

function ItemBin.getTrashAmount(self: ItemBin, item: InventoryTypes.Item): number
	return 1
end

function ItemBin.onItemAdded(self: ItemBin, item: InventoryTypes.Item): () end

function ItemBin.onItemRemoved(self: ItemBin, item: InventoryTypes.Item): () end

function ItemBin.isFull(self: ItemBin): boolean
	return self.trashAmount >= self.trashGoal
end

function ItemBin.canAddItem(self: ItemBin, item: InventoryTypes.Item): boolean
	return not self:isFull()
end

function ItemBin.updateGui(self: ItemBin): ()
	BinGuiView.render(self.model, self.trashAmount, self.trashGoal)
end

function ItemBin.tryAttachToPlayer(self: ItemBin, player: Player): boolean
	if not self:isFull() or self.carryRig:isCarried() then
		return false
	end

	if not self.carryRig:attachToPlayer(player) then
		return false
	end

	MovementController.getMovement(player):setBin(true)

	CharacterAnimator.HoldRightHand(player)
	CharacterAnimator.HoldLeftHand(player)

	BinRegistry.PickedUp:Fire(player, self.model)

	return true
end

function ItemBin.drop(self: ItemBin, player: Player): boolean
	if self.carryRig:getCarrier() ~= player then
		return false
	end

	MovementController.getMovement(player):setBin(false)
	CharacterAnimator.StopHandAnimations(player)

	local itemInstances: { Instance } = {}
	for _, item in self.items do
		table.insert(itemInstances, item:getItemData().instance)
	end

	self.carryRig:drop(itemInstances)
	self:updateGui()

	return true
end

function ItemBin.getItems(self: ItemBin): { InventoryTypes.Item }
	return self.items
end

function ItemBin.getViewModel(self: ItemBin): Model
	return self.model.Model
end

function ItemBin.getOpenCameraPosition(self: ItemBin): BasePart
	return self.model.CameraPosition
end

function ItemBin.getItemSpawnPosition(self: ItemBin): BasePart
	return self.model.ItemSpawnPosition
end

function ItemBin.playerInZone(self: ItemBin, player: Player): boolean
	return self.zone:findPlayer(player)
end

function ItemBin.destroy(self: ItemBin): ()
	self.carryRig:destroy()

	table.clear(self.items)

	self.zone:destroy()
	self.pushZone:destroy()
end

return ItemBin
