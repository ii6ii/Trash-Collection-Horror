--!strict

local ContentProvider = game:GetService("ContentProvider")

local ANIMATION_IDS = {
	RightHandHold = 125153135180187,
	LeftHandHold = 133289954566083,
}

local animations = {}

for _, id in ANIMATION_IDS do
	local animation = Instance.new("Animation")
	animation.AnimationId = `rbxassetid://{id}`
	table.insert(animations, animation)
end

ContentProvider:PreloadAsync(animations)
