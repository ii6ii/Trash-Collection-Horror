--!strict

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local CAMERA = workspace.CurrentCamera

local CAMERA_OFFSET = Vector3.new(0, 0.95, 0)

local SENSITIVITY = 0.003
local MIN_PITCH = math.rad(-80)
local MAX_PITCH = math.rad(80)

local HEAD_TRANSPARENCY = 0
local ACCESSORY_TRANSPARENCY = 1
local BODY_TRANSPARENCY = 0

local RENDER_NAME = "FirstPersonCamera"

local FirstPersonCamera = {}

local character: Model?
local humanoid: Humanoid?
local head: BasePart?
local humanoidRootPart: BasePart?

local enabled = false

local cameraRotation = Vector2.zero

local function setCharacterTransparency(newCharacter: Model): ()
	for _, descendant in newCharacter:GetDescendants() do
		local parent = descendant.Parent

		if descendant:IsA("BasePart") then
			if descendant.Name == "Head" then
				descendant.LocalTransparencyModifier = HEAD_TRANSPARENCY
				descendant.CastShadow = true
			elseif parent and parent:IsA("Accessory") then
				descendant.LocalTransparencyModifier = ACCESSORY_TRANSPARENCY
				descendant.CastShadow = true
			else
				descendant.LocalTransparencyModifier = BODY_TRANSPARENCY
			end
		elseif descendant:IsA("Decal") and parent and parent:IsA("BasePart") and parent.Name == "Head" then
			descendant.LocalTransparencyModifier = 1
		end
	end
end

local function getRootYaw(): number
	local currentRootPart = humanoidRootPart

	if not currentRootPart then
		return 0
	end

	local _, yaw, _ = currentRootPart.CFrame:ToOrientation()

	return yaw
end

local function updateCamera(): ()
	local currentHead = head
	local currentRootPart = humanoidRootPart

	if not currentHead or not currentRootPart then
		return
	end

	if not currentHead.Parent or not currentRootPart.Parent then
		return
	end

	-- Получаем движение мыши напрямую.
	-- Это не зависит от того, находится ли мышь над GUI.
	local mouseDelta = UserInputService:GetMouseDelta()

	if mouseDelta.Magnitude > 0 then
		cameraRotation = Vector2.new(
			math.clamp(cameraRotation.X - mouseDelta.Y * SENSITIVITY, MIN_PITCH, MAX_PITCH),
			cameraRotation.Y - mouseDelta.X * SENSITIVITY
		)
	end

	CAMERA.CFrame = CFrame.new(currentHead.Position)
		* CFrame.Angles(0, cameraRotation.Y, 0)
		* CFrame.Angles(cameraRotation.X, 0, 0)
		* CFrame.new(CAMERA_OFFSET)

	currentRootPart.CFrame = CFrame.new(currentRootPart.Position) * CFrame.Angles(0, cameraRotation.Y, 0)
end

function FirstPersonCamera.init(newCharacter: Model): ()
	character = newCharacter

	humanoid = newCharacter:WaitForChild("Humanoid") :: Humanoid
	head = newCharacter:WaitForChild("Head") :: BasePart
	humanoidRootPart = newCharacter:WaitForChild("HumanoidRootPart") :: BasePart
end

function FirstPersonCamera.enable(): ()
	if enabled then
		return
	end

	local currentCharacter = character
	local currentHumanoid = humanoid

	if not currentCharacter or not currentHumanoid then
		return
	end

	enabled = true

	currentHumanoid.AutoRotate = false

	setCharacterTransparency(currentCharacter)

	-- Камера начинает смотреть ровно туда,
	-- куда сейчас смотрит HumanoidRootPart.
	cameraRotation = Vector2.new(0, getRootYaw())

	-- ВАЖНО:
	-- блокируем курсор в центре экрана.
	-- GUI при этом всё равно может получать клики.
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	UserInputService.MouseIconEnabled = true

	RunService:BindToRenderStep(RENDER_NAME, Enum.RenderPriority.Camera.Value, updateCamera)
end

function FirstPersonCamera.disable(): ()
	if not enabled then
		return
	end

	enabled = false

	RunService:UnbindFromRenderStep(RENDER_NAME)

	UserInputService.MouseBehavior = Enum.MouseBehavior.Default

	local currentHumanoid = humanoid

	if currentHumanoid then
		currentHumanoid.AutoRotate = true
	end
end

return FirstPersonCamera
