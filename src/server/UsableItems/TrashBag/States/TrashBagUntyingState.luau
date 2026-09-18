--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local SoundService = require(ServerScriptService.Server.Sound.SoundService)
local InventoryTypes = require(ReplicatedStorage.Shared.Inventroy.InventoryTypes)
local ItemConfig = require(ReplicatedStorage.Shared.Inventroy.ItemConfig)
local SoundConfig = require(ReplicatedStorage.Shared.Sound.SoundConfig)
local BaseTrashBagState = require(ServerScriptService.Server.UsableItems.TrashBag.States.BaseTrashBagState)
local TrashBagAnimator = require(ServerScriptService.Server.UsableItems.TrashBag.TrashBagAnimator)
local TrashBagTyer = require(ServerScriptService.Server.UsableItems.TrashBag.TrashBagTyer)
local TrashBagTypes = require(ServerScriptService.Server.UsableItems.TrashBag.TrashBagTypes)

local TrashBagUntyingState = {}
TrashBagUntyingState.__index = TrashBagUntyingState

setmetatable(TrashBagUntyingState, BaseTrashBagState)

export type TrashBagUntyingState = typeof(setmetatable(
	{} :: TrashBagTypes.TrashBagState & { soundId: string },
	TrashBagUntyingState
))

function TrashBagUntyingState.new(trashBag: TrashBagTypes.TrashBag): TrashBagTypes.TrashBagState
	local self: any
	self = BaseTrashBagState.new(trashBag, {
		EInputSwitch = function()
			self.context:switchState(self.context.allStates.tying)
		end,
	})
	return setmetatable(self, TrashBagUntyingState)
end

function TrashBagUntyingState.onEnter(self: TrashBagUntyingState)
	TrashBagTyer.untie(self.context)
	TrashBagTyer.getData(self.context).untieFinished:Once(function()
		self.context:switchState(self.context.allStates.withTrash)
	end)
	TrashBagAnimator.playTieAnimation(self.context.instance.Model)
	print("===switched to UNTYING state===")
	if not self.context.owner then
		return
	end
	self.soundId = SoundService.Play(self.context.owner, SoundConfig.trashTie)
end

function TrashBagUntyingState.onExit(self: TrashBagUntyingState)
	TrashBagAnimator.stop(self.context.instance.Model)
	if not self.soundId then
		return
	end
	if not self.context.owner then
		return
	end
	SoundService.StopSound(self.context.owner, self.soundId)
end

function TrashBagUntyingState.getItemData(self: TrashBagUntyingState): InventoryTypes.ItemData
	local config = ItemConfig.trashBag
	return {
		attachment = self.context.attachment,
		instance = self.context.instance,
		type = config.type,
		weight = self.context:getWeight(),
		size = config.size,
		canTakeInHands = true,
		canPutInBackpack = false,
	}
end

return TrashBagUntyingState
