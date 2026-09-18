--!strict

local BinRegistry = {}

local bins: { [Instance]: ItemBin } = {}

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

return BinRegistry
