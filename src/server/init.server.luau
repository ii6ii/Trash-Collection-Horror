local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local CharacterAnimator = require(script.Core.Animator.CharacterAnimator)
local CameraController = require(script.Core.Camera.CameraController)
local InputSystem = require(script.Core.InputSystem.InputSystem)
local MovementController = require(script.Core.Movement.MovementController)
local SoundService = require(script.Core.Sound.SoundService)
local UsableItemsController = require(script.Core.UsableItems.UsableItemsController)
local ItemCollector = require(script.Core.ItemCollector.ItemCollector)

local BinController = require(script.Features.Bin.BinController)
local BinService = require(script.Features.Bin.BinService)
local Inventory = require(script.Features.Inventory.Inventory)
local UnpackableTrash = require(script.Features.Items.UnpackableTrash.UnpackableTrash)
local TrashBag = require(script.Features.Items.TrashBag.TrashBag)
local TrashBagGiver = require(script.Features.Items.TrashBag.TrashBagGiver)
local TrashBagTyer = require(script.Features.Items.TrashBag.TrashBagTyer)

local TrashInitializer = require(script.World.TrashInitializer)

local RunTests = require(script.Tests.RunTests)

CharacterAnimator.init()
CameraController.init()
InputSystem.init()
MovementController.init()
SoundService.init()

BinController.init()
BinService.init()
Inventory.init()
TrashBagTyer.init()

TrashInitializer.init()

RunTests.init()

Players.PlayerAdded:Connect(function(player: Player)
	UsableItemsController.new(player)
	ItemCollector.new(player)
	MovementController.initPlayer(player)

	player.CharacterAdded:Connect(function(character: Model)
		UnpackableTrash.new(Workspace.CardboardBox, "bigBox", 6)
		UnpackableTrash.new(Workspace.Cardboard, "cardboard", 2)
	end)

	-- Надетые в руки предметы запаренчены прямо в Character. Движок уничтожает
	-- Character (и всё, что к нему приварено/запарентено) при смерти, респавне и
	-- при выходе игрока - CharacterRemoving стреляет ДО этого удаления, пока
	-- предметы ещё живы, поэтому именно здесь их нужно вернуть в мир, а не в
	-- CharacterAdded/PlayerRemoving, когда старый Character уже может быть мёртв.
	player.CharacterRemoving:Connect(function(character: Model)
		Inventory.clearPlayerInventory(player, "Respawn")
	end)
end)

Players.PlayerRemoving:Connect(function(player: Player)
	UsableItemsController.getPlayerController(player):destroy()
	ItemCollector.getPlayerCollector(player):destroy()
	MovementController.destroyPlayer(player)
	InputSystem.destroyPlayer(player)
	Inventory.getPlayerInventory(player):destroy()
end)

TrashBagGiver.init(5, Vector3.new(0, 0, -1))
