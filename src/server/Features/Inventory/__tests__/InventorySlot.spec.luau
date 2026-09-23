--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local InventorySlot = require(ServerScriptService.Server.Features.Inventory.InventorySlot)
local TestItemFactory = require(script.Parent.TestItemFactory)

return function()
	describe("InventorySlot", function()
		it("starts empty and unlocked", function()
			local slot = InventorySlot.new()

			expect(slot:getItem()).to.equal(nil)
			expect(slot.lockData.locked).to.equal(false)
		end)

		it("putItem locks the slot with the placed item as locker", function()
			local slot = InventorySlot.new()
			local item = TestItemFactory.new()

			expect(slot:putItem(item)).to.equal(true)
			expect(slot:getItem()).to.equal(item)
			expect(slot.lockData.locked).to.equal(true)
			expect(slot.lockData.lockedBy).to.equal(item)
		end)

		it("refuses putItem on an already locked slot", function()
			local slot = InventorySlot.new()
			slot:lockSlot(TestItemFactory.new())

			expect(slot:putItem(TestItemFactory.new())).to.equal(false)
		end)

		it("refuses to unlock a slot that still holds an item", function()
			local slot = InventorySlot.new()
			slot:putItem(TestItemFactory.new())

			expect(slot:unlockSlot()).to.equal(false)
			expect(slot.lockData.locked).to.equal(true)
		end)

		it("removeItem clears both the item and the lock", function()
			local slot = InventorySlot.new()
			local item = TestItemFactory.new()
			slot:putItem(item)

			expect(slot:removeItem()).to.equal(item)
			expect(slot:getItem()).to.equal(nil)
			expect(slot.lockData.locked).to.equal(false)
		end)

		it("removeItem on an empty slot returns nil and does not error", function()
			local slot = InventorySlot.new()

			expect(slot:removeItem()).to.equal(nil)
		end)
	end)
end
