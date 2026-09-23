--!strict

export type Config = {
	ItemCollectRayDistance: number,
}

local InteractionConfig: Config = {
	-- ItemCollector: максимальная дистанция подбора предмета взглядом (F).
	ItemCollectRayDistance = 10,
}

return InteractionConfig
