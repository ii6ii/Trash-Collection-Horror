--!strict

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local UserInputService = game:GetService("UserInputService")

local Networker = require(ReplicatedStorage.Packages.Networker).client

local CameraShakeEffect = require(StarterPlayer.StarterPlayerScripts.Client.Camera.CameraEffect.CameraShakeEffect)

local FirstPersonCamera = require(script.Parent.FirstPersonCamera)

local CAMERA = workspace.CurrentCamera

local ATTACHED_CAMERA_RENDER_NAME = "AttachedCamera"

local CameraController = {}

local attachedPart: BasePart?

Networker.new("CameraController", CameraController)

local function lockCursor(): ()
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	UserInputService.MouseIconEnabled = false
end

local function unlockCursor(): ()
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	UserInputService.MouseIconEnabled = true
end

function CameraController.init(character: Model): ()
	FirstPersonCamera.init(character)
end

function CameraController.enableFirstPerson(): ()
	CameraController.detach()

	CAMERA.CameraType = Enum.CameraType.Scriptable

	FirstPersonCamera.enable()

	lockCursor()
end

function CameraController.disableFirstPerson(): ()
	FirstPersonCamera.disable()

	unlockCursor()
end

function CameraController.attach(part: BasePart): ()
	CameraController.disableFirstPerson()

	attachedPart = part

	CAMERA.CameraType = Enum.CameraType.Scriptable

	unlockCursor()

	RunService:BindToRenderStep(ATTACHED_CAMERA_RENDER_NAME, Enum.RenderPriority.Camera.Value + 1, function()
		local currentPart = attachedPart

		if not currentPart or not currentPart.Parent then
			return
		end

		CAMERA.CFrame = currentPart.CFrame
	end)
end

function CameraController.detach(): ()
	attachedPart = nil

	RunService:UnbindFromRenderStep(ATTACHED_CAMERA_RENDER_NAME)

	unlockCursor()
end

function CameraController.startShake(): ()
	CameraShakeEffect.Start()
end

function CameraController.stopShake(): ()
	CameraShakeEffect.Stop()
end

function CameraController.disable(): ()
	CameraController.detach()
	CameraController.disableFirstPerson()
	CameraController.stopShake()

	CAMERA.CameraType = Enum.CameraType.Custom

	unlockCursor()
end

function CameraController.onCharacterAdded(character: Model): ()
	FirstPersonCamera.init(character)
end

return CameraController
