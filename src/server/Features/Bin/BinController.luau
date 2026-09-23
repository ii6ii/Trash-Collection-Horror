--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CollectionServiceUtils = require(ReplicatedStorage.Shared.Utils.CollectionServiceUtils)

local BinRegistry = require(script.Parent.BinRegistry)
local ItemBin = require(script.Parent.ItemBin)
local TrashBin = require(script.Parent.TrashBin)
local UnpackableItemsBin = require(script.Parent.UnpackableItemsBin)

local BinController = {}

local TRASH_BIN_TAG = "TrashBin"
local UNPACKABLE_BIN_TAG = "UnpackableItemsBin"

local AMOUNT_ATTRIBUTE = "OpenAmount"

local function onBinRemoved(instance: Instance): ()
	local bin = BinRegistry.Get(instance)

	if not bin then
		return
	end

	bin:destroy()
	BinRegistry.Unregister(instance)
end

local function createUnpackBin(instance: Instance)
	if not instance:IsA("Model") then
		return
	end

	local bin = UnpackableItemsBin.new(instance :: ItemBin.BinModel, instance:GetAttribute(AMOUNT_ATTRIBUTE) :: number)
	BinRegistry.Register(instance, bin :: any)
end

local function createTrashBin(instance: Instance)
	if not instance:IsA("Model") then
		return
	end

	local bin = TrashBin.new(instance :: ItemBin.BinModel, instance:GetAttribute(AMOUNT_ATTRIBUTE) :: number)
	BinRegistry.Register(instance, bin :: any)
end

function BinController.init(): ()
	CollectionServiceUtils.watchTag(UNPACKABLE_BIN_TAG, createUnpackBin, onBinRemoved)
	CollectionServiceUtils.watchTag(TRASH_BIN_TAG, createTrashBin, onBinRemoved)
end

return BinController
