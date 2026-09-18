--!strict

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Debris = game:GetService("Debris")

local BinInteraction = require(script.Parent.BinInteraction)
local InventoryGui = require(script.Parent.Parent.Inventory.InventoryGui)
local BinNetworker = require(script.Parent.BinNetworker)

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local BinGui = {}

local currentBin: Model?

local MAX_RAY_DISTANCE = 1000
local HIT_PART_SIZE = 0.25
local HIT_PART_LIFETIME = 2

local playerGui = player:WaitForChild("PlayerGui")
local mainGui = playerGui:WaitForChild("MainGui") :: ScreenGui

local gui = mainGui:WaitForChild("Bottom"):WaitForChild("BinGui") :: Frame

local putButton = gui:WaitForChild("PutButton") :: ImageButton
local closeButton = gui:WaitForChild("CloseButton") :: ImageButton

local function raycastFromScreenPosition(screenPosition: Vector2): RaycastResult?
	local ray = camera:ScreenPointToRay(screenPosition.X, screenPosition.Y)

	return workspace:Raycast(ray.Origin, ray.Direction * MAX_RAY_DISTANCE)
end

local function spawnHitPart(position: Vector3): ()
	local part = Instance.new("Part")

	part.Name = "RaycastHit"
	part.Size = Vector3.new(HIT_PART_SIZE, HIT_PART_SIZE, HIT_PART_SIZE)

	part.CFrame = CFrame.new(position)

	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false

	part.Parent = workspace

	Debris:AddItem(part, HIT_PART_LIFETIME)
end

function BinGui.show(bin: Model): ()
	currentBin = bin
	gui.Visible = true
end

function BinGui.getCurrentBin(): Model?
	return currentBin
end

function BinGui.hide(): ()
	currentBin = nil
	gui.Visible = false
end

function BinGui.init(): ()
	putButton.MouseButton1Click:Connect(function()
		local selectedSlot = InventoryGui.getSelectedId()

		print("PUT PRESSED", currentBin, selectedSlot)

		if not currentBin or not selectedSlot then
			return
		end

		BinNetworker.putItemInBin(currentBin, selectedSlot)

		InventoryGui.resetSelectedSlot()
	end)

	closeButton.MouseButton1Click:Connect(function()
		BinInteraction.exit()
		BinGui.hide()
	end)

	UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessedEvent: boolean)
		if gameProcessedEvent then
			return
		end

		if
			input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch
		then
			return
		end

		if not currentBin then
			return
		end

		local result = raycastFromScreenPosition(Vector2.new(input.Position.X, input.Position.Y))

		if not result then
			return
		end

		print("BIN CLICK HIT:", result.Instance:GetFullName())

		print("HIT POSITION:", result.Position)

		-- Тестовая точка попадания
		--spawnHitPart(result.Position)

		-- Пока передаём Parent объекта,
		-- как у тебя было раньше.
		local itemInstance = result.Instance.Parent

		if not itemInstance then
			return
		end

		BinNetworker.takeItemFromBin(currentBin, itemInstance)
	end)

	BinGui.hide()
end

return BinGui
