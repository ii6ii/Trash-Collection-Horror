--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local InventoryTypes = require(ReplicatedStorage.Shared.Types.InventoryTypes)
local Inventory = require(ServerScriptService.Server.Features.Inventory.Inventory)
local InventoryItemRegistry = require(ServerScriptService.Server.Features.Inventory.InventoryItemRegistry)
local SoundService = require(ServerScriptService.Server.Core.Sound.SoundService)
local PartUtils = require(ReplicatedStorage.Shared.Utils.PartUtils)
local SoundConfig = require(ReplicatedStorage.Shared.Config.SoundConfig)
local BaseTrashBagState = require(ServerScriptService.Server.Features.Items.TrashBag.States.BaseTrashBagState)
local TrashBagTypes = require(ServerScriptService.Server.Features.Items.TrashBag.TrashBagTypes)

local TrashBagOnGroundState = {}
TrashBagOnGroundState.__index = TrashBagOnGroundState

setmetatable(TrashBagOnGroundState, BaseTrashBagState)

export type TrashBagOnGroundState = typeof(setmetatable({} :: TrashBagTypes.TrashBagState, TrashBagOnGroundState))

function TrashBagOnGroundState.new(trashBag: TrashBagTypes.TrashBag): TrashBagTypes.TrashBagState
	local self = BaseTrashBagState.new(trashBag, {}) :: any
	return setmetatable(self, TrashBagOnGroundState)
end

function TrashBagOnGroundState.onEnter(self): ()
	local item = InventoryItemRegistry.get(self.context.instance) :: InventoryTypes.Item

	if not self.context.owner then
		return
	end

	local owner = self.context.owner

	-- На дисконнекте движок мог уничтожить instance вместе с Character раньше
	-- нашей очистки инвентаря - тогда дочерней "Model" части уже нет.
	local model = self.context.instance:FindFirstChild("Model") :: BasePart?

	if not model then
		Inventory.getPlayerInventory(owner):removeItem(item)
		return
	end

	if not PartUtils.CanPlace(model, 1) then
		return
	end

	SoundService.Play(owner, SoundConfig.trashDrop)

	Inventory.getPlayerInventory(owner):removeItem(item)
	PartUtils.placeOnGround(model, 1)
end

function TrashBagOnGroundState.onEquipped(self: TrashBagOnGroundState): ()
	self.context:switchState(self.context.lastState)
end

function TrashBagOnGroundState.getItemData(self: TrashBagOnGroundState)
	return self.context.lastState:getItemData()
end

return TrashBagOnGroundState
