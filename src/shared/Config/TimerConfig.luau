--!strict

export type Config = {
	DurationSeconds: number,
}

local TimerConfig: Config = {
	DurationSeconds = 6 * 60,
}

return TimerConfig
