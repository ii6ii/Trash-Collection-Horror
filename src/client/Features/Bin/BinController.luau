--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CollectionServiceUtils = require(ReplicatedStorage.Shared.Utils.CollectionServiceUtils)

local BinNetworker = require(script.Parent.BinNetworker)
local BinInteraction = require(script.Parent.BinInteraction)
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

local function removeBin(instance: Instance)
	local bin = ItemBin.allBins[instance :: Model]

	if not bin then
		return
	end

	bin:destroy()
end

function BinController.init(): ()
	BinNetworker.init()
	BinInteraction.init()
	ItemBin.init()

	CollectionServiceUtils.watchTag(UNPACKABLE_BIN_TAG, createBin, removeBin)
	CollectionServiceUtils.watchTag(TRASH_BIN_TAG, createBin, removeBin)
end

return BinController
