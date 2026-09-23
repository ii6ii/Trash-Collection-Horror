--!strict

export type Config = {
	TweenDuration: number,
	DarknessDensity: number,
	DarknessColor: Color3,
}

local BasementDarknessConfig: Config = {
	TweenDuration = 1,
	DarknessDensity = 1,
	DarknessColor = Color3.new(0, 0, 0),
}

return BasementDarknessConfig
