--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InventoryTypes = require(ReplicatedStorage.Shared.Inventroy.InventoryTypes)

local ItemConfig = require(ReplicatedStorage.Shared.Inventroy.ItemConfig)

local Networker = require(ReplicatedStorage.Packages.Networker).client

local player = Players.LocalPlayer

local InventoryGui = {}

local slots: { [number]: Frame } = {}
local selectStrokes: { [number]: UIStroke } = {}
local slotData: { [number]: InventoryTypes.SlotData } = {}

local networker = Networker.new("Inventory", InventoryGui)

local selectedSlot: number?

local LOCK_TRANSPARENCY = 0.7
local SLOT_COUNT = 5

local function getGui(): ()
	local playerGui = player:WaitForChild("PlayerGui")
	local mainGui = playerGui:WaitForChild("MainGui") :: ScreenGui
	local bottom = mainGui:WaitForChild("Bottom") :: Frame

	local inventoryFrame = bottom:WaitForChild("InventoryFrame"):WaitForChild("Slots") :: Frame

	slots = {
		[1] = inventoryFrame:WaitForChild("LeftHandFrame") :: Frame,
		[2] = inventoryFrame:WaitForChild("RightHandFrame") :: Frame,
		[3] = inventoryFrame:WaitForChild("BackpackFrame1") :: Frame,
		[4] = inventoryFrame:WaitForChild("BackpackFrame2") :: Frame,
		[5] = inventoryFrame:WaitForChild("BackpackFrame3") :: Frame,
	}

	for id, slot in slots do
		selectStrokes[id] = slot:WaitForChild("SelectStroke") :: UIStroke
		selectStrokes[id].Enabled = false
	end
end

local function clearSelection(): ()
	for _, stroke in selectStrokes do
		stroke.Enabled = false
	end

	selectedSlot = nil
end

local function canSelectSlot(id: number): boolean
	local data = slotData[id]

	return data ~= nil and not data.isLock
end

local function selectSlot(id: number): ()
	clearSelection()

	selectedSlot = id
	selectStrokes[id].Enabled = true
end

local function onSlotPressed(id: number): ()
	if not selectedSlot then
		if canSelectSlot(id) then
			selectSlot(id)
		end

		return
	end

	if not canSelectSlot(id) then
		return
	end

	local fromId = selectedSlot
	local toId = id

	clearSelection()

	if fromId == toId then
		return
	end

	networker:fetch("moveItemFromClient", fromId, toId)
end

function InventoryGui.init(): ()
	getGui()

	local inputFolder = ReplicatedStorage:WaitForChild("Input"):WaitForChild("Inventory")

	for id = 1, SLOT_COUNT do
		local input = inputFolder:WaitForChild(`SelectInput{id}`)

		input.Pressed:Connect(function()
			onSlotPressed(id)
		end)
	end

	InventoryGui:UpdateGui(table.create(SLOT_COUNT, {
		type = nil,
		isLock = false,
	}))
end

function InventoryGui:UpdateGui(newSlotData: { InventoryTypes.SlotData }): ()
	slotData = newSlotData
	for id = 1, SLOT_COUNT do
		local data = slotData[id]
		local slot = slots[id]

		if not data or not slot then
			continue
		end

		local icon = slot:WaitForChild("Icon") :: ImageLabel

		if not data.type then
			icon.Image = ""
			icon.ImageTransparency = 0
			continue
		end

		local config = ItemConfig[data.type]

		if not config then
			continue
		end

		icon.Image = config.image
		icon.ImageTransparency = data.isLock and LOCK_TRANSPARENCY or 0
	end
end

function InventoryGui.getSelectedId(): number?
	return selectedSlot
end

function InventoryGui.resetSelectedSlot()
	clearSelection()
end

return InventoryGui
