--!strict

-- Тонкий оркестратор: связывает input (нажатия по слотам) с выбором слота
-- и сетевым запросом на сервер, а серверные обновления - с отрисовкой.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InventoryTypes = require(ReplicatedStorage.Shared.Types.InventoryTypes)
local InventoryConfig = require(ReplicatedStorage.Shared.Config.InventoryConfig)
local Networker = require(ReplicatedStorage.Packages.Networker).client

local InventorySlotsView = require(script.Parent.InventorySlotsView)
local InventorySelection = require(script.Parent.InventorySelection)

local InventoryGui = {}

local view: InventorySlotsView.InventorySlotsView
local selection = InventorySelection.new()
local slotData: { InventoryTypes.SlotData } = {}

local networker: any

local function canSelectSlot(id: number): boolean
	local data = slotData[id]

	return data ~= nil and not data.isLock
end

local function onSlotPressed(id: number): ()
	local selectedId = selection:get()

	if not selectedId then
		if canSelectSlot(id) then
			selection:select(id)
			view:applySelection(selection:get())
		end

		return
	end

	if not canSelectSlot(id) then
		return
	end

	local fromId = selectedId
	local toId = id

	selection:clear()
	view:applySelection(nil)

	if fromId == toId then
		return
	end

	networker:fetch("moveItemFromClient", fromId, toId)
end

function InventoryGui.init(): ()
	networker = Networker.new("Inventory", InventoryGui)

	view = InventorySlotsView.new()

	local inputFolder = ReplicatedStorage:WaitForChild("Input"):WaitForChild("Inventory")

	for id = 1, InventoryConfig.TotalSlots do
		local input = inputFolder:WaitForChild(`SelectInput{id}`)

		input.Pressed:Connect(function()
			onSlotPressed(id)
		end)
	end

	local emptySlotData: { InventoryTypes.SlotData } = {}

	for _ = 1, InventoryConfig.TotalSlots do
		table.insert(emptySlotData, { type = nil, isLock = false })
	end

	InventoryGui:UpdateGui(emptySlotData)
end

function InventoryGui:UpdateGui(newSlotData: { InventoryTypes.SlotData }): ()
	slotData = newSlotData
	view:render(slotData)
end

function InventoryGui.getSelectedId(): number?
	return selection:get()
end

function InventoryGui.resetSelectedSlot(): ()
	selection:clear()
	view:applySelection(nil)
end

return InventoryGui
