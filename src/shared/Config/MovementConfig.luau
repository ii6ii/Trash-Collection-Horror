--!strict

export type Config = {
	BaseWalkSpeed: number,
	SpeedLossPerWeight: number,
	SprintMultiplier: number,
	BinSpeedMultiplier: number,

	MaxSprintWeight: number,
	CameraShakeWeight: number,

	DisabledWalkSpeed: number,
}

local MovementConfig: Config = {
	BaseWalkSpeed = 16,
	SpeedLossPerWeight = 0.05,
	SprintMultiplier = 1.5,
	BinSpeedMultiplier = 0.4,

	MaxSprintWeight = 2,
	CameraShakeWeight = 12,

	DisabledWalkSpeed = 0,
}

return MovementConfig
