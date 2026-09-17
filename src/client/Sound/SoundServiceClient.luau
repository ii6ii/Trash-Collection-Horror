--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Networker = require(ReplicatedStorage.Packages.Networker).client

local sounds: { [string]: Sound } = {}

local SoundServiceClient = {}

function SoundServiceClient.init(): ()
	Networker.new("SoundService", SoundServiceClient)
end

function SoundServiceClient:Play(soundId: string, id: string, timePosition: number, volume: number): ()
	print("Played")
	local sound = Instance.new("Sound")
	sound.SoundId = id
	sound.TimePosition = timePosition
	sound.Parent = SoundService
	sound.Volume = volume

	sounds[soundId] = sound

	sound:Play()

	sound.Ended:Once(function()
		if sounds[soundId] == sound then
			sounds[soundId] = nil
		end

		sound:Destroy()
	end)
end

function SoundServiceClient:StopSound(soundId: string): ()
	local sound = sounds[soundId]
	if not sound then
		return
	end

	sounds[soundId] = nil
	sound:Destroy()
end

return SoundServiceClient
