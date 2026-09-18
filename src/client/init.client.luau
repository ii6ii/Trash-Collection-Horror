local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local CharacterAnimator = require(script.Animator.CharacterAnimator)
local BinGui = require(script.Bin.BinGui)
local CameraController = require(script.Camera.CameraController)
local InputSystem = require(script.InputSystem.InputSystem)
local InventoryGui = require(script.Inventory.InventoryGui)
local SoundServiceClient = require(script.Sound.SoundServiceClient)
local BinController = require(script.Bin.BinController)
--local InertialMovement = require(script.Movment.InertialMovement)

BinGui.init()
InventoryGui.init()
InputSystem.init()
SoundServiceClient.init()
BinController.init()

local function initCharacter(character: Model)
	CameraController.onCharacterAdded(character)
	CameraController.enableFirstPerson()
	--InertialMovement.Enable()
end

local LOCAL_PLAYER = Players.LocalPlayer :: Player
if LOCAL_PLAYER.Character then
	initCharacter(LOCAL_PLAYER.Character)
end
LOCAL_PLAYER.CharacterAdded:Connect(function(character: Model)
	initCharacter(character)
end)
