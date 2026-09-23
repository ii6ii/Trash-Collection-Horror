local Players = game:GetService("Players")

local AnimationsPreloader = require(script.Core.AnimationsPreloader)
local CharacterAnimator = require(script.Core.Animator.CharacterAnimator)
local BinGui = require(script.Features.Bin.BinGui)
local CameraController = require(script.Core.Camera.CameraController)
local InputSystem = require(script.Core.InputSystem.InputSystem)
local InventoryGui = require(script.Features.Inventory.InventoryGui)
local SoundServiceClient = require(script.Core.Sound.SoundServiceClient)
local BinController = require(script.Features.Bin.BinController)
local TrashBagGiverController = require(script.Features.Items.TrashBag.TrashBagGiverController)
local BasementDarkness = require(script.World.BasementDarkness)
local Timer = require(script.UI.Timer)

CharacterAnimator.init()
CameraController.init()
AnimationsPreloader.init()
BinGui.init()
InventoryGui.init()
InputSystem.init()
SoundServiceClient.init()
BinController.init()
TrashBagGiverController.init()
BasementDarkness.init()
Timer.init()

local function initCharacter(character: Model)
	CameraController.onCharacterAdded(character)
	CameraController.enableFirstPerson()
end

local LOCAL_PLAYER = Players.LocalPlayer :: Player
if LOCAL_PLAYER.Character then
	initCharacter(LOCAL_PLAYER.Character)
end
LOCAL_PLAYER.CharacterAdded:Connect(function(character: Model)
	initCharacter(character)
end)
