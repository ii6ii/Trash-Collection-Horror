--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ZonePlus = require(ReplicatedStorage.Shared.Utils.TypedZone)

local BinInteraction = require(script.Parent.BinInteraction)
local BinGui = require(script.Parent.BinGui)
local BinNetworker = require(script.Parent.BinNetworker)

local ItemBin = {}
ItemBin.__index = ItemBin

ItemBin.allBins = {} :: { [Model]: ItemBin }

export type ItemBin = typeof(setmetatable(
	{} :: {
		instance: Model,
		zone: ZonePlus.Zone?,
		cameraPosition: BasePart,
	},
	ItemBin
))

function ItemBin.new(instance: Model): ItemBin
	if ItemBin.allBins[instance] then
		return ItemBin.allBins[instance]
	end

	local cameraPosition = instance:WaitForChild("CameraPosition") :: BasePart
	local zonePart = instance:WaitForChild("Zone") :: BasePart

	local self = setmetatable({
		instance = instance,
		zone = ZonePlus.new(zonePart),
		cameraPosition = cameraPosition,
	}, ItemBin) :: ItemBin

	self.zone.localPlayerEntered:Connect(function()
		BinInteraction.enter(self.cameraPosition)
		BinGui.show(self.instance)
	end)

	self.zone.localPlayerExited:Connect(function()
		if BinGui.isCarryingBin() then
			return
		end

		BinInteraction.exit()
		BinGui.hide()
	end)

	ItemBin.allBins[instance] = self

	return self
end

function ItemBin.getInstance(self: ItemBin): Model
	return self.instance
end

function ItemBin.disable(self: ItemBin): ()
	if not self.zone then
		return
	end

	self.zone:destroy()
	self.zone = nil
end

local function onPickedUp(binName: string): ()
	for instance in ItemBin.allBins do
		if instance.Name == binName then
			BinInteraction.exit()
			BinGui.pickUp(instance)
			return
		end
	end
end

local function onFilled(binName: string): ()
	for instance, bin in ItemBin.allBins do
		if instance.Name == binName then
			bin:disable()
		end
	end
end

function ItemBin.init(): ()
	BinNetworker.PickedUp:Connect(onPickedUp)
	BinNetworker.Filled:Connect(onFilled)
end

function ItemBin.destroy(self: ItemBin): ()
	self:disable()
	ItemBin.allBins[self.instance] = nil
end

return ItemBin
