--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InventoryTypes = require(ReplicatedStorage.Shared.Types.InventoryTypes)

local InventorySlot = {}
InventorySlot.__index = InventorySlot

export type LockData = {
	locked: boolean,
	lockedBy: InventoryTypes.Item?,
}

export type InventorySlot = typeof(setmetatable(
	{} :: {
		item: InventoryTypes.Item?,
		lockData: LockData,
	},
	InventorySlot
))

function InventorySlot.new(): InventorySlot
	local self = setmetatable({
		item = nil,
		lockData = {
			locked = false,
			lockedBy = nil,
		},
	}, InventorySlot)
	return self
end

function InventorySlot.putItem(self: InventorySlot, item: InventoryTypes.Item): boolean
	if self.lockData.locked then
		return false
	end
	self:lockSlot(item)
	self.item = item
	return true
end

function InventorySlot.lockSlot(self: InventorySlot, locker: InventoryTypes.Item): boolean
	if self.lockData.locked then
		return false
	end
	self.lockData.locked = true
	self.lockData.lockedBy = locker
	return true
end

function InventorySlot.unlockSlot(self: InventorySlot): boolean
	if self.item then
		return false
	end
	self.lockData.locked = false
	self.lockData.lockedBy = nil
	return true
end

function InventorySlot.getItem(self: InventorySlot): InventoryTypes.Item?
	return self.item
end

function InventorySlot.removeItem(self: InventorySlot): InventoryTypes.Item?
	local item = self.item
	if item then
		self.item = nil
		self:unlockSlot()
	end
	return item
end

return InventorySlot
