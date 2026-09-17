--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local GoodSignal = require(ReplicatedStorage.Packages.GoodSignal)

local TrashBagTypes = require(ServerScriptService.Server.UsableItems.TrashBag.TrashBagTypes)

local TIE_DURATION = 1

export type BagData = {
	tieFinished: GoodSignal.Signal<>,
	untieFinished: GoodSignal.Signal<>,
	bag: TrashBagTypes.TrashBag,
}

local allTyingTrashBags: { TrashBagTypes.TrashBag } = {}
local allUntyingTrashBags: { TrashBagTypes.TrashBag } = {}
local allBagDatas: { [TrashBagTypes.TrashBag]: BagData } = {}

local TrashBagTyer = {}

local function removeBagFromList(list: { TrashBagTypes.TrashBag }, bag: TrashBagTypes.TrashBag): ()
	local index = table.find(list, bag)

	if index then
		table.remove(list, index)
	end
end

function TrashBagTyer.tie(bag: TrashBagTypes.TrashBag): ()
	if not allBagDatas[bag] then
		return
	end
	removeBagFromList(allUntyingTrashBags, bag)

	if not table.find(allTyingTrashBags, bag) then
		table.insert(allTyingTrashBags, bag)
	end
end

function TrashBagTyer.untie(bag: TrashBagTypes.TrashBag): ()
	if not allBagDatas[bag] then
		return
	end
	removeBagFromList(allTyingTrashBags, bag)

	if not table.find(allUntyingTrashBags, bag) then
		table.insert(allUntyingTrashBags, bag)
	end
end

function TrashBagTyer.addBag(bag: TrashBagTypes.TrashBag): ()
	if allBagDatas[bag] then
		return
	end

	allBagDatas[bag] = {
		tieFinished = GoodSignal.new(),
		untieFinished = GoodSignal.new(),
		bag = bag,
	}
end

function TrashBagTyer.removeBag(bag: TrashBagTypes.TrashBag): ()
	allBagDatas[bag] = nil

	removeBagFromList(allTyingTrashBags, bag)
	removeBagFromList(allUntyingTrashBags, bag)
end

function TrashBagTyer.getData(bag: TrashBagTypes.TrashBag): BagData
	return allBagDatas[bag]
end

RunService.Heartbeat:Connect(function(deltaTime: number)
	deltaTime = deltaTime / TIE_DURATION
	for _, bag in allTyingTrashBags do
		bag.tieProgress = math.clamp(bag.tieProgress + deltaTime, 0, 1)

		if bag.tieProgress >= 1 then
			removeBagFromList(allTyingTrashBags, bag)
			allBagDatas[bag].tieFinished:Fire()
		end
	end

	for _, bag in allUntyingTrashBags do
		bag.tieProgress = math.clamp(bag.tieProgress - deltaTime, 0, 1)

		if bag.tieProgress <= 0 then
			removeBagFromList(allUntyingTrashBags, bag)
			allBagDatas[bag].untieFinished:Fire()
		end
	end
end)

return TrashBagTyer
