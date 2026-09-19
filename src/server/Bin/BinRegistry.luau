--!strict

local BinRegistry = {}

local bins: { [Instance]: ItemBin } = {}
local pickupCallback: ((Player, Model) -> ())?

export type ItemBin = any

function BinRegistry.Register(instance: Instance, bin: ItemBin): ()
	bins[instance] = bin
end

function BinRegistry.Get(instance: Instance): ItemBin?
	return bins[instance]
end

function BinRegistry.Unregister(instance: Instance): ()
	bins[instance] = nil
end

function BinRegistry.SetPickupCallback(callback: (Player, Model) -> ()): ()
	pickupCallback = callback
end

function BinRegistry.NotifyPickedUp(player: Player, bin: Model): ()
	if pickupCallback then
		pickupCallback(player, bin)
	end
end

return BinRegistry
