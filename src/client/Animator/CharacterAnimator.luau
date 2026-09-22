--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Networker = require(ReplicatedStorage.Packages.Networker).client

local CharacterAnimator = {}

local PLAYER = Players.LocalPlayer

local RIGHT_HAND_ANIMATION_ID = 124714956055404
local LEFT_HAND_ANIMATION_ID = 105492048233640

local tracks: { [Humanoid]: { [string]: AnimationTrack } } = {}

local function getCharacter(): Model?
	return PLAYER.Character
end

local function getTrack(humanoid: Humanoid, name: string, animationId: number): AnimationTrack
	local animator = humanoid:WaitForChild("Animator") :: Animator

	tracks[humanoid] = tracks[humanoid] or {}

	if tracks[humanoid][name] then
		return tracks[humanoid][name]
	end

	local animation = Instance.new("Animation")
	animation.AnimationId = `rbxassetid://{animationId}`

	local track = animator:LoadAnimation(animation)
	track.Priority = Enum.AnimationPriority.Action4
	track.Looped = true

	tracks[humanoid][name] = track

	return track
end

function CharacterAnimator:HoldRightHand(): ()
	local character = getCharacter()
	if not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	print(getTrack(humanoid, "RightHand", RIGHT_HAND_ANIMATION_ID):Play())
	getTrack(humanoid, "RightHand", RIGHT_HAND_ANIMATION_ID):Play()
end

function CharacterAnimator:HoldLeftHand(): ()
	local character = getCharacter()
	if not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	print(LEFT_HAND_ANIMATION_ID)
	getTrack(humanoid, "LeftHand", LEFT_HAND_ANIMATION_ID):Play()
end

function CharacterAnimator:StopHandAnimations(): ()
	local character = getCharacter()
	if not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	local humanoidTracks = tracks[humanoid]
	if not humanoidTracks then
		return
	end

	for _, track in humanoidTracks do
		track:Stop()
	end
end

Networker.new("Animator", CharacterAnimator)

return CharacterAnimator
