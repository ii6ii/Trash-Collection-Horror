--!strict

-- Rendering-слой: находит GUI-инстансы слотов и отрисовывает присланные
-- сервером данные (иконки, замки, рамку выбора). Не занимается input'ом
-- и не хранит игровое состояние — только то, что нужно для отрисовки.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InventoryTypes = require(ReplicatedStorage.Shared.Types.InventoryTypes)
local InventoryConfig = require(ReplicatedStorage.Shared.Config.InventoryConfig)
local ItemConfig = require(ReplicatedStorage.Shared.Config.ItemConfig)

local player = Players.LocalPlayer

local InventorySlotsView = {}
InventorySlotsView.__index = InventorySlotsView

export type InventorySlotsView = typeof(setmetatable(
	{} :: {
		slots: { [number]: Frame },
		selectStrokes: { [number]: UIStroke },
	},
	InventorySlotsView
))

function InventorySlotsView.new(): InventorySlotsView
	local playerGui = player:WaitForChild("PlayerGui")
	local mainGui = playerGui:WaitForChild("MainGui") :: ScreenGui
	local bottom = mainGui:WaitForChild("Bottom") :: Frame

	local inventoryFrame = bottom:WaitForChild("InventoryFrame"):WaitForChild("Slots") :: Frame

	local slots: { [number]: Frame } = {
		[1] = inventoryFrame:WaitForChild("LeftHandFrame") :: Frame,
		[2] = inventoryFrame:WaitForChild("RightHandFrame") :: Frame,
		[3] = inventoryFrame:WaitForChild("BackpackFrame1") :: Frame,
		[4] = inventoryFrame:WaitForChild("BackpackFrame2") :: Frame,
		[5] = inventoryFrame:WaitForChild("BackpackFrame3") :: Frame,
	}

	local selectStrokes: { [number]: UIStroke } = {}

	for id, slot in slots do
		local stroke = slot:WaitForChild("SelectStroke") :: UIStroke
		stroke.Enabled = false
		selectStrokes[id] = stroke
	end

	return setmetatable({
		slots = slots,
		selectStrokes = selectStrokes,
	}, InventorySlotsView)
end

function InventorySlotsView.render(self: InventorySlotsView, slotData: { InventoryTypes.SlotData }): ()
	for id = 1, InventoryConfig.TotalSlots do
		local data = slotData[id]
		local slot = self.slots[id]

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
		icon.ImageTransparency = data.isLock and InventoryConfig.LockTransparency or 0
	end
end

function InventorySlotsView.applySelection(self: InventorySlotsView, selectedId: number?): ()
	for id, stroke in self.selectStrokes do
		stroke.Enabled = id == selectedId
	end
end

return InventorySlotsView
