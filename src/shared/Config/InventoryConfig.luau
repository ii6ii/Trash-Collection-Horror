--!strict

export type Config = {
	HandsCapacity: number,
	BackpackCapacity: number,
	TotalSlots: number,
	LockTransparency: number,

	-- Предметы с size >= TwoHandedMinSize занимают оба слота рук и держатся
	-- между кистями (InventoryView, TwoHandedGrip). Настройки самого хвата -
	-- в GripConfig.
	TwoHandedMinSize: number,

	-- Хват одной рукой: поворот (градусы) относительно самой руки. Позиция не
	-- настраивается - она привязана к руке напрямую, это уже учитывает рост/
	-- пропорции конкретной модели игрока.
	OneHandedGripRotation: Vector3,
}

local HANDS_CAPACITY = 2
local BACKPACK_CAPACITY = 3

local InventoryConfig: Config = {
	HandsCapacity = HANDS_CAPACITY,
	BackpackCapacity = BACKPACK_CAPACITY,
	TotalSlots = HANDS_CAPACITY + BACKPACK_CAPACITY,
	LockTransparency = 0.7,

	TwoHandedMinSize = 2,
	OneHandedGripRotation = Vector3.new(-90, 0, 0),
}

return InventoryConfig
