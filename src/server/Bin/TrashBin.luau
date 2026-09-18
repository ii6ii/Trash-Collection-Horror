--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ItemBin = require(script.Parent.ItemBin)

local TrashBag = require(ServerScriptService.Server.UsableItems.TrashBag.TrashBag)

local InventoryTypes = require(ReplicatedStorage.Shared.Inventroy.InventoryTypes)

local TrashBin = {}
TrashBin.__index = TrashBin

setmetatable(TrashBin, ItemBin)

export type TrashBin = typeof(setmetatable(
	{} :: {
		model: ItemBin.BinModel,
		items: { InventoryTypes.Item },
		zone: any,
		trashAmount: number,
		trashGoal: number,
	},
	TrashBin
))

function TrashBin.new(model: ItemBin.BinModel, trashGoal: number): TrashBin
	local self = ItemBin.new(model, trashGoal) :: any

	setmetatable(self, TrashBin)

	return self
end

function TrashBin.canAddItem(self: TrashBin, item: InventoryTypes.Item): boolean
	if not ItemBin.canAddItem(self, item) then
		return false
	end

	local itemData = item:getItemData()

	local trashBag = TrashBag.allBags[itemData.instance]

	if not trashBag then
		return false
	end

	return trashBag.trashInside > 0
end

function TrashBin.getTrashAmount(self: TrashBin, item: InventoryTypes.Item): number
	local itemData = item:getItemData()

	local trashBag = TrashBag.allBags[itemData.instance]

	if not trashBag then
		return 0
	end

	return trashBag.trashInside
end

function TrashBin.onItemAdded(self: TrashBin, item: InventoryTypes.Item): ()
	local itemData = item:getItemData()

	local trashBag = TrashBag.allBags[itemData.instance]

	if not trashBag then
		return
	end

	self:updateBagVisuals(trashBag)
end

function TrashBin.onItemRemoved(self: TrashBin, item: InventoryTypes.Item): ()
	local itemData = item:getItemData()

	local trashBag = TrashBag.allBags[itemData.instance]

	if not trashBag then
		return
	end

	local instance = trashBag.instance

	local billboardGui = instance:FindFirstChild("BillboardGui", true) :: BillboardGui?
	local highlight = instance:FindFirstChild("Highlight", true) :: Highlight?

	if billboardGui then
		billboardGui.Enabled = false
	end

	if highlight then
		highlight.Enabled = false
	end
end

function TrashBin.updateBagVisuals(self: TrashBin, trashBag: TrashBag.TrashBag): ()
	local instance = trashBag.instance

	local billboardGui = instance:FindFirstChild("BillboardGui", true) :: BillboardGui?
	local highlight = instance:FindFirstChild("Highlight", true) :: Highlight?

	if not billboardGui or not highlight then
		return
	end

	local isFull = trashBag.trashInside >= trashBag.capacity

	billboardGui.Enabled = not isFull
	highlight.Enabled = not isFull
end

return TrashBin
