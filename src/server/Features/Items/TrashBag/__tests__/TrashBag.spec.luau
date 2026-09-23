--!strict

-- TrashBag.new() требует настоящую Model-иерархию (Model/Attachment) и
-- регистрирует себя в глобальных реестрах - здесь тестируется только чистая
-- формула getWeight, вызванная на минимальном фейковом self.

local ServerScriptService = game:GetService("ServerScriptService")

local TrashBag = require(ServerScriptService.Server.Features.Items.TrashBag.TrashBag)

return function()
	describe("TrashBag.getWeight", function()
		it("weighs 1 when empty", function()
			local fakeBag = { trashInside = 0 } :: any

			expect(TrashBag.getWeight(fakeBag)).to.equal(1)
		end)

		it("adds 1 weight per unit of trash inside", function()
			local fakeBag = { trashInside = 4 } :: any

			expect(TrashBag.getWeight(fakeBag)).to.equal(5)
		end)
	end)
end
