--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Networker = require(ReplicatedStorage.Packages.Networker).client
local AnimatorConfig = require(ReplicatedStorage.Shared.Config.AnimatorConfig)

local CharacterAnimator = {}

local PLAYER = Players.LocalPlayer

local RIGHT_HAND_ANIMATION_ID = AnimatorConfig.RightHandHoldId
local LEFT_HAND_ANIMATION_ID = AnimatorConfig.LeftHandHoldId

local tracks: { [Humanoid]: { [string]: AnimationTrack } } = {}

local function getCharacter(): Model?
	return PLAYER.Character
end

-- Humanoid уничтожается на каждом респавне - отписываемся по Destroying,
-- а не по CharacterAdded/Removing, иначе tracks растёт с каждым респавном.
local function forgetHumanoidOnDestroy(humanoid: Humanoid): ()
	if tracks[humanoid] then
		return
	end

	tracks[humanoid] = {}

	humanoid.Destroying:Once(function()
		tracks[humanoid] = nil
	end)
end

local function getTrack(humanoid: Humanoid, name: string, animationId: number): AnimationTrack
	local animator = humanoid:WaitForChild("Animator") :: Animator

	forgetHumanoidOnDestroy(humanoid)

	local humanoidTracks = tracks[humanoid]

	if humanoidTracks[name] then
		return humanoidTracks[name]
	end

	local animation = Instance.new("Animation")
	animation.AnimationId = `rbxassetid://{animationId}`

	local track = animator:LoadAnimation(animation)
	track.Priority = Enum.AnimationPriority.Action4
	track.Looped = true

	humanoidTracks[name] = track

	return track
end

local function playHand(name: string, animationId: number): ()
	local character = getCharacter()
	if not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	getTrack(humanoid, name, animationId):Play()
end

function CharacterAnimator:HoldRightHand(): ()
	playHand("RightHand", RIGHT_HAND_ANIMATION_ID)
end

function CharacterAnimator:HoldLeftHand(): ()
	playHand("LeftHand", LEFT_HAND_ANIMATION_ID)
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

function CharacterAnimator.init(): ()
	Networker.new("Animator", CharacterAnimator)
end

return CharacterAnimator
