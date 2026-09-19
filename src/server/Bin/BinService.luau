--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Inventory = require(ServerScriptService.Server.Inventory.Inventory)

local BinRegistry = require(script.Parent.BinRegistry)
local ItemBin = require(script.Parent.ItemBin)

local Networker = require(ReplicatedStorage.Packages.Networker).server

local BinService = {}

local networker: any

function BinService.init() end

function BinService:putItemInBin(player: Player, binInstance: Instance, inventorySlot: number): ()
	local bin = BinRegistry.Get(binInstance) :: ItemBin.ItemBin?

	if not bin then
		return
	end

	local inventory = Inventory.getPlayerInventory(player)

	if not inventory then
		return
	end

	local item = inventory:getItem(inventorySlot)

	if not item then
		return
	end

	local added = bin:addItem(player, item)

	if added and bin:isFull() then
		print("SERVER: BIN FILLED", binInstance.Name)

		networker:fire(player, "binFilled", binInstance.Name)
	end
end

function BinService:takeItemFromBin(player: Player, binInstance: Instance, itemInstance: Instance): ()
	local bin = BinRegistry.Get(binInstance) :: ItemBin.ItemBin?

	if not bin then
		return
	end

	for _, item in bin:getItems() do
		if item:getItemData().instance == itemInstance then
			bin:removeItem(player, item)
			return
		end
	end
end

function BinService:dropBin(player: Player, binInstance: Instance): ()
	local bin = BinRegistry.Get(binInstance) :: ItemBin.ItemBin?

	if not bin then
		return
	end

	bin:drop(player)
end

networker = Networker.new("BinService", BinService, {
	BinService.putItemInBin,
	BinService.takeItemFromBin,
	BinService.dropBin,
})

BinRegistry.SetPickupCallback(function(player: Player, bin: Model)
	print("SERVER: BIN PICKED UP", bin.Name)

	networker:fire(player, "binPickedUp", bin.Name)
end)

return BinService
