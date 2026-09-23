--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local Input = require(ServerScriptService.Server.Core.InputSystem.Input)

local function fakeContext(name: string)
	return {
		lookDirection = Vector3.zero,
		cameraCFrame = CFrame.new(),
		name = name,
	}
end

return function()
	describe("Input", function()
		it("starts not started", function()
			local input = Input.new()

			expect(input.isStarted).to.equal(false)
		end)

		it("begin fires Started and Switched, sets isStarted", function()
			local input = Input.new()
			local startedCount = 0
			local switchedCount = 0

			input.Started:Connect(function()
				startedCount += 1
			end)
			input.Switched:Connect(function()
				switchedCount += 1
			end)

			input:begin(fakeContext("EInput"))

			expect(input.isStarted).to.equal(true)
			expect(startedCount).to.equal(1)
			expect(switchedCount).to.equal(1)
		end)

		it("begin is idempotent while already started", function()
			local input = Input.new()
			local startedCount = 0

			input.Started:Connect(function()
				startedCount += 1
			end)

			input:begin(fakeContext("EInput"))
			input:begin(fakeContext("EInput"))

			expect(startedCount).to.equal(1)
		end)

		it("finish fires Ended and Switched only when started", function()
			local input = Input.new()
			local endedCount = 0
			local switchedCount = 0

			input.Ended:Connect(function()
				endedCount += 1
			end)
			input.Switched:Connect(function()
				switchedCount += 1
			end)

			input:finish(fakeContext("EInput"))
			expect(endedCount).to.equal(0)
			expect(switchedCount).to.equal(0)

			input:begin(fakeContext("EInput"))
			input:finish(fakeContext("EInput"))

			expect(input.isStarted).to.equal(false)
			expect(endedCount).to.equal(1)
			expect(switchedCount).to.equal(2) -- begin + finish
		end)

		it("destroy disconnects all listeners", function()
			local input = Input.new()
			local calls = 0

			input.Started:Connect(function()
				calls += 1
			end)

			input:destroy()
			input:begin(fakeContext("EInput"))

			expect(calls).to.equal(0)
		end)
	end)
end
