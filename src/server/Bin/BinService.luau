--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Inventory = require(ServerScriptService.Server.Inventory.Inventory)

local BinRegistry = require(script.Parent.BinRegistry)
local ItemBin = require(script.Parent.ItemBin)

local Networker = require(ReplicatedStorage.Packages.Networker).server

local BinService = {}

function BinService.init() end

function BinService:putItemInBin(player: Player, binInstance: Instance, inventorySlot: number)
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

	bin:addItem(player, item)
end

function BinService:takeItemFromBin(player: Player, binInstance: Instance, itemInstance: Instance)
	local bin = BinRegistry.Get(binInstance) :: ItemBin.ItemBin?

	if not bin then
		return
	end

	local items = bin:getItems()

	for _, item in items do
		local itemData = item:getItemData()

		if itemData.instance == itemInstance then
			bin:removeItem(player, item)
			return
		end
	end
end

local networker = Networker.new("BinService", BinService, {
	BinService.putItemInBin,
	BinService.takeItemFromBin,
})

return BinService
