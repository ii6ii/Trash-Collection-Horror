--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ZonePlus = require(ReplicatedStorage.Packages.ZonePlus)
local InventoryTypes = require(ReplicatedStorage.Shared.Inventroy.InventoryTypes)

local Inventory = require(ServerScriptService.Server.Inventory.Inventory)
local CharacterAnimator = require(ServerScriptService.Server.Animator.CharacterAnimator)
local MovementController = require(ServerScriptService.Server.Movment.MovementController)

local BinRegistry = require(script.Parent.BinRegistry)

local ItemBin = {}
ItemBin.__index = ItemBin

local OFFSET_X = 0.3
local OFFSET_Y_MIN = 0
local OFFSET_Y_MAX = 0.2
local OFFSET_Z = 0.3

local ROTATION_X = 20
local ROTATION_Y = 360
local ROTATION_Z = 20

local PUSH_OFFSET = Vector3.new(0, -1, -3)
local PUSH_ROTATION = Vector3.new(0, -90, 0)

local GROUND_RAY_DISTANCE = 1000
local GROUND_OFFSET = 0.01

-- Локальный оффсет относительно HumanoidRootPart игрока.
-- -Z = вперёд, +X = вправо, +Y = вверх.
local DROP_OFFSET = Vector3.new(0, 0, -2)

export type BinModel = Model & {
	Model: Model & {
		PushZone: Part,
	},
	CameraPosition: BasePart,
	ItemSpawnPosition: BasePart,
	Zone: Part,
	BillboardGui: BillboardGui,
}

export type ItemBin = typeof(setmetatable(
	{} :: {
		model: BinModel,
		items: { InventoryTypes.Item },

		zone: any,
		pushZone: any,

		trashAmount: number,
		trashGoal: number,

		pushWeld: WeldConstraint?,
		pushingPlayer: Player?,

		originalPartProperties: {
			[BasePart]: {
				Anchored: boolean,
				CanCollide: boolean,
				CanTouch: boolean,
				CanQuery: boolean,
				Massless: boolean,
			},
		}?,
	},
	ItemBin
))

function ItemBin.new(model: BinModel, trashGoal: number): ItemBin
	local self = setmetatable({
		model = model,
		items = {},

		zone = ZonePlus.new(model.Zone),
		pushZone = ZonePlus.new(model.Model.PushZone),

		trashAmount = 0,
		trashGoal = trashGoal,

		pushWeld = nil,
		pushingPlayer = nil,

		originalPartProperties = nil,
	}, ItemBin)

	self.pushZone.playerEntered:Connect(function(player: Player)
		self:attachToPlayer(player)
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
	local gui = self.model.BillboardGui
	local progressBar = gui.ProgressBar

	local filler = progressBar.Filler
	local gradient = filler.UIGradient
	local progressText = progressBar.ProgressText
	local grabText = gui.GrabText

	local progress = if self.trashGoal > 0 then math.clamp(self.trashAmount / self.trashGoal, 0, 1) else 1

	if progress == 0 then
		gradient.Transparency = NumberSequence.new(1)
	elseif progress == 1 then
		gradient.Transparency = NumberSequence.new(0)
	else
		gradient.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(progress, 0),
			NumberSequenceKeypoint.new(progress, 1),
			NumberSequenceKeypoint.new(1, 1),
		})
	end

	progressText.Text = `{self.trashAmount}/{self.trashGoal}`

	if self.trashAmount < self.trashGoal then
		progressText.Text ..= " 🔒"
	end

	local full = self:isFull()

	for _, object in gui:GetDescendants() do
		if object:IsA("GuiObject") then
			object.Visible = not full
		end
	end

	grabText.Visible = full
end

function ItemBin.attachToPlayer(self: ItemBin, player: Player): ()
	if not self:isFull() or self.pushWeld then
		return
	end

	local character = player.Character

	if not character then
		return
	end

	local root = character:FindFirstChild("HumanoidRootPart")

	if not root or not root:IsA("BasePart") then
		return
	end

	local binModel = self.model.Model
	local primaryPart = binModel.PrimaryPart

	if not primaryPart then
		warn(`{binModel:GetFullName()} has no PrimaryPart`)
		return
	end

	self.originalPartProperties = {}

	for _, part in binModel:GetDescendants() do
		if part:IsA("BasePart") then
			self.originalPartProperties[part] = {
				Anchored = part.Anchored,
				CanCollide = part.CanCollide,
				CanTouch = part.CanTouch,
				CanQuery = part.CanQuery,
				Massless = part.Massless,
			}

			part.Anchored = false
			part.CanCollide = false
			part.CanTouch = false
			part.CanQuery = false
			part.Massless = true
		end
	end

	binModel:PivotTo(
		root.CFrame
			* CFrame.new(PUSH_OFFSET)
			* CFrame.Angles(math.rad(PUSH_ROTATION.X), math.rad(PUSH_ROTATION.Y), math.rad(PUSH_ROTATION.Z))
	)

	local weld = Instance.new("WeldConstraint")
	weld.Name = "BinPlayerWeld"
	weld.Part0 = root
	weld.Part1 = primaryPart
	weld.Parent = primaryPart

	self.pushWeld = weld
	self.pushingPlayer = player

	-- Отключаем BillboardGui самого бина.
	self.model.BillboardGui.Enabled = false

	MovementController.getMovement(player):setBin(true)

	CharacterAnimator.HoldRightHand(player)
	CharacterAnimator.HoldLeftHand(player)

	BinRegistry.NotifyPickedUp(player, self.model)
end

function ItemBin.detachFromPlayer(self: ItemBin): ()
	local player = self.pushingPlayer

	if self.pushWeld then
		self.pushWeld:Destroy()
		self.pushWeld = nil
	end

	if player then
		MovementController.getMovement(player):setBin(false)
		CharacterAnimator.StopHandAnimations(player)
	end

	self.pushingPlayer = nil
end

function ItemBin.drop(self: ItemBin, player: Player): boolean
	if self.pushingPlayer ~= player then
		return false
	end

	local binModel = self.model.Model
	local character = player.Character

	self:detachFromPlayer()

	-- Возвращаем BillboardGui.
	self.model.BillboardGui.Enabled = true

	-- Все части временно закрепляем.
	for _, part in binModel:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = true
		end
	end

	-- Выравниваем Bin, сохраняя только Y-поворот.
	local pivot = binModel:GetPivot()
	local _, y = pivot:ToOrientation()

	binModel:PivotTo(CFrame.new(pivot.Position) * CFrame.Angles(0, y, 0))

	-- DROP_OFFSET относительно HumanoidRootPart.
	local worldDropOffset = Vector3.zero

	local root = character and character:FindFirstChild("HumanoidRootPart")

	if root and root:IsA("BasePart") then
		worldDropOffset = root.CFrame:VectorToWorldSpace(DROP_OFFSET)
	end

	binModel:PivotTo(binModel:GetPivot() + worldDropOffset)

	-- Ищем поверхность.
	local boxCFrame, boxSize = binModel:GetBoundingBox()

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = {
		self.model,
		character,
	}

	for _, item in self.items do
		table.insert(raycastParams.FilterDescendantsInstances, item:getItemData().instance)
	end

	local rayOrigin = boxCFrame.Position + Vector3.new(0, boxSize.Y / 2 + 1, 0)

	local result = workspace:Raycast(rayOrigin, Vector3.new(0, -GROUND_RAY_DISTANCE, 0), raycastParams)

	if result then
		local bottomY = boxCFrame.Position.Y - boxSize.Y / 2

		local offsetY = result.Position.Y - bottomY + GROUND_OFFSET

		binModel:PivotTo(binModel:GetPivot() + Vector3.new(0, offsetY, 0))
	end

	-- Возвращаем исходные свойства частей.
	if self.originalPartProperties then
		for part, properties in self.originalPartProperties do
			if part.Parent then
				part.Anchored = properties.Anchored
				part.CanCollide = properties.CanCollide
				part.CanTouch = properties.CanTouch
				part.CanQuery = properties.CanQuery
				part.Massless = properties.Massless
			end
		end
	end

	self.originalPartProperties = nil

	-- На всякий случай повторно включаем GUI
	-- и обновляем его содержимое.
	self.model.BillboardGui.Enabled = true
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
	self:detachFromPlayer()

	table.clear(self.items)

	self.zone:destroy()
	self.pushZone:destroy()
end

return ItemBin
