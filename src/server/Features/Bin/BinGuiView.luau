--!strict

-- Рендер billboard-прогресс-бара Bin. Не хранит состояние - принимает
-- текущие числа снаружи и просто обновляет Instance'ы.

export type BinGuiModel = Model & {
	BillboardGui: BillboardGui & {
		ProgressBar: CanvasGroup & {
			Filler: Frame & {
				UIGradient: UIGradient,
			},
			ProgressText: TextLabel,
		},
		GrabText: TextLabel,
	},
}

local BinGuiView = {}

function BinGuiView.render(model: BinGuiModel, trashAmount: number, trashGoal: number): ()
	local gui = model.BillboardGui
	local progressBar = gui.ProgressBar

	local filler = progressBar.Filler
	local gradient = filler.UIGradient
	local progressText = progressBar.ProgressText
	local grabText = gui.GrabText

	local progress = if trashGoal > 0 then math.clamp(trashAmount / trashGoal, 0, 1) else 1

	if progress == 0 then
		gradient.Transparency = NumberSequence.new(1)
	elseif progress == 1 then
		gradient.Transparency = NumberSequence.new(0)
	else
		gradient.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(progress, 0),
			NumberSequenceKeypoint.new(progress, 1),
			NumberSequenceKeypoint.new(1, 1),
		})
	end

	progressText.Text = `{trashAmount}/{trashGoal}`

	if trashAmount < trashGoal then
		progressText.Text ..= " 🔒"
	end

	local full = trashAmount >= trashGoal

	for _, object in gui:GetDescendants() do
		if object:IsA("GuiObject") then
			object.Visible = not full
		end
	end

	grabText.Visible = full
end

return BinGuiView
