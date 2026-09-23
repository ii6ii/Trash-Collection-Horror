--!strict

-- Покрывает переходы состояния (sprint/bin/enable гейтинг), которые не
-- требуют реального Character. updateWeight/updateSpeed/updateCameraShake
-- не тестируются здесь: они трогают Humanoid и шлют networker-событие через
-- CameraController.startShake/stopShake, которому нужен настоящий Player
-- (FireClient падает на фейковой таблице) - это уже требует реального игрока.

local ServerScriptService = game:GetService("ServerScriptService")

local Movement = require(ServerScriptService.Server.Core.Movement.Movement)

local function fakePlayer(): Player
	return {} :: any
end

return function()
	describe("Movement.startSprint / stopSprint", function()
		it("starts sprinting when nothing blocks it", function()
			local movement = Movement.new(fakePlayer())

			movement:startSprint()

			expect(movement.isSprinting).to.equal(true)
		end)

		it("refuses to sprint while carrying a bin", function()
			local movement = Movement.new(fakePlayer())
			movement:setBin(true)

			movement:startSprint()

			expect(movement.isSprinting).to.equal(false)
		end)

		it("refuses to sprint while movement is disabled", function()
			local movement = Movement.new(fakePlayer())
			movement:disableMovement()

			movement:startSprint()

			expect(movement.isSprinting).to.equal(false)
		end)

		it("refuses to sprint over the max sprint weight", function()
			local movement = Movement.new(fakePlayer())
			movement.totalWeight = 999

			movement:startSprint()

			expect(movement.isSprinting).to.equal(false)
		end)

		it("stopSprint clears isSprinting", function()
			local movement = Movement.new(fakePlayer())
			movement:startSprint()

			movement:stopSprint()

			expect(movement.isSprinting).to.equal(false)
		end)

		it("stopSprint is a no-op when not sprinting", function()
			local movement = Movement.new(fakePlayer())

			movement:stopSprint()

			expect(movement.isSprinting).to.equal(false)
		end)
	end)

	describe("Movement.setBin", function()
		it("forces sprint off when picking up a bin", function()
			local movement = Movement.new(fakePlayer())
			movement:startSprint()

			movement:setBin(true)

			expect(movement.isSprinting).to.equal(false)
			expect(movement.hasBin).to.equal(true)
		end)

		it("does not force sprint on by itself when dropping a bin", function()
			local movement = Movement.new(fakePlayer())
			movement:setBin(true)

			movement:setBin(false)

			expect(movement.hasBin).to.equal(false)
			expect(movement.isSprinting).to.equal(false)
		end)
	end)

	describe("Movement.disableMovement / enableMovement", function()
		it("disables movement and clears sprint", function()
			local movement = Movement.new(fakePlayer())
			movement:startSprint()

			movement:disableMovement()

			expect(movement.isMovementEnabled).to.equal(false)
			expect(movement.isSprinting).to.equal(false)
		end)

		it("is idempotent", function()
			local movement = Movement.new(fakePlayer())

			movement:disableMovement()
			movement:disableMovement()

			expect(movement.isMovementEnabled).to.equal(false)
		end)

		it("re-enables movement", function()
			local movement = Movement.new(fakePlayer())
			movement:disableMovement()

			movement:enableMovement()

			expect(movement.isMovementEnabled).to.equal(true)
		end)

		it("enableMovement is idempotent", function()
			local movement = Movement.new(fakePlayer())

			movement:enableMovement()

			expect(movement.isMovementEnabled).to.equal(true)
		end)
	end)
end
