--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Networker = require(ReplicatedStorage.Packages.Networker).client

local CameraController = require(script.Parent.Parent.Parent.Core.Camera.CameraController)

local BinInteraction = {}

local networker: any

function BinInteraction.init(): ()
	networker = Networker.new("Movment", BinInteraction)
end

function BinInteraction.enter(cameraPosition: BasePart): ()
	CameraController.attach(cameraPosition)

	networker:fire("setBinOpen", true)
	networker:fire("disableMovement")
end

function BinInteraction.exit(): ()
	CameraController.detach()

	networker:fire("setBinOpen", false)
	networker:fire("enableMovement")
end

return BinInteraction
