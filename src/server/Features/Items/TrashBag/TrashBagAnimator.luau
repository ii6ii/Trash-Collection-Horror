--!strict

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TrashBagConfig = require(ReplicatedStorage.Shared.Config.TrashBagConfig)

local TrashBagAnimator = {}

local TWEEN_INFO =
	TweenInfo.new(TrashBagConfig.TieAnimationDuration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

local X_SCALE = TrashBagConfig.TieAnimationXScale
local Y_SCALE = TrashBagConfig.TieAnimationYScale
local Z_SCALE = TrashBagConfig.TieAnimationZScale

type AnimationData = {
	originalSize: Vector3,
	tween: Tween?,
	running: boolean,
}

local animations: { [BasePart]: AnimationData } = {}

function TrashBagAnimator.playTieAnimation(part: BasePart): ()
	local currentData = animations[part]

	if currentData and currentData.running then
		return
	end

	local data: AnimationData = {
		originalSize = part.Size,
		tween = nil,
		running = true,
	}

	animations[part] = data

	task.spawn(function()
		while data.running do
			local tween = TweenService:Create(part, TWEEN_INFO, {
				Size = Vector3.new(
					data.originalSize.X * X_SCALE,
					data.originalSize.Y * Y_SCALE,
					data.originalSize.Z * Z_SCALE
				),
			})

			data.tween = tween
			tween:Play()
			tween.Completed:Wait()

			if not data.running then
				break
			end

			local resetTween = TweenService:Create(part, TWEEN_INFO, {
				Size = data.originalSize,
			})

			data.tween = resetTween
			resetTween:Play()
			resetTween.Completed:Wait()
		end
	end)
end

function TrashBagAnimator.stop(part: BasePart): ()
	local data = animations[part]
	if not data then
		return
	end

	data.running = false

	if data.tween then
		data.tween:Cancel()
	end

	part.Size = data.originalSize
	animations[part] = nil
end

return TrashBagAnimator
