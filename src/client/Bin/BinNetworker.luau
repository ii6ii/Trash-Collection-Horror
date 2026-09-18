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

return BinNetworker
