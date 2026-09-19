--!strict

local CollectionService = game:GetService("CollectionService")

local BinRegistry = require(script.Parent.BinRegistry)
local ItemBin = require(script.Parent.ItemBin)
local TrashBin = require(script.Parent.TrashBin)
local UnpackableItemsBin = require(script.Parent.UnpackableItemsBin)

local BinController = {}

local TRASH_BIN_TAG = "TrashBin"
local UNPACKABLE_BIN_TAG = "UnpackableItemsBin"

local AMOUNT_ATTRIBUTE = "OpenAmount"

local function createUnpackBin(instance: ItemBin.BinModel)
	if not instance:IsA("Model") then
		return
	end
	local bin = UnpackableItemsBin.new(instance, instance:GetAttribute(AMOUNT_ATTRIBUTE) :: number)
	BinRegistry.Register(instance, bin)
end

local function createTrashBin(instance: ItemBin.BinModel)
	if not instance:IsA("Model") then
		return
	end
	local bin = TrashBin.new(instance, instance:GetAttribute(AMOUNT_ATTRIBUTE) :: number)
	BinRegistry.Register(instance, bin)
end

function BinController.init(): ()
	for _, instance in CollectionService:GetTagged(UNPACKABLE_BIN_TAG) do
		createUnpackBin(instance)
	end

	CollectionService:GetInstanceAddedSignal(UNPACKABLE_BIN_TAG):Connect(createUnpackBin)

	for _, instance in CollectionService:GetTagged(TRASH_BIN_TAG) do
		createTrashBin(instance)
	end

	CollectionService:GetInstanceAddedSignal(TRASH_BIN_TAG):Connect(createTrashBin)
end

return BinController
