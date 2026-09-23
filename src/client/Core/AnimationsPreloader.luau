--!strict

local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AnimatorConfig = require(ReplicatedStorage.Shared.Config.AnimatorConfig)

local AnimationsPreloader = {}

function AnimationsPreloader.init(): ()
	local animations = {}

	for _, id in AnimatorConfig do
		local animation = Instance.new("Animation")
		animation.AnimationId = `rbxassetid://{id}`
		table.insert(animations, animation)
	end

	-- PreloadAsync yield'ит; раньше это был отдельный Script в своём потоке,
	-- поэтому не блокировал остальную инициализацию - сохраняем то же
	-- поведение через task.spawn вместо синхронного вызова из init.client.luau.
	task.spawn(function()
		ContentProvider:PreloadAsync(animations)
	end)
end

return AnimationsPreloader
