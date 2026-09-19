--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Networker = require(ReplicatedStorage.Packages.Networker).client

local BinNetworker = {}

local networker = Networker.new("BinService", BinNetworker)

function BinNetworker.putItemInBin(bin: Model, slotId: number): ()
	networker:fetch("putItemInBin", bin, slotId)
end

function BinNetworker.takeItemFromBin(bin: Model, itemInstance: Instance): ()
	networker:fetch("takeItemFromBin", bin, itemInstance)
end

function BinNetworker.dropBin(bin: Model): ()
	networker:fetch("dropBin", bin)
end

function BinNetworker:binPickedUp(binName: string): ()
	print("BIN PICKED UP:", binName)

	local bin = require(script.Parent.ItemBin)

	bin.onPickedUp(binName)
end

function BinNetworker:binFilled(binName: string): ()
	print("BIN FILLED:", binName)

	local bin = require(script.Parent.ItemBin)

	bin.onFilled(binName)
end

return BinNetworker
