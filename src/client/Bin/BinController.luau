--!strict

local CollectionService = game:GetService("CollectionService")

local ItemBin = require(script.Parent.ItemBin)

local BinController = {}

local UNPACKABLE_BIN_TAG = "UnpackableItemsBin"
local TRASH_BIN_TAG = "TrashBin"

local function createBin(instance: Instance)
	if not instance:IsA("Model") then
		return
	end

	ItemBin.new(instance)
end

function BinController.init(): ()
	for _, instance in CollectionService:GetTagged(UNPACKABLE_BIN_TAG) do
		createBin(instance)
	end

	CollectionService:GetInstanceAddedSignal(UNPACKABLE_BIN_TAG):Connect(createBin)

	for _, instance in CollectionService:GetTagged(TRASH_BIN_TAG) do
		createBin(instance)
	end

	CollectionService:GetInstanceAddedSignal(TRASH_BIN_TAG):Connect(createBin)
end

return BinController
