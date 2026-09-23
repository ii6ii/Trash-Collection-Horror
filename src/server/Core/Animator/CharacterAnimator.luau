--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Networker = require(ReplicatedStorage.Packages.Networker).server

local CharacterAnimator = {}

local animatorNetworker: any

function CharacterAnimator.init(): ()
	animatorNetworker = Networker.new("Animator")
end

function CharacterAnimator.HoldRightHand(player: Player): ()
	animatorNetworker:fire(player, "HoldRightHand")
end

function CharacterAnimator.HoldLeftHand(player: Player): ()
	animatorNetworker:fire(player, "HoldLeftHand")
end

function CharacterAnimator.StopHandAnimations(player: Player): ()
	animatorNetworker:fire(player, "StopHandAnimations")
end

return CharacterAnimator