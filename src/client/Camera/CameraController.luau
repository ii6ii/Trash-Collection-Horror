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

local ATTACH_DURATION = 0.45
local DETACH_DURATION = 0.35

local ATTACH_START_OFFSET = Vector3.new(0, -2.5, 5)
local ATTACH_ARC_HEIGHT = 0.8
local ATTACH_START_ROTATION = Vector3.new(20, 0, 0)

local CameraController = {}

local attachedPart: BasePart?
local isDetaching = false
local transitionId = 0

Networker.new("CameraController", CameraController)

local function lockCursor(): ()
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	UserInputService.MouseIconEnabled = false
end

local function unlockCursor(): ()
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	UserInputService.MouseIconEnabled = true
end

local function easeInOut(alpha: number): number
	return alpha * alpha * (3 - 2 * alpha)
end

local function getStartCFrame(part: BasePart): CFrame
	return part.CFrame
		* CFrame.new(ATTACH_START_OFFSET)
		* CFrame.Angles(
			math.rad(ATTACH_START_ROTATION.X),
			math.rad(ATTACH_START_ROTATION.Y),
			math.rad(ATTACH_START_ROTATION.Z)
		)
end

local function getArcCFrame(part: BasePart): CFrame
	return part.CFrame * CFrame.new(0, ATTACH_START_OFFSET.Y + ATTACH_ARC_HEIGHT, ATTACH_START_OFFSET.Z * 0.5)
end

local function unbindCamera(): ()
	RunService:UnbindFromRenderStep(ATTACHED_CAMERA_RENDER_NAME)
end

local function enableFirstPersonInternal(): ()
	isDetaching = false

	CAMERA.CameraType = Enum.CameraType.Scriptable

	FirstPersonCamera.enable()

	lockCursor()
end

function CameraController.init(character: Model): ()
	FirstPersonCamera.init(character)
end

function CameraController.enableFirstPerson(): ()
	transitionId += 1
	isDetaching = false

	unbindCamera()

	attachedPart = nil

	CAMERA.CameraType = Enum.CameraType.Scriptable

	FirstPersonCamera.enable()

	lockCursor()
end

function CameraController.disableFirstPerson(): ()
	transitionId += 1
	isDetaching = false

	FirstPersonCamera.disable()

	unlockCursor()
end

function CameraController.attach(part: BasePart): ()
	transitionId += 1

	local currentTransition = transitionId

	isDetaching = false

	unbindCamera()

	FirstPersonCamera.disable()

	attachedPart = part

	CAMERA.CameraType = Enum.CameraType.Scriptable

	unlockCursor()

	local targetCFrame = part.CFrame
	local startCFrame = getStartCFrame(part)
	local arcCFrame = getArcCFrame(part)

	local startPosition = startCFrame.Position
	local arcPosition = arcCFrame.Position
	local targetPosition = targetCFrame.Position

	local elapsed = 0

	CAMERA.CFrame = startCFrame

	RunService:BindToRenderStep(
		ATTACHED_CAMERA_RENDER_NAME,
		Enum.RenderPriority.Camera.Value + 1,
		function(deltaTime: number)
			if currentTransition ~= transitionId then
				return
			end

			local currentPart = attachedPart

			if not currentPart or not currentPart.Parent then
				unbindCamera()
				return
			end

			elapsed += deltaTime

			local alpha = math.clamp(elapsed / ATTACH_DURATION, 0, 1)

			local eased = easeInOut(alpha)
			local inverse = 1 - eased

			local position = startPosition * (inverse * inverse)
				+ arcPosition * (2 * inverse * eased)
				+ targetPosition * (eased * eased)

			local rotation = startCFrame:Lerp(targetCFrame, eased).Rotation

			CAMERA.CFrame = CFrame.new(position) * rotation

			if alpha >= 1 then
				CAMERA.CFrame = targetCFrame

				unbindCamera()
			end
		end
	)
end

function CameraController.detach(): ()
	if isDetaching then
		return
	end

	local part = attachedPart

	if not part or not part.Parent then
		return
	end

	isDetaching = true

	transitionId += 1

	local currentTransition = transitionId

	unbindCamera()

	CAMERA.CameraType = Enum.CameraType.Scriptable

	-- Текущая позиция камеры.
	local startCFrame = CAMERA.CFrame

	-- Финальная точка выхода:
	-- та самая точка, откуда камера входила.
	local targetCFrame = getStartCFrame(part)
	local arcCFrame = getArcCFrame(part)

	local startPosition = startCFrame.Position
	local arcPosition = arcCFrame.Position
	local targetPosition = targetCFrame.Position

	local elapsed = 0

	RunService:BindToRenderStep(
		ATTACHED_CAMERA_RENDER_NAME,
		Enum.RenderPriority.Camera.Value + 1,
		function(deltaTime: number)
			if currentTransition ~= transitionId then
				return
			end

			elapsed += deltaTime

			local alpha = math.clamp(elapsed / DETACH_DURATION, 0, 1)

			local eased = easeInOut(alpha)
			local inverse = 1 - eased

			local position = startPosition * (inverse * inverse)
				+ arcPosition * (2 * inverse * eased)
				+ targetPosition * (eased * eased)

			local rotation = startCFrame:Lerp(targetCFrame, eased).Rotation

			CAMERA.CFrame = CFrame.new(position) * rotation

			if alpha >= 1 then
				CAMERA.CFrame = targetCFrame

				unbindCamera()

				attachedPart = nil
				isDetaching = false

				-- ВОТ ЗДЕСЬ, И ТОЛЬКО ЗДЕСЬ,
				-- включается FirstPerson.
				enableFirstPersonInternal()
			end
		end
	)
end

function CameraController.startShake(): ()
	CameraShakeEffect.Start()
end

function CameraController.stopShake(): ()
	CameraShakeEffect.Stop()
end

function CameraController.disable(): ()
	transitionId += 1
	isDetaching = false

	unbindCamera()

	attachedPart = nil

	FirstPersonCamera.disable()
	CameraShakeEffect.Stop()

	CAMERA.CameraType = Enum.CameraType.Custom

	unlockCursor()
end

function CameraController.onCharacterAdded(character: Model): ()
	FirstPersonCamera.init(character)
end

return CameraController
