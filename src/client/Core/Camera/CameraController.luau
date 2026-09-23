--!strict

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Networker = require(ReplicatedStorage.Packages.Networker).client
local CameraConfig = require(ReplicatedStorage.Shared.Config.CameraConfig)
local Easing = require(ReplicatedStorage.Shared.Utils.Easing)

local CameraShakeEffect = require(script.Parent.CameraEffect.CameraShakeEffect)

local FirstPersonCamera = require(script.Parent.FirstPersonCamera)

local CAMERA = workspace.CurrentCamera

local ATTACHED_CAMERA_RENDER_NAME = "AttachedCamera"

local ATTACH_DURATION = CameraConfig.AttachDuration
local DETACH_DURATION = CameraConfig.DetachDuration

local ATTACH_START_OFFSET = CameraConfig.AttachStartOffset
local ATTACH_ARC_HEIGHT = CameraConfig.AttachArcHeight
local ATTACH_START_ROTATION = CameraConfig.AttachStartRotation

local CameraController = {}

local attachedPart: BasePart?
local isDetaching = false
local transitionId = 0

function CameraController.init(): ()
	Networker.new("CameraController", CameraController)
end

local function lockCursor(): ()
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	UserInputService.MouseIconEnabled = false
end

local function unlockCursor(): ()
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	UserInputService.MouseIconEnabled = true
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

-- Общая dolly-анимация камеры: движение по дуге (квадратичная интерполяция
-- через arcCFrame) + Lerp поворота. attach() и detach() отличаются только
-- направлением (start/target поменяны местами), длительностью, условием
-- отмены (isCancelled) и тем, что происходит по завершению (onComplete).
local function runArcTransition(
	currentTransition: number,
	startCFrame: CFrame,
	targetCFrame: CFrame,
	arcCFrame: CFrame,
	duration: number,
	isCancelled: () -> boolean,
	onComplete: () -> ()
): ()
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

			if isCancelled() then
				unbindCamera()
				return
			end

			elapsed += deltaTime

			local alpha = math.clamp(elapsed / duration, 0, 1)

			local eased = Easing.smoothstep(alpha)
			local inverse = 1 - eased

			local position = startPosition * (inverse * inverse)
				+ arcPosition * (2 * inverse * eased)
				+ targetPosition * (eased * eased)

			local rotation = startCFrame:Lerp(targetCFrame, eased).Rotation

			CAMERA.CFrame = CFrame.new(position) * rotation

			if alpha >= 1 then
				CAMERA.CFrame = targetCFrame

				unbindCamera()
				onComplete()
			end
		end
	)
end

local function enableFirstPersonInternal(): ()
	isDetaching = false

	CAMERA.CameraType = Enum.CameraType.Scriptable

	FirstPersonCamera.enable()

	lockCursor()
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

	CAMERA.CFrame = startCFrame

	runArcTransition(currentTransition, startCFrame, targetCFrame, arcCFrame, ATTACH_DURATION, function(): boolean
		local currentPart = attachedPart
		return not currentPart or not currentPart.Parent
	end, function(): () end)
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

	runArcTransition(currentTransition, startCFrame, targetCFrame, arcCFrame, DETACH_DURATION, function(): boolean
		return false
	end, function(): ()
		attachedPart = nil
		isDetaching = false

		-- ВОТ ЗДЕСЬ, И ТОЛЬКО ЗДЕСЬ,
		-- включается FirstPerson.
		enableFirstPersonInternal()
	end)
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
