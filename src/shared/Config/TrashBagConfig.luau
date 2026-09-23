--!strict

export type Config = {
	Capacity: number,
	WeightPerTrash: number,

	EmptySizeScale: number,
	TrashSizeScale: number,

	TieDuration: number,
	TieAnimationDuration: number,
	TieAnimationXScale: number,
	TieAnimationYScale: number,
	TieAnimationZScale: number,

	TrashPerBag: number,
	BagDistance: number,
}

local TrashBagConfig: Config = {
	Capacity = 5,
	WeightPerTrash = 1,

	EmptySizeScale = 0.1,
	TrashSizeScale = 0.18,

	TieDuration = 1,
	TieAnimationDuration = 0.3,
	TieAnimationXScale = 0.8,
	TieAnimationYScale = 0.95,
	TieAnimationZScale = 0.8,

	-- TrashBagGiver: сколько мешков нужно на TrashPerBag единиц цели уборки,
	-- и расстояние между спавнящимися мешками.
	TrashPerBag = 5,
	BagDistance = 1.2,
}

return TrashBagConfig
