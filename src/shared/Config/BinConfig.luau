--!strict

export type Config = {
	-- Разброс положения предмета, брошенного в Bin (ItemBin.addItem).
	ItemScatterOffsetX: number,
	ItemScatterOffsetYMin: number,
	ItemScatterOffsetYMax: number,
	ItemScatterOffsetZ: number,
	ItemScatterRotationX: number,
	ItemScatterRotationY: number,
	ItemScatterRotationZ: number,

	-- Перенос Bin игроком (BinCarryRig).
	CarryOffset: Vector3,
	CarryRotation: Vector3,
	DropOffset: Vector3,
}

local BinConfig: Config = {
	ItemScatterOffsetX = 0.3,
	ItemScatterOffsetYMin = 0,
	ItemScatterOffsetYMax = 0.2,
	ItemScatterOffsetZ = 0.3,
	ItemScatterRotationX = 20,
	ItemScatterRotationY = 360,
	ItemScatterRotationZ = 20,

	CarryOffset = Vector3.new(0, -1, -3),
	CarryRotation = Vector3.new(0, -90, 0),
	-- Относительно HumanoidRootPart игрока при сбросе: -Z = вперёд, +X = вправо, +Y = вверх.
	DropOffset = Vector3.new(0, 0, -2),
}

return BinConfig
