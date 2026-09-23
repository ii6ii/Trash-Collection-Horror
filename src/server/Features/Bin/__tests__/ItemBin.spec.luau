--!strict

-- Покрывает только то, что не тянет за собой реального Player/Inventory:
-- capacity-бухгалтерию (isFull/canAddItem/getItems) и default-хуки.
-- addItem/removeItem идут через Inventory.getPlayerInventory(player), которому
-- нужен настоящий Player и предмет с реальным Instance - это уже интеграционный
-- сценарий поверх всего стека (Bin+Inventory+Roblox), а не модульный тест ItemBin.

local ServerScriptService = game:GetService("ServerScriptService")

local ItemBin = require(ServerScriptService.Server.Features.Bin.ItemBin)

local function buildBinModelFixture(): ItemBin.BinModel
	local model = Instance.new("Model")

	local zone = Instance.new("Part")
	zone.Name = "Zone"
	zone.Parent = model

	local cameraPosition = Instance.new("Part")
	cameraPosition.Name = "CameraPosition"
	cameraPosition.Parent = model

	local itemSpawnPosition = Instance.new("Part")
	itemSpawnPosition.Name = "ItemSpawnPosition"
	itemSpawnPosition.Parent = model

	local inner = Instance.new("Model")
	inner.Name = "Model"
	inner.Parent = model

	local pushZone = Instance.new("Part")
	pushZone.Name = "PushZone"
	pushZone.Parent = inner

	local gui = Instance.new("BillboardGui")
	gui.Name = "BillboardGui"
	gui.Parent = model

	local progressBar = Instance.new("CanvasGroup")
	progressBar.Name = "ProgressBar"
	progressBar.Parent = gui

	local filler = Instance.new("Frame")
	filler.Name = "Filler"
	filler.Parent = progressBar

	local gradient = Instance.new("UIGradient")
	gradient.Parent = filler

	local progressText = Instance.new("TextLabel")
	progressText.Name = "ProgressText"
	progressText.Parent = progressBar

	local grabText = Instance.new("TextLabel")
	grabText.Name = "GrabText"
	grabText.Parent = gui

	return model :: any
end

return function()
	describe("ItemBin", function()
		it("starts empty and not full for a positive goal", function()
			local model = buildBinModelFixture()
			local bin = ItemBin.new(model, 5)

			expect(bin:isFull()).to.equal(false)
			expect(#bin:getItems()).to.equal(0)

			model:Destroy()
		end)

		it("is immediately full when the goal is zero", function()
			local model = buildBinModelFixture()
			local bin = ItemBin.new(model, 0)

			expect(bin:isFull()).to.equal(true)

			model:Destroy()
		end)

		it("canAddItem is false once the bin reports full", function()
			local model = buildBinModelFixture()
			local bin = ItemBin.new(model, 3)

			bin.trashAmount = 3

			expect(bin:isFull()).to.equal(true)
			expect(bin:canAddItem(nil :: any)).to.equal(false)

			model:Destroy()
		end)

		it("canAddItem is true below the goal", function()
			local model = buildBinModelFixture()
			local bin = ItemBin.new(model, 3)

			bin.trashAmount = 2

			expect(bin:canAddItem(nil :: any)).to.equal(true)

			model:Destroy()
		end)

		it("getTrashAmount defaults to 1 per item regardless of the item", function()
			local model = buildBinModelFixture()
			local bin = ItemBin.new(model, 5)

			expect(bin:getTrashAmount(nil :: any)).to.equal(1)

			model:Destroy()
		end)

		it("getItems reflects whatever is currently tracked", function()
			local model = buildBinModelFixture()
			local bin = ItemBin.new(model, 5)

			local fakeItem = {} :: any
			table.insert(bin.items, fakeItem)

			local items = bin:getItems()

			expect(#items).to.equal(1)
			expect(items[1]).to.equal(fakeItem)

			model:Destroy()
		end)
	end)
end
