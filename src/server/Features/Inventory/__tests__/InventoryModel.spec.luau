--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local InventoryModel = require(ServerScriptService.Server.Features.Inventory.InventoryModel)
local TestItemFactory = require(script.Parent.TestItemFactory)

-- Слоты 1-2 - руки, 3-5 - рюкзак (InventoryConfig: HandsCapacity=2, BackpackCapacity=3).
-- ItemStorage.getFreeSlotId заполняет с наибольшего свободного id, поэтому тесты
-- не хардкодят конкретный номер слота там, где это не является предметом проверки,
-- а вычисляют его через getItemSlot.

return function()
	describe("InventoryModel.addItem", function()
		it("places a single item into hands when it allows it", function()
			local model = InventoryModel.new()
			local item = TestItemFactory.new()

			expect(model:addItem(item)).to.equal(true)
			local slot = model:getItemSlot(item)
			expect(slot).to.be.ok()
			expect(model:isHandSlot(slot :: number)).to.equal(true)
		end)

		it("fills hands starting from the last free slot", function()
			local model = InventoryModel.new()
			local first = TestItemFactory.new()
			local second = TestItemFactory.new()
			model:addItem(first)
			model:addItem(second)

			expect(model:getItemSlot(first)).to.equal(2)
			expect(model:getItemSlot(second)).to.equal(1)
		end)

		it("falls back to the backpack when hands are full", function()
			local model = InventoryModel.new()
			model:addItem(TestItemFactory.new())
			model:addItem(TestItemFactory.new())

			local third = TestItemFactory.new()
			expect(model:addItem(third)).to.equal(true)
			expect(model:isHandSlot(model:getItemSlot(third) :: number)).to.equal(false)
		end)

		it("goes straight to the backpack when hands are disallowed", function()
			local model = InventoryModel.new()
			local item = TestItemFactory.new({ canTakeInHands = false })

			expect(model:addItem(item)).to.equal(true)
			expect(model:isHandSlot(model:getItemSlot(item) :: number)).to.equal(false)
		end)

		it("fails when neither hands nor backpack accept the item", function()
			local model = InventoryModel.new()

			for _ = 1, 2 do
				model:addItem(TestItemFactory.new())
			end
			for _ = 1, 3 do
				model:addItem(TestItemFactory.new())
			end

			local overflow = TestItemFactory.new()
			expect(model:addItem(overflow)).to.equal(false)
			expect(model:getItemSlot(overflow)).to.equal(nil)
		end)
	end)

	describe("InventoryModel.removeItem", function()
		it("reports wasInHands = true for a hand slot", function()
			local model = InventoryModel.new()
			local item = TestItemFactory.new()
			model:addItem(item)

			local wasInHands: boolean? = nil
			model.ItemRemoved:Connect(function(_, inHands)
				wasInHands = inHands
			end)

			expect(model:removeItem(item)).to.equal(true)
			expect(wasInHands).to.equal(true)
			expect(model:getItemSlot(item)).to.equal(nil)
		end)

		it("reports wasInHands = false for a backpack slot", function()
			local model = InventoryModel.new()
			local item = TestItemFactory.new()
			model:addItem(item)

			local handSlot = model:getItemSlot(item) :: number
			model:moveItem(handSlot, 3)

			local wasInHands: boolean? = nil
			model.ItemRemoved:Connect(function(_, inHands)
				wasInHands = inHands
			end)

			model:removeItem(item)
			expect(wasInHands).to.equal(false)
		end)

		it("returns false for an item that is not in the inventory", function()
			local model = InventoryModel.new()

			expect(model:removeItem(TestItemFactory.new())).to.equal(false)
		end)
	end)

	describe("InventoryModel.moveItem", function()
		it("is a no-op when from and to are the same slot", function()
			local model = InventoryModel.new()
			model:addItem(TestItemFactory.new())

			expect(model:moveItem(1, 1)).to.equal(false)
		end)

		it("rejects out-of-range and non-integer slot ids", function()
			local model = InventoryModel.new()
			model:addItem(TestItemFactory.new())

			expect(model:moveItem(0, 1)).to.equal(false)
			expect(model:moveItem(1, 6)).to.equal(false)
			expect(model:moveItem(1, 1.5)).to.equal(false)
		end)

		it("does nothing when both slots are empty", function()
			local model = InventoryModel.new()

			expect(model:moveItem(1, 2)).to.equal(false)
		end)

		it("moves an item from an occupied slot into an empty one", function()
			local model = InventoryModel.new()
			local item = TestItemFactory.new()
			model:addItem(item)
			local from = model:getItemSlot(item) :: number

			expect(model:moveItem(from, 3)).to.equal(true)
			expect(model:getItem(3)).to.equal(item)
			expect(model:getItem(from)).to.equal(nil)
		end)

		it("moves an item when the empty slot is given first", function()
			local model = InventoryModel.new()
			local item = TestItemFactory.new()
			model:addItem(item)
			local occupied = model:getItemSlot(item) :: number

			expect(model:moveItem(3, occupied)).to.equal(true)
			expect(model:getItem(3)).to.equal(item)
			expect(model:getItem(occupied)).to.equal(nil)
		end)

		it("swaps two occupied slots", function()
			local model = InventoryModel.new()
			local a = TestItemFactory.new()
			local b = TestItemFactory.new()
			model:addItem(a)
			model:addItem(b)

			local slotA = model:getItemSlot(a) :: number
			local slotB = model:getItemSlot(b) :: number

			expect(model:moveItem(slotA, slotB)).to.equal(true)
			expect(model:getItem(slotA)).to.equal(b)
			expect(model:getItem(slotB)).to.equal(a)
		end)

		it("refuses to move an item into hands if it disallows hands", function()
			local model = InventoryModel.new()
			local item = TestItemFactory.new({ canTakeInHands = false })
			model:addItem(item)
			local backpackSlot = model:getItemSlot(item) :: number

			expect(model:moveItem(backpackSlot, 1)).to.equal(false)
			expect(model:getItem(backpackSlot)).to.equal(item)
			expect(model:getItem(1)).to.equal(nil)
		end)

		it("refuses to move an item into the backpack if it disallows the backpack", function()
			local model = InventoryModel.new()
			local item = TestItemFactory.new({ canPutInBackpack = false })
			model:addItem(item)
			local handSlot = model:getItemSlot(item) :: number

			expect(model:moveItem(handSlot, 3)).to.equal(false)
			expect(model:getItem(handSlot)).to.equal(item)
			expect(model:getItem(3)).to.equal(nil)
		end)

		it("rolls back a swap entirely when one side is not allowed", function()
			local model = InventoryModel.new()
			local handsOnly = TestItemFactory.new({ canPutInBackpack = false })
			local backpackOnly = TestItemFactory.new({ canTakeInHands = false })

			model:addItem(handsOnly)
			model:addItem(backpackOnly)

			local handSlot = model:getItemSlot(handsOnly) :: number
			local backpackSlot = model:getItemSlot(backpackOnly) :: number

			expect(model:moveItem(handSlot, backpackSlot)).to.equal(false)
			expect(model:getItem(handSlot)).to.equal(handsOnly)
			expect(model:getItem(backpackSlot)).to.equal(backpackOnly)
		end)

		it("moves a multi-slot item into the backpack when there is room", function()
			local model = InventoryModel.new()
			local bigItem = TestItemFactory.new({ size = 2 })
			model:addItem(bigItem) -- занимает оба слота рук: 2 (основной) + 1 (заблокированный)

			expect(model:getItem(2)).to.equal(bigItem)

			expect(model:moveItem(2, 5)).to.equal(true)
			expect(model:getItem(5)).to.equal(bigItem)
			expect(model:getItem(1)).to.equal(nil)
			expect(model:getItem(2)).to.equal(nil)
		end)

		it("refuses a multi-slot move that would not fit at the target", function()
			local model = InventoryModel.new()
			local bigItem = TestItemFactory.new({ size = 2 })
			model:addItem(bigItem)

			-- Слот 3 (первый слот рюкзака) не может вместить предмет размера 2:
			-- не хватает места слева.
			expect(model:moveItem(2, 3)).to.equal(false)
			expect(model:getItem(2)).to.equal(bigItem)
			expect(model:getItem(3)).to.equal(nil)
		end)
	end)

	describe("InventoryModel.getAllItems / getSlotData", function()
		it("combines hands and backpack items", function()
			local model = InventoryModel.new()
			local a = TestItemFactory.new()
			local b = TestItemFactory.new({ canTakeInHands = false })
			model:addItem(a)
			model:addItem(b)

			local items = model:getAllItems()
			expect(#items).to.equal(2)
			expect(table.find(items, a)).to.be.ok()
			expect(table.find(items, b)).to.be.ok()
		end)

		it("marks the locked slot of a multi-slot item with its type", function()
			local model = InventoryModel.new()
			local bigItem = TestItemFactory.new({ size = 2, type = "big" })
			model:addItem(bigItem)

			local slotData = model:getSlotData()

			expect(slotData[1].isLock).to.equal(true)
			expect(slotData[1].type).to.equal("big")
			expect(slotData[2].isLock).to.equal(false)
			expect(slotData[2].type).to.equal("big")
		end)
	end)
end
