--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Networker = require(ReplicatedStorage.Packages.Networker).client
local CameraController = require(script.Parent.Parent.Camera.CameraController)

local BinInteraction = {}
local networker = Networker.new("Movment", BinInteraction)

function BinInteraction.enter(cameraPosition: BasePart): ()
	CameraController.attach(cameraPosition)
	networker:fire("disableMovement")
end

function BinInteraction.exit(): ()
	CameraController.detach()
	CameraController.enableFirstPerson()
	networker:fire("enableMovement")
end

return BinInteraction
