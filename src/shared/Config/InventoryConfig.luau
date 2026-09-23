--!strict

export type Config = {
	HandsCapacity: number,
	BackpackCapacity: number,
	TotalSlots: number,
	LockTransparency: number,
}

local HANDS_CAPACITY = 2
local BACKPACK_CAPACITY = 3

local InventoryConfig: Config = {
	HandsCapacity = HANDS_CAPACITY,
	BackpackCapacity = BACKPACK_CAPACITY,
	TotalSlots = HANDS_CAPACITY + BACKPACK_CAPACITY,
	LockTransparency = 0.7,
}

return InventoryConfig
