--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Networker = require(ReplicatedStorage.Packages.Networker).server

local networker = Networker.new("CameraShakeEffect")

local CameraShakeEffect = {}

function CameraShakeEffect.Start(player: Player): ()
	print("START SHAKE SERVER")

	networker:fire(player, "Start")
end

function CameraShakeEffect.Stop(player: Player): ()
	networker:fire(player, "Stop")
end

return CameraShakeEffect
