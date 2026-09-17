local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local PLAYER = Players.LocalPlayer
local CAMERA = workspace.CurrentCamera

local CAMERA_OFFSET = Vector3.new(0, 0.95, 0)

local SENSITIVITY = 0.003
local MIN_PITCH = math.rad(-80)
local MAX_PITCH = math.rad(80)

local HEAD_TRANSPARENCY = 0
local ACCESSORY_TRANSPARENCY = 1
local BODY_TRANSPARENCY = 0

local cameraRotation = Vector2.zero

local inputConnection: RBXScriptConnection?

UserInputService.MouseIconEnabled = false

local function setCharacterTransparency(character: Model)
	for _, descendant in character:GetDescendants() do
		if descendant:IsA("BasePart") then
			if descendant.Name == "Head" then
				descendant.LocalTransparencyModifier = HEAD_TRANSPARENCY
				descendant.CastShadow = true
			elseif descendant.Parent:IsA("Accessory") then
				descendant.LocalTransparencyModifier = ACCESSORY_TRANSPARENCY
				descendant.CastShadow = true
			else
				descendant.LocalTransparencyModifier = BODY_TRANSPARENCY
			end
		elseif descendant:IsA("Decal") and descendant.Parent:IsA("BasePart") then
			if descendant.Parent.Name == "Head" then
				descendant.LocalTransparencyModifier = 1
			end
		end
	end
end

local function disconnectInput()
	if inputConnection then
		inputConnection:Disconnect()
		inputConnection = nil
	end
end

local function setupInput()
	disconnectInput()

	inputConnection = UserInputService.InputChanged:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end

		if input.UserInputType ~= Enum.UserInputType.MouseMovement then
			return
		end

		local delta = input.Delta

		cameraRotation = Vector2.new(
			math.clamp(cameraRotation.X - delta.Y * SENSITIVITY, MIN_PITCH, MAX_PITCH),
			cameraRotation.Y - delta.X * SENSITIVITY
		)
	end)
end

local function setupFirstPersonCamera(character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	local head = character:WaitForChild("Head") :: BasePart
	local humanoidRootPart = character:WaitForChild("HumanoidRootPart") :: BasePart

	RunService:UnbindFromRenderStep("FirstPersonCamera")

	humanoid.AutoRotate = false

	CAMERA.CameraType = Enum.CameraType.Scriptable
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter

	setCharacterTransparency(character)

	cameraRotation = Vector2.zero

	setupInput()

	RunService:BindToRenderStep("FirstPersonCamera", Enum.RenderPriority.Camera.Value, function()
		if not character.Parent then
			return
		end

		if not head.Parent or not humanoidRootPart.Parent then
			return
		end

		local cameraCFrame = CFrame.new(head.Position)
			* CFrame.Angles(0, cameraRotation.Y, 0)
			* CFrame.Angles(cameraRotation.X, 0, 0)
			* CFrame.new(CAMERA_OFFSET)

		CAMERA.CFrame = cameraCFrame

		humanoidRootPart.CFrame = CFrame.new(humanoidRootPart.Position) * CFrame.Angles(0, cameraRotation.Y, 0)
	end)
end

local function onCharacterAdded(character: Model)
	RunService:UnbindFromRenderStep("FirstPersonCamera")
	disconnectInput()

	character:WaitForChild("Humanoid")
	character:WaitForChild("Head")
	character:WaitForChild("HumanoidRootPart")

	task.wait(0.1)

	if character.Parent then
		setupFirstPersonCamera(character)
	end
end

if PLAYER.Character then
	onCharacterAdded(PLAYER.Character)
end

PLAYER.CharacterAdded:Connect(onCharacterAdded)

PLAYER.CharacterRemoving:Connect(function()
	RunService:UnbindFromRenderStep("FirstPersonCamera")
	disconnectInput()
end)
