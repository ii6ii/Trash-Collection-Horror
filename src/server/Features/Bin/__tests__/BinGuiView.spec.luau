--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local BinGuiView = require(ServerScriptService.Server.Features.Bin.BinGuiView)

local function buildFixture()
	local model = Instance.new("Model")

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
	gradient.Name = "UIGradient"
	gradient.Parent = filler

	local progressText = Instance.new("TextLabel")
	progressText.Name = "ProgressText"
	progressText.Parent = progressBar

	local grabText = Instance.new("TextLabel")
	grabText.Name = "GrabText"
	grabText.Parent = gui

	return model :: any, gradient, progressText, grabText
end

return function()
	describe("BinGuiView.render", function()
		it("shows progress text and hides GrabText while not full", function()
			local model, _gradient, progressText, grabText = buildFixture()

			BinGuiView.render(model, 2, 5)

			expect(progressText.Text).to.equal("2/5 🔒")
			expect(grabText.Visible).to.equal(false)

			model:Destroy()
		end)

		it("shows GrabText and hides the rest once full", function()
			local model, _gradient, progressText, grabText = buildFixture()

			BinGuiView.render(model, 5, 5)

			expect(progressText.Text).to.equal("5/5")
			expect(grabText.Visible).to.equal(true)
			expect(progressText.Visible).to.equal(false)

			model:Destroy()
		end)

		it("treats trashGoal <= 0 as always-full (progress clamps to 1)", function()
			local model, gradient = buildFixture()

			BinGuiView.render(model, 0, 0)

			expect(gradient.Transparency).to.equal(NumberSequence.new(0))

			model:Destroy()
		end)

		it("never goes above 100% progress even if trashAmount exceeds the goal", function()
			local model, gradient = buildFixture()

			BinGuiView.render(model, 999, 5)

			expect(gradient.Transparency).to.equal(NumberSequence.new(0))

			model:Destroy()
		end)
	end)
end
