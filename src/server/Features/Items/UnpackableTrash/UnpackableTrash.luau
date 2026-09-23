--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Inventory = require(ServerScriptService.Server.Features.Inventory.Inventory)
local InventoryItemRegistry = require(ServerScriptService.Server.Features.Inventory.InventoryItemRegistry)
local UsableItemsRegistry = require(ServerScriptService.Server.Core.UsableItems.UsableItemsRegistry)
local InputSystemTypes = require(ReplicatedStorage.Shared.Types.InputSystemTypes)
local InventoryTypes = require(ReplicatedStorage.Shared.Types.InventoryTypes)
local ItemConfig = require(ReplicatedStorage.Shared.Config.ItemConfig)
local PartUtils = require(ReplicatedStorage.Shared.Utils.PartUtils)

local UnpackableTrash = {}
UnpackableTrash.__index = UnpackableTrash
UnpackableTrash.allTrash = {}

export type UnpackableTrash = typeof(setmetatable(
	{} :: {
		instance: Model,
		owner: Player?,
		attachment: Attachment?,
		config: ItemConfig.Config,
		weight: number,
	},
	UnpackableTrash
))

function UnpackableTrash.new(instance: Model, type: string, weight: number): UnpackableTrash
	local config = ItemConfig[type]

	assert(config, `Unknown UnpackableTrash type: {type}`)

	local self = setmetatable({
		instance = instance,
		owner = nil,
		attachment = instance:FindFirstChildOfClass("Attachment"),
		config = config,
		weight = weight,
	}, UnpackableTrash)

	InventoryItemRegistry.register(instance, self :: any)
	UsableItemsRegistry.register(instance, self :: any)

	UnpackableTrash.allTrash[instance] = self
	return self
end

function UnpackableTrash.getItemData(self: UnpackableTrash): InventoryTypes.ItemData
	return {
		type = self.config.type,
		weight = self.weight,
		size = self.config.size,
		canTakeInHands = true,
		canPutInBackpack = false,
		instance = self.instance,
		attachment = self.attachment,
	}
end

function UnpackableTrash.setOwner(self: UnpackableTrash, owner: Player?): ()
	self.owner = owner
end

function UnpackableTrash.getOwner(self: UnpackableTrash): Player?
	return self.owner
end

function UnpackableTrash.onEquipped(self: UnpackableTrash): () end

function UnpackableTrash.onUnequipped(self: UnpackableTrash): () end

function UnpackableTrash.canHandleInput(self: UnpackableTrash, context: InputSystemTypes.InputContext): boolean
	return context.name == "GInput"
end

local function dropToGround(self: UnpackableTrash): ()
	if not self.owner then
		return
	end

	Inventory.getPlayerInventory(self.owner):removeItem(self :: any)

	-- На дисконнекте движок мог уничтожить instance вместе с Character раньше
	-- нашей очистки инвентаря - тогда PrimaryPart уже нет, физически размещать нечего.
	local primaryPart = self.instance.PrimaryPart

	if not primaryPart then
		return
	end

	PartUtils.placeOnGround(primaryPart, 1)
end

function UnpackableTrash.handleInputStart(self: UnpackableTrash, context: InputSystemTypes.InputContext): ()
	if context.name ~= "GInput" then
		return
	end

	dropToGround(self)
end

function UnpackableTrash.onInventoryCleared(self: UnpackableTrash, reason: InventoryTypes.ClearReason): ()
	dropToGround(self)
end

function UnpackableTrash.handleInputEnd(self: UnpackableTrash, context: InputSystemTypes.InputContext): () end

function UnpackableTrash.handleInputSwitch(self: UnpackableTrash, context: InputSystemTypes.InputContext): () end

return UnpackableTrash
