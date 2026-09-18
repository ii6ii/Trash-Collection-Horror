--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Networker = require(ReplicatedStorage.Packages.Networker).server

local CameraController = {}

local networker = Networker.new("CameraController")

function CameraController.enableFirstPerson(player: Player): ()
	networker:fire(player, "enableFirstPerson")
end

function CameraController.disableFirstPerson(player: Player): ()
	networker:fire(player, "disableFirstPerson")
end

function CameraController.attach(player: Player, part: BasePart): ()
	networker:fire(player, "attach", part)
end

function CameraController.detach(player: Player): ()
	networker:fire(player, "detach")
end

function CameraController.startShake(player: Player): ()
	networker:fire(player, "startShake")
end

function CameraController.stopShake(player: Player): ()
	networker:fire(player, "stopShake")
end

function CameraController.disable(player: Player): ()
	networker:fire(player, "disable")
end

return CameraController
