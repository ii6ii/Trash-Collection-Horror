--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local SoundService = require(ServerScriptService.Server.Core.Sound.SoundService)
local InventoryTypes = require(ReplicatedStorage.Shared.Types.InventoryTypes)
local SoundConfig = require(ReplicatedStorage.Shared.Config.SoundConfig)
local BaseTrashBagState = require(ServerScriptService.Server.Features.Items.TrashBag.States.BaseTrashBagState)
local TrashBagAnimator = require(ServerScriptService.Server.Features.Items.TrashBag.TrashBagAnimator)
local TrashBagTyer = require(ServerScriptService.Server.Features.Items.TrashBag.TrashBagTyer)
local TrashBagTypes = require(ServerScriptService.Server.Features.Items.TrashBag.TrashBagTypes)

local TrashBagTyingState = {}
TrashBagTyingState.__index = TrashBagTyingState

setmetatable(TrashBagTyingState, BaseTrashBagState)

export type TrashBagTyingState = typeof(setmetatable(
	{} :: TrashBagTypes.TrashBagState & { soundId: string },
	TrashBagTyingState
))

function TrashBagTyingState.new(trashBag: TrashBagTypes.TrashBag): TrashBagTypes.TrashBagState
	local self: any
	self = BaseTrashBagState.new(trashBag, {
		EInputSwitch = function()
			if self.context.trashInside == self.context.capacity then
				return
			end
			self.context:switchState(self.context.allStates.untying)
		end,
	})
	return setmetatable(self, TrashBagTyingState)
end

function TrashBagTyingState.onEnter(self: TrashBagTyingState)
	TrashBagTyer.tie(self.context)
	TrashBagTyer.getData(self.context).tieFinished:Once(function()
		self.context:switchState(self.context.allStates.tied)
	end)
	TrashBagAnimator.playTieAnimation(self.context.instance.Model)
	if not self.context.owner then
		return
	end
	self.soundId = SoundService.Play(self.context.owner, SoundConfig.trashTie)
end

function TrashBagTyingState.onExit(self: TrashBagTyingState)
	TrashBagAnimator.stop(self.context.instance.Model)
	if not self.soundId then
		return
	end
	if not self.context.owner then
		return
	end
	SoundService.StopSound(self.context.owner, self.soundId)
end

function TrashBagTyingState.getItemData(self: TrashBagTyingState): InventoryTypes.ItemData
	return self:buildItemData(false)
end

return TrashBagTyingState
