--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Networker = require(ReplicatedStorage.Packages.Networker)

local TrashBagGiverController = {}

local player = Players.LocalPlayer

local WHITE = Color3.fromRGB(255, 255, 255)
local YELLOW = Color3.fromRGB(255, 221, 0)

local BLINK_INTERVAL = 0.35

local initialized = false

local blinkConnection: RBXScriptConnection?
local blinkElapsed = 0
local blinkVisible = true

local dontHaveBagsFrame: GuiObject?
local buyMaxText: TextLabel?

local function getGui(): BillboardGui?
	local playerGui = player:FindFirstChildOfClass("PlayerGui")

	if not playerGui then
		return nil
	end

	local gui = playerGui:FindFirstChild("BillboardGui")

	if not gui then
		print("No Gui")

		return nil
	end

	if not gui:IsA("BillboardGui") then
		return nil
	end

	print("GET GUI")

	return gui
end

local function stopBlink(amountText: TextLabel): ()
	if blinkConnection then
		blinkConnection:Disconnect()
		blinkConnection = nil
	end

	blinkElapsed = 0
	blinkVisible = true

	amountText.TextColor3 = WHITE
end

local function startBlink(amountText: TextLabel): ()
	if blinkConnection then
		return
	end

	blinkElapsed = 0
	blinkVisible = true

	blinkConnection = RunService.RenderStepped:Connect(function(deltaTime: number)
		local kitchen = workspace:FindFirstChild("Kitchen")

		if not kitchen then
			return
		end

		local bagCount = kitchen:GetAttribute("TrashBagCount")

		if bagCount ~= 1 then
			stopBlink(amountText)
			return
		end

		blinkElapsed += deltaTime

		if blinkElapsed < BLINK_INTERVAL then
			return
		end

		blinkElapsed = 0
		blinkVisible = not blinkVisible

		if blinkVisible then
			amountText.TextColor3 = YELLOW
		else
			amountText.TextColor3 = WHITE
		end
	end)
end

local function updateUI(): ()
	local gui = getGui()

	if not gui then
		return
	end

	local kitchen = workspace:FindFirstChild("Kitchen")

	if not kitchen then
		return
	end

	local bagCount = kitchen:GetAttribute("TrashBagCount")
	local bagCapacity = kitchen:GetAttribute("TrashBagCapacity")

	if typeof(bagCount) ~= "number" then
		return
	end

	if typeof(bagCapacity) ~= "number" then
		return
	end

	local haveBagsFrame = gui:FindFirstChild("HaveBagsGrame")
	local currentDontHaveBagsFrame = gui:FindFirstChild("DontHaveBagsFrame")

	if not haveBagsFrame or not currentDontHaveBagsFrame then
		return
	end

	if not haveBagsFrame:IsA("GuiObject") then
		return
	end

	if not currentDontHaveBagsFrame:IsA("GuiObject") then
		return
	end

	local amountText = haveBagsFrame:FindFirstChild("BagAmountText")

	if not amountText or not amountText:IsA("TextLabel") then
		return
	end

	-- Обновляем текст BuyMax всегда.
	local currentBuyMaxText = buyMaxText

	if currentBuyMaxText then
		currentBuyMaxText.Text = string.format("buy %d more", bagCapacity)
	end

	-- ========================================
	-- Есть пакеты
	-- ========================================

	if bagCount > 0 then
		haveBagsFrame.Visible = true
		currentDontHaveBagsFrame.Visible = false

		amountText.Text = string.format("(%d/%d)", bagCount, bagCapacity)

		-- Один пакет -> мигание.
		if bagCount == 1 then
			startBlink(amountText)
		else
			stopBlink(amountText)
		end

		return
	end

	-- ========================================
	-- Пакетов нет
	-- ========================================

	haveBagsFrame.Visible = false
	currentDontHaveBagsFrame.Visible = true

	amountText.Text = string.format("(0/%d)", bagCapacity)

	stopBlink(amountText)
end

function TrashBagGiverController.init(): ()
	if initialized then
		return
	end

	initialized = true

	local networker = Networker.client.new("TrashBagGiverGUI", TrashBagGiverController)

	local playerGui = player:WaitForChild("PlayerGui")

	local gui = playerGui:WaitForChild("BillboardGui")

	if not gui:IsA("BillboardGui") then
		warn("TrashBagGiverController: PlayerGui.BillboardGui must be a BillboardGui")

		return
	end

	local currentDontHaveBagsFrame = gui:WaitForChild("DontHaveBagsFrame")

	if not currentDontHaveBagsFrame:IsA("GuiObject") then
		warn("TrashBagGiverController: DontHaveBagsFrame must be a GuiObject")

		return
	end

	dontHaveBagsFrame = currentDontHaveBagsFrame

	local buttons = currentDontHaveBagsFrame:WaitForChild("Buttons")

	local buyOne = buttons:WaitForChild("BuyOne")

	local buyMax = buttons:WaitForChild("BuyMax")

	local currentBuyMaxText = buyMax:WaitForChild("Text")

	if not buyOne:IsA("GuiButton") then
		warn("TrashBagGiverController: BuyOne must be a GuiButton")

		return
	end

	if not buyMax:IsA("GuiButton") then
		warn("TrashBagGiverController: BuyMax must be a GuiButton")

		return
	end

	if not currentBuyMaxText:IsA("TextLabel") then
		warn("TrashBagGiverController: BuyMax.Text must be a TextLabel")

		return
	end

	buyMaxText = currentBuyMaxText

	-- ============================
	-- BuyOne
	-- ============================

	buyOne.Activated:Connect(function()
		print("BuyOne clicked")

		networker:fire("addOne")
	end)

	-- ============================
	-- BuyMax
	-- ============================

	buyMax.Activated:Connect(function()
		print("BuyMax clicked")

		networker:fire("addMax")
	end)

	local kitchen = workspace:WaitForChild("Kitchen")

	kitchen:GetAttributeChangedSignal("TrashBagCount"):Connect(function()
		updateUI()
	end)

	kitchen:GetAttributeChangedSignal("TrashBagCapacity"):Connect(function()
		updateUI()
	end)

	updateUI()
end

return TrashBagGiverController
