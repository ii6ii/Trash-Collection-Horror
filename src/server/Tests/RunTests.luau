--!strict

-- Прогоняет все TestEz-спеки (*.spec.luau) проекта. Работает только в Studio,
-- чтобы не тратить время старта на живом сервере. Спеки лежат рядом с кодом,
-- который они проверяют, в папках __tests__.

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local RunTests = {}

function RunTests.init(): ()
	if not RunService:IsStudio() then
		return
	end

	-- В своём потоке, как раньше в отдельном Script: не блокирует остальную
	-- инициализацию сервера и PlayerAdded/PlayerRemoving подписки.
	task.spawn(function()
		local TestEz = require(ReplicatedStorage.Packages.TestEz)

		-- Целиком по Server и Shared: спеки сами находят себя по суффиксу
		-- .spec, так что новый __tests__ где угодно в дереве подхватится
		-- без правки этого файла.
		local roots = {
			ServerScriptService.Server,
			ReplicatedStorage.Shared,
		}

		local results = TestEz.TestBootstrap:run(roots)

		if results.failureCount > 0 then
			warn(`Tests: {results.failureCount} failed, {results.successCount} passed`)
		else
			print(`Tests: all {results.successCount} passed`)
		end
	end)
end

return RunTests
