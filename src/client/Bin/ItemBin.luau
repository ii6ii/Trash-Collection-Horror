--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ZonePlus = require(ReplicatedStorage.Packages.ZonePlus)

local BinInteraction = require(script.Parent.BinInteraction)
local BinGui = require(script.Parent.BinGui)

local ItemBin = {}
ItemBin.__index = ItemBin
ItemBin.allBins = {} :: { [Model]: ItemBin }

export type ItemBin = typeof(setmetatable(
	{} :: {
		instance: Model,
		zone: any,
		cameraPosition: BasePart,
	},
	ItemBin
))

function ItemBin.new(instance: Model): ItemBin
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
		BinInteraction.exit()
		BinGui.hide()
	end)

	ItemBin.allBins[instance] = self

	return self
end

function ItemBin.getInstance(self: ItemBin): Model
	return self.instance
end

function ItemBin.destroy(self: ItemBin): ()
	self.zone:destroy()
end

return ItemBin
