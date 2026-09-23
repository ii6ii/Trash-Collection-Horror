--!strict

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Networker = require(ReplicatedStorage.Packages.Networker).server
local SoundConfig = require(ReplicatedStorage.Shared.Config.SoundConfig)

local SoundService = {}

local networker: any

function SoundService.init(): ()
	networker = Networker.new("SoundService")
end

function SoundService.Play(player: Player, config: SoundConfig.SoundData): string
	local soundId = HttpService:GenerateGUID(false)

	networker:fire(player, "Play", soundId, config.id, config.timePosition, config.volume)

	return soundId
end

function SoundService.StopSound(player: Player, soundId: string): ()
	networker:fire(player, "StopSound", soundId)
end

return SoundService
