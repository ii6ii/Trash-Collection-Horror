--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local timerText =
	Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("MainGui"):WaitForChild("Top"):WaitForChild("Timer")

local DURATION = 6 * 60
local remainingTime = DURATION

local connection = RunService.Heartbeat:Connect(function(deltaTime: number)
	remainingTime = math.max(remainingTime - deltaTime, 0)

	local minutes = math.floor(remainingTime / 60)
	local seconds = math.floor(remainingTime % 60)

	timerText.Text = string.format("%02d:%02d", minutes, seconds)

	if remainingTime <= 0 then
		connection:Disconnect()
	end
end)
