--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Inventory = require(ServerScriptService.Server.Features.Inventory.Inventory)

local BinRegistry = require(script.Parent.BinRegistry)

local Networker = require(ReplicatedStorage.Packages.Networker).server

local BinService = {}

local networker: any

function BinService.init(): ()
	networker = Networker.new("BinService")
	-- :: any на каждом элементе: putItemInBin/takeItemFromBin/dropBin имеют
	-- разную арность и типы параметров, и Luau пытается свести литерал массива
	-- к одной сигнатуре при выводе типа - без cast'а это падает ещё до проверки
	-- совместимости с {any} в addClientAccess.
	networker:addClientAccess(BinService, {
		BinService.putItemInBin :: any,
		BinService.takeItemFromBin :: any,
		BinService.dropBin :: any,
	})

	BinRegistry.PickedUp:Connect(function(player: Player, bin: Model)
		networker:fire(player, "binPickedUp", bin.Name)
	end)
end

-- Игрок должен физически стоять в зоне бина - иначе клиент мог бы прислать
-- instance произвольного бина без реального взаимодействия с ним.
function BinService:putItemInBin(player: Player, binInstance: Instance, inventorySlot: number): ()
	local bin = BinRegistry.Get(binInstance)

	if not bin or not bin:playerInZone(player) then
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
		networker:fire(player, "binFilled", binInstance.Name)
	end
end

function BinService:takeItemFromBin(player: Player, binInstance: Instance, itemInstance: Instance): ()
	local bin = BinRegistry.Get(binInstance)

	if not bin or not bin:playerInZone(player) then
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
	local bin = BinRegistry.Get(binInstance)

	if not bin then
		return
	end

	bin:drop(player)
end

return BinService
