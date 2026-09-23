--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GoodSignal = require(ReplicatedStorage.Packages.GoodSignal)
local Networker = require(ReplicatedStorage.Packages.Networker).client

local BinNetworker = {}

-- Сигналы вместо прямого require(ItemBin): ItemBin и так зависит от
-- BinNetworker (чтобы слать put/take/drop), а BinNetworker -> ItemBin ->
-- BinGui -> BinNetworker образовало бы цикл require.
BinNetworker.PickedUp = GoodSignal.new() :: GoodSignal.Signal<string>
BinNetworker.Filled = GoodSignal.new() :: GoodSignal.Signal<string>

local networker: any

function BinNetworker.init(): ()
	networker = Networker.new("BinService", BinNetworker)
end

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
	BinNetworker.PickedUp:Fire(binName)
end

function BinNetworker:binFilled(binName: string): ()
	BinNetworker.Filled:Fire(binName)
end

return BinNetworker
