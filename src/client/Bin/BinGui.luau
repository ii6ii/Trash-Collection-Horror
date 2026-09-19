--!strict

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")

local BinInteraction = require(script.Parent.BinInteraction)
local InventoryGui = require(script.Parent.Parent.Inventory.InventoryGui)
local BinNetworker = require(script.Parent.BinNetworker)

local player = Players.LocalPlayer

local BinGui = {}

local currentBin: Model?
local carryingBin = false
local droppingBin = false

local MAX_RAY_DISTANCE = 1000

local DROP_BIN_ACTION = "DropBinOnJump"
local DROP_BIN_PRIORITY = 3000

local playerGui = player:WaitForChild("PlayerGui")
local mainGui = playerGui:WaitForChild("MainGui") :: ScreenGui

local gui = mainGui:WaitForChild("Bottom"):WaitForChild("BinGui") :: Frame

local putButton = gui:WaitForChild("PutButton") :: ImageButton
local closeButton = gui:WaitForChild("CloseButton") :: ImageButton

local function setJumpEnabled(enabled: boolean): ()
	local character = player.Character
	if not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, enabled)

	if not enabled then
		humanoid.Jump = false
	end
end

local function raycastFromScreenPosition(screenPosition: Vector2): RaycastResult?
	local camera = workspace.CurrentCamera

	if not camera then
		return nil
	end

	local ray = camera:ScreenPointToRay(screenPosition.X, screenPosition.Y)

	return workspace:Raycast(ray.Origin, ray.Direction * MAX_RAY_DISTANCE)
end

local function finishDrop(): ()
	droppingBin = false

	ContextActionService:UnbindAction(DROP_BIN_ACTION)

	local character = player.Character

	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")

		if humanoid then
			-- На всякий случай поглощаем оставшийся Jump.
			humanoid.Jump = false

			-- Возвращаем обычный прыжок только после
			-- завершения первого нажатия.
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
		end
	end
end

local function dropBin(): ()
	if not carryingBin or droppingBin then
		return
	end

	local bin = currentBin

	if not bin then
		return
	end

	droppingBin = true
	carryingBin = false
	currentBin = nil

	-- Сервер отпускает физический Bin.
	BinNetworker.dropBin(bin)

	-- GUI сразу возвращаем в обычное состояние.
	putButton.Visible = true
	closeButton.Visible = true
	gui.Visible = false

	BinInteraction.exit()

	-- ВАЖНО:
	-- Jumping пока НЕ включаем.
	-- Текущее нажатие должно полностью закончиться.
end

local function onDropBinAction(
	_actionName: string,
	inputState: Enum.UserInputState,
	_inputObject: InputObject
): Enum.ContextActionResult
	if not carryingBin and not droppingBin then
		return Enum.ContextActionResult.Pass
	end

	if inputState == Enum.UserInputState.Begin then
		if carryingBin then
			dropBin()
		end

		-- Поглощаем первое нажатие.
		return Enum.ContextActionResult.Sink
	end

	if inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then
		if droppingBin then
			finishDrop()
		end

		return Enum.ContextActionResult.Sink
	end

	return Enum.ContextActionResult.Sink
end

function BinGui.show(bin: Model): ()
	currentBin = bin
	carryingBin = false
	droppingBin = false

	putButton.Visible = true
	closeButton.Visible = true

	gui.Visible = true
end

function BinGui.pickUp(bin: Model): ()
	currentBin = bin
	carryingBin = true
	droppingBin = false

	putButton.Visible = false
	closeButton.Visible = false

	gui.Visible = true

	setJumpEnabled(false)

	ContextActionService:UnbindAction(DROP_BIN_ACTION)

	ContextActionService:BindActionAtPriority(
		DROP_BIN_ACTION,
		onDropBinAction,
		false,
		DROP_BIN_PRIORITY,
		Enum.PlayerActions.CharacterJump
	)
end

function BinGui.hide(): ()
	ContextActionService:UnbindAction(DROP_BIN_ACTION)

	currentBin = nil
	carryingBin = false
	droppingBin = false

	putButton.Visible = true
	closeButton.Visible = true

	setJumpEnabled(true)

	gui.Visible = false
end

function BinGui.isCarryingBin(): boolean
	return carryingBin
end

function BinGui.getCurrentBin(): Model?
	return currentBin
end

function BinGui.init(): ()
	putButton.MouseButton1Click:Connect(function()
		if carryingBin then
			return
		end

		local bin = currentBin
		local selectedSlot = InventoryGui.getSelectedId()

		if not bin or not selectedSlot then
			return
		end

		BinNetworker.putItemInBin(bin, selectedSlot)

		InventoryGui.resetSelectedSlot()
	end)

	closeButton.MouseButton1Click:Connect(function()
		if carryingBin then
			return
		end

		BinInteraction.exit()
		BinGui.hide()
	end)

	UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessedEvent: boolean)
		if gameProcessedEvent then
			return
		end

		if carryingBin or droppingBin then
			return
		end

		if
			input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch
		then
			return
		end

		local bin = currentBin

		if not bin then
			return
		end

		local result = raycastFromScreenPosition(Vector2.new(input.Position.X, input.Position.Y))

		if not result then
			return
		end

		local itemInstance = result.Instance.Parent

		if not itemInstance then
			return
		end

		BinNetworker.takeItemFromBin(bin, itemInstance)
	end)

	BinGui.hide()
end

return BinGui
