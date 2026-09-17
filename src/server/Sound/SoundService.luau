--!strict

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Networker = require(ReplicatedStorage.Packages.Networker).server
local SoundConfig = require(ReplicatedStorage.Shared.Sound.SoundConfig)

local SoundService = {}

local networker = Networker.new("SoundService")

function SoundService.Play(player: Player, config: SoundConfig.SoundData): string
	local soundId = HttpService:GenerateGUID(false)

	print("FIRE")
	networker:fire(player, "Play", soundId, config.id, config.timePosition, config.volume)

	return soundId
end

function SoundService.StopSound(player: Player, soundId: string): ()
	networker:fire(player, "StopSound", soundId)
end

return SoundService
