--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Networker = require(ReplicatedStorage.Packages.Networker).server
local TrashBagConfig = require(ReplicatedStorage.Shared.Config.TrashBagConfig)

local TrashBag = require(script.Parent.TrashBag)

local TrashBagGiver = {}

local TRASH_PER_BAG = TrashBagConfig.TrashPerBag
local BAG_DISTANCE = TrashBagConfig.BagDistance

type GiverState = {
	trashAmount: number,
	bagCapacity: number,

	direction: Vector3,

	bagsFolder: Folder,
	spawnPart: BasePart,
	bagTemplate: Model,

	bags: { [number]: Model },
}

local state: GiverState?

local function getState(): GiverState
	assert(state, "TrashBagGiver is not initialized")

	return state
end

local function getBagCount(): number
	local currentState = getState()

	local count = 0

	for slot, bag in currentState.bags do
		if bag.Parent ~= currentState.bagsFolder then
			currentState.bags[slot] = nil
		else
			count += 1
		end
	end

	return count
end

local function updateBagAttributes(): ()
	local currentState = getState()

	local kitchen = workspace:WaitForChild("Kitchen")

	kitchen:SetAttribute("TrashBagCount", getBagCount())

	kitchen:SetAttribute("TrashBagCapacity", currentState.bagCapacity)
end

local function setupPlayerGui(player: Player): ()
	local playerGui = player:WaitForChild("PlayerGui")

	local guiFolder = ReplicatedStorage:WaitForChild("Gui")

	local guiTemplate = guiFolder:WaitForChild("BillboardGui")

	if not guiTemplate:IsA("BillboardGui") then
		warn("TrashBagGiver: ReplicatedStorage.Gui.BillboardGui must be a BillboardGui")

		return
	end

	local oldGui = playerGui:FindFirstChild("BillboardGui")

	if oldGui then
		oldGui:Destroy()
	end

	-- Клонируем ТОЛЬКО BillboardGui.
	local gui = guiTemplate:Clone()

	gui.Parent = playerGui
end

local function getFreeSlot(): number
	local currentState = getState()

	local slot = 1

	while currentState.bags[slot] ~= nil do
		slot += 1
	end

	return slot
end

local function getSpawnPosition(slot: number): Vector3
	local currentState = getState()

	local offset = currentState.direction * ((slot - 1) * BAG_DISTANCE)

	return currentState.spawnPart.CFrame:PointToWorldSpace(offset)
end

local function createBag(slot: number): Model
	local currentState = getState()

	local bag = currentState.bagTemplate:Clone()

	bag.Name = string.format("TrashBag%d", slot)

	-- Сохраняем оригинальную ротацию шаблона.
	local originalPivot = bag:GetPivot()

	local position = getSpawnPosition(slot)

	bag:PivotTo(CFrame.new(position) * originalPivot.Rotation)

	bag.Parent = currentState.bagsFolder

	TrashBag.new(bag)

	currentState.bags[slot] = bag

	-- Следим за удалением мешка.
	bag.AncestryChanged:Connect(function()
		if bag.Parent == currentState.bagsFolder then
			return
		end

		if currentState.bags[slot] ~= bag then
			return
		end

		currentState.bags[slot] = nil

		updateBagAttributes()
	end)

	return bag
end

function TrashBagGiver:addOne(player: Player): boolean
	-- Нельзя покупать, пока есть хотя бы
	-- один существующий мешок.
	if getBagCount() > 0 then
		return false
	end

	local slot = getFreeSlot()

	createBag(slot)

	updateBagAttributes()

	return true
end

function TrashBagGiver:addMax(player: Player): boolean
	local currentState = getState()

	-- Нельзя покупать, пока есть хотя бы
	-- один существующий мешок.
	if getBagCount() > 0 then
		return false
	end

	-- Создаём ровно bagCapacity мешков.
	for slot = 1, currentState.bagCapacity do
		if currentState.bags[slot] == nil then
			createBag(slot)
		end
	end

	updateBagAttributes()

	return true
end

function TrashBagGiver.init(trashAmount: number, direction: Vector3): ()
	if state then
		warn("TrashBagGiver.init() has already been called")

		return
	end

	local kitchen = workspace:WaitForChild("Kitchen")

	local bagsFolder = kitchen:WaitForChild("Bags") :: Folder

	local spawnPart = kitchen:WaitForChild("BagsSpawnPart") :: BasePart

	local bagTemplate = ServerStorage:WaitForChild("Models"):WaitForChild("TrashBag") :: Model

	local bagCapacity = math.ceil(trashAmount / TRASH_PER_BAG) + 1

	state = {
		trashAmount = trashAmount,
		bagCapacity = bagCapacity,

		direction = direction,

		bagsFolder = bagsFolder,
		spawnPart = spawnPart,
		bagTemplate = bagTemplate,

		bags = {},
	}

	-- Сразу создаём полный стартовый набор.
	for slot = 1, bagCapacity do
		createBag(slot)
	end

	updateBagAttributes()

	-- Игроки, которые уже находятся на сервере.
	for _, player in Players:GetPlayers() do
		task.spawn(function()
			setupPlayerGui(player)
		end)
	end

	-- Новые игроки.
	Players.PlayerAdded:Connect(function(player: Player)
		task.spawn(function()
			setupPlayerGui(player)
		end)
	end)

	Networker.new("TrashBagGiverGUI", TrashBagGiver, {
		TrashBagGiver.addOne,
		TrashBagGiver.addMax,
	})
end

return TrashBagGiver
