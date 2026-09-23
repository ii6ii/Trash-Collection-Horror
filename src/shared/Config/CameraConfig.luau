--!strict

export type Config = {
	AttachDuration: number,
	DetachDuration: number,
	AttachStartOffset: Vector3,
	AttachArcHeight: number,
	AttachStartRotation: Vector3,

	FirstPersonSensitivity: number,
	FirstPersonMinPitch: number,
	FirstPersonMaxPitch: number,
	FirstPersonCameraOffset: Vector3,

	ShakeTimeSpeed: number,
	ShakePositionAmplitudeX: number,
	ShakePositionAmplitudeY: number,
	ShakePositionOffsetX: number,
	ShakeRotationAmplitude: number,
}

local CameraConfig: Config = {
	-- Attach/detach dolly-анимация (BinInteraction).
	AttachDuration = 0.45,
	DetachDuration = 0.35,
	AttachStartOffset = Vector3.new(0, -2.5, 5),
	AttachArcHeight = 0.8,
	AttachStartRotation = Vector3.new(20, 0, 0),

	-- Камера от первого лица.
	FirstPersonSensitivity = 0.003,
	FirstPersonMinPitch = math.rad(-80),
	FirstPersonMaxPitch = math.rad(80),
	FirstPersonCameraOffset = Vector3.new(0, 0.95, 0),

	-- Тряска камеры (перегруз инвентаря).
	ShakeTimeSpeed = 2.5,
	ShakePositionAmplitudeX = 0.4,
	ShakePositionAmplitudeY = 0.03,
	ShakePositionOffsetX = -0.1,
	ShakeRotationAmplitude = 0.035,
}

return CameraConfig
