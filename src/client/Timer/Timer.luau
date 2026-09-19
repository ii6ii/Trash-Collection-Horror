--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Timer = {}

local DURATION = 6 * 60

local initialized = false
local remainingTime = DURATION
local connection: RBXScriptConnection?

local function getTimerText(): TextLabel
	local player = Players.LocalPlayer

	local playerGui = player:WaitForChild("PlayerGui")
	local mainGui = playerGui:WaitForChild("MainGui")
	local top = mainGui:WaitForChild("Top")
	local timer = top:WaitForChild("Timer")

	assert(timer:IsA("TextLabel"), "Timer must be a TextLabel")

	return timer
end

local function updateText(timerText: TextLabel): ()
	local minutes = math.floor(remainingTime / 60)
	local seconds = math.floor(remainingTime % 60)

	timerText.Text = string.format("%02d:%02d", minutes, seconds)
end

local function stop(timerText: TextLabel): ()
	if connection then
		connection:Disconnect()
		connection = nil
	end

	remainingTime = 0

	updateText(timerText)
end

function Timer.init(): ()
	if initialized then
		return
	end

	initialized = true

	local timerText = getTimerText()

	remainingTime = DURATION

	-- Сразу показываем начальное значение.
	updateText(timerText)

	connection = RunService.Heartbeat:Connect(function(deltaTime: number)
		if remainingTime <= 0 then
			stop(timerText)
			return
		end

		remainingTime = math.max(remainingTime - deltaTime, 0)

		updateText(timerText)

		if remainingTime <= 0 then
			stop(timerText)
		end
	end)
end

return Timer
