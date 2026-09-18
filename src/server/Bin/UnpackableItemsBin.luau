--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local UnpackableTrash = require(ServerScriptService.Server.UsableItems.UnpackableTrash.UnpackableTrash)

local ItemBin = require(script.Parent.ItemBin)

local InventoryTypes = require(ReplicatedStorage.Shared.Inventroy.InventoryTypes)

local UnpackableItemsBin = {}
UnpackableItemsBin.__index = UnpackableItemsBin

setmetatable(UnpackableItemsBin, ItemBin)

export type UnpackableItemsBin = typeof(setmetatable(
	{} :: {
		model: ItemBin.BinModel,
		items: { InventoryTypes.Item },
		zone: any,
		trashAmount: number,
		trashGoal: number,
	},
	UnpackableItemsBin
))

function UnpackableItemsBin.new(model: ItemBin.BinModel, trashGoal: number): UnpackableItemsBin
	local self = ItemBin.new(model, trashGoal) :: any

	setmetatable(self, UnpackableItemsBin)

	return self
end

function UnpackableItemsBin.canAddItem(self: UnpackableItemsBin, item: InventoryTypes.Item): boolean
	if not ItemBin.canAddItem(self, item) then
		return false
	end

	local itemData = item:getItemData()

	return UnpackableTrash.allTrash[itemData.instance] ~= nil
end

return UnpackableItemsBin
