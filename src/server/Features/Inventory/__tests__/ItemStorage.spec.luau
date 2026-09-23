--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local ItemStorage = require(ServerScriptService.Server.Features.Inventory.ItemStorage)
local TestItemFactory = require(script.Parent.TestItemFactory)

return function()
	describe("ItemStorage", function()
		it("adds an item to a free slot", function()
			local storage = ItemStorage.new(3)
			local item = TestItemFactory.new()

			expect(storage:addItem(item)).to.equal(true)
			expect(storage:getItemPosition(item)).to.be.ok()
		end)

		it("refuses to add when full", function()
			local storage = ItemStorage.new(1)
			storage:addItem(TestItemFactory.new())

			expect(storage:addItem(TestItemFactory.new())).to.equal(false)
		end)

		it("places multi-slot items at the highest free contiguous range", function()
			local storage = ItemStorage.new(3)
			local bigItem = TestItemFactory.new({ size = 2 })

			expect(storage:addItem(bigItem)).to.equal(true)
			-- Основной (доступный через getItem) слот - последний в занятом диапазоне,
			-- предыдущий слот занят, но лишь как локер (getItem его не возвращает).
			expect(storage:getItem(3)).to.equal(bigItem)
			expect(storage:getItem(2)).to.equal(nil)
			expect(storage:getItemPosition(bigItem)).to.equal(3)
		end)

		it("locks the secondary slots occupied by a multi-slot item", function()
			local storage = ItemStorage.new(2)
			local bigItem = TestItemFactory.new({ size = 2 })

			storage:putItem(bigItem, 2)

			expect(storage:getSlot(1).lockData.locked).to.equal(true)
			expect(storage:getSlot(1).lockData.lockedBy).to.equal(bigItem)
			expect(storage:canPutItem(TestItemFactory.new(), 1)).to.equal(false)
		end)

		it("frees every locked slot when the item is removed", function()
			local storage = ItemStorage.new(2)
			local bigItem = TestItemFactory.new({ size = 2 })
			storage:putItem(bigItem, 2)

			storage:removeItem(2)

			expect(storage:getSlot(1).lockData.locked).to.equal(false)
			expect(storage:getFreeSpace()).to.equal(2)
		end)

		it("rejects placement that would overlap an occupied slot", function()
			local storage = ItemStorage.new(3)
			storage:putItem(TestItemFactory.new(), 2)

			local bigItem = TestItemFactory.new({ size = 2 })

			expect(storage:canPutItem(bigItem, 2)).to.equal(false)
		end)

		it("rejects placement out of bounds", function()
			local storage = ItemStorage.new(2)
			local bigItem = TestItemFactory.new({ size = 3 })

			expect(storage:canPutItem(bigItem, 2)).to.equal(false)
		end)

		it("getAllItems returns every placed item exactly once", function()
			local storage = ItemStorage.new(3)
			local a = TestItemFactory.new()
			local b = TestItemFactory.new({ size = 2 })

			storage:putItem(a, 1)
			storage:putItem(b, 3)

			local items = storage:getAllItems()

			expect(#items).to.equal(2)
			expect(table.find(items, a)).to.be.ok()
			expect(table.find(items, b)).to.be.ok()
		end)
	end)
end
