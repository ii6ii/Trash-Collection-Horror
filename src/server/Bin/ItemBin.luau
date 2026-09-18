--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ZonePlus = require(ReplicatedStorage.Packages.ZonePlus)
local InventoryTypes = require(ReplicatedStorage.Shared.Inventroy.InventoryTypes)

local Inventory = require(ServerScriptService.Server.Inventory.Inventory)

local ItemBin = {}
ItemBin.__index = ItemBin

local OFFSET_X = 0.3
local OFFSET_Y_MIN = 0
local OFFSET_Y_MAX = 0.2
local OFFSET_Z = 0.3

local ROTATION_X = 20
local ROTATION_Y = 360
local ROTATION_Z = 20

export type BinModel = Model & {
	Model: Model,
	CameraPosition: BasePart,
	ItemSpawnPosition: BasePart,
	Zone: Part,
}

export type ItemBin = typeof(setmetatable(
	{} :: {
		model: BinModel,
		items: { InventoryTypes.Item },
		zone: any,
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
		trashAmount = 0,
		trashGoal = trashGoal,
	}, ItemBin)

	self:updateGui()

	return self
end

function ItemBin.addItem(self: ItemBin, player: Player, item: InventoryTypes.Item): boolean
	if not self:canAddItem(item) then
		return false
	end

	local inventory = Inventory.getPlayerInventory(player)

	if not inventory then
		return false
	end

	local itemData = item:getItemData()
	local instance = itemData.instance

	-- Сначала убираем предмет из инвентаря.
	-- После этого персонаж больше не держит предмет.
	local removedFromInventory = inventory:removeItem(item)

	if not removedFromInventory then
		return false
	end

	table.insert(self.items, item)

	self.trashAmount += self:getTrashAmount(item)

	local spawnPosition = self.model.ItemSpawnPosition

	local offset = Vector3.new(
		math.random(-OFFSET_X * 100, OFFSET_X * 100) / 100,
		math.random(OFFSET_Y_MIN * 100, OFFSET_Y_MAX * 100) / 100,
		math.random(-OFFSET_Z * 100, OFFSET_Z * 100) / 100
	)

	local rotation = CFrame.Angles(
		math.rad(math.random(-ROTATION_X, ROTATION_X)),
		math.rad(math.random(0, ROTATION_Y)),
		math.rad(math.random(-ROTATION_Z, ROTATION_Z))
	)

	instance:PivotTo(spawnPosition.CFrame * CFrame.new(offset) * rotation)

	for _, descendant in instance:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = false
			descendant.CanCollide = true
		end
	end

	self:onItemAdded(item)
	self:updateGui()

	return true
end

function ItemBin.removeItem(self: ItemBin, player: Player, item: InventoryTypes.Item): boolean
	local index = table.find(self.items, item)

	if not index then
		return false
	end

	local inventory = Inventory.getPlayerInventory(player)

	if not inventory then
		return false
	end

	-- Сначала пробуем вернуть предмет в инвентарь.
	--
	-- Если инвентарь заполнен или предмет нельзя
	-- туда положить, Bin вообще не изменяется.
	if not inventory:addItem(item) then
		return false
	end

	local trashAmount = self:getTrashAmount(item)

	table.remove(self.items, index)

	self.trashAmount -= trashAmount

	self:onItemRemoved(item)
	self:updateGui()

	return true
end

function ItemBin.getTrashAmount(self: ItemBin, item: InventoryTypes.Item): number
	return 1
end

function ItemBin.onItemAdded(self: ItemBin, item: InventoryTypes.Item): ()
	-- Hook для наследников.
end

function ItemBin.onItemRemoved(self: ItemBin, item: InventoryTypes.Item): ()
	-- Hook для наследников.
end

function ItemBin.updateGui(self: ItemBin): ()
	local billboardGui = self.model:WaitForChild("BillboardGui") :: BillboardGui
	local progressBar = billboardGui:WaitForChild("ProgressBar") :: Frame

	local filler = progressBar:WaitForChild("Filler") :: Frame
	local gradient = filler:WaitForChild("UIGradient") :: UIGradient
	local progressText = progressBar:WaitForChild("ProgressText") :: TextLabel

	local have = self.trashAmount
	local need = self.trashGoal

	local progress = math.clamp(have / need, 0, 1)

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

	progressText.Text = `{have}/{need}`

	if have < need then
		progressText.Text ..= " 🔒"
	end
end

function ItemBin.canAddItem(self: ItemBin, item: InventoryTypes.Item): boolean
	return self.trashAmount < self.trashGoal
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

function ItemBin.destroy(self: ItemBin): ()
	table.clear(self.items)
	self.zone:destroy()
end

function ItemBin.playerInZone(self: ItemBin, player: Player): boolean
	return self.zone:findPlayer(player)
end

return ItemBin
