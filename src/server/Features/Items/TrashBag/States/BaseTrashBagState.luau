--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local InputSystemTypes = require(ReplicatedStorage.Shared.Types.InputSystemTypes)
local InventoryTypes = require(ReplicatedStorage.Shared.Types.InventoryTypes)
local ItemConfig = require(ReplicatedStorage.Shared.Config.ItemConfig)
local TrashBagTypes = require(ServerScriptService.Server.Features.Items.TrashBag.TrashBagTypes)

local BaseTrashBagState = {}
BaseTrashBagState.__index = BaseTrashBagState

export type BaseTrashBagState = typeof(setmetatable(
	{} :: {
		inputActions: { [string]: (self: TrashBagTypes.TrashBag, context: InputSystemTypes.InputContext) -> () },
		context: TrashBagTypes.TrashBag,
	},
	BaseTrashBagState
))

function BaseTrashBagState.new(
	trashBag: TrashBagTypes.TrashBag,
	inputActions: {
		[string]: (self: TrashBagTypes.TrashBag, context: InputSystemTypes.InputContext) -> (),
	}
): BaseTrashBagState
	return setmetatable({
		context = trashBag,
		inputActions = inputActions,
	}, BaseTrashBagState)
end

function BaseTrashBagState.onEnter(self: BaseTrashBagState): ()
	return
end

function BaseTrashBagState.onExit(self: BaseTrashBagState): ()
	return
end

function BaseTrashBagState.onEquipped(self: BaseTrashBagState): ()
	return
end

function BaseTrashBagState.onUnequipped(self: BaseTrashBagState): ()
	return
end

function BaseTrashBagState.handleInputStart(self: BaseTrashBagState, context: InputSystemTypes.InputContext): ()
	local action = self.inputActions[context.name .. "Start"]
	if not action then
		return
	end
	action(self.context, context)
end

function BaseTrashBagState.handleInputEnd(self: BaseTrashBagState, context: InputSystemTypes.InputContext): ()
	local action = self.inputActions[context.name .. "End"]
	if not action then
		return
	end
	action(self.context, context)
end

function BaseTrashBagState.handleInputSwitch(self: BaseTrashBagState, context: InputSystemTypes.InputContext): ()
	local action = self.inputActions[context.name .. "Switch"]
	if not action then
		return
	end
	action(self.context, context)
end

function BaseTrashBagState.canHandleInput(self: BaseTrashBagState, context: InputSystemTypes.InputContext): boolean
	return self.inputActions[context.name .. "Start"] ~= nil
		or self.inputActions[context.name .. "End"] ~= nil
		or self.inputActions[context.name .. "Switch"] ~= nil
end

-- Общий билдер ItemData: все состояния пакета отличаются друг от друга
-- только тем, можно ли в этом состоянии положить пакет в рюкзак
-- (завязанный/с мусором - нельзя, обычный - можно).
function BaseTrashBagState.buildItemData(self: BaseTrashBagState, canPutInBackpack: boolean): InventoryTypes.ItemData
	local config = ItemConfig.trashBag

	return {
		attachment = self.context.attachment,
		instance = self.context.instance,
		type = config.type,
		weight = self.context:getWeight(),
		size = config.size,
		canTakeInHands = true,
		canPutInBackpack = canPutInBackpack,
	}
end

function BaseTrashBagState.getItemData(self: BaseTrashBagState): InventoryTypes.ItemData
	return self:buildItemData(true)
end

return BaseTrashBagState
