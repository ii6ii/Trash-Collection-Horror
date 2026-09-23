--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Networker = require(ReplicatedStorage.Packages.Networker).client

local sounds: { [string]: Sound } = {}

local SoundServiceClient = {}

function SoundServiceClient.init(): ()
	Networker.new("SoundService", SoundServiceClient)
end

function SoundServiceClient:Play(trackingId: string, assetId: string, timePosition: number, volume: number): ()
	local sound = Instance.new("Sound")
	sound.SoundId = assetId
	sound.TimePosition = timePosition
	sound.Parent = SoundService
	sound.Volume = volume

	sounds[trackingId] = sound

	sound:Play()

	sound.Ended:Once(function()
		if sounds[trackingId] == sound then
			sounds[trackingId] = nil
		end

		sound:Destroy()
	end)
end

function SoundServiceClient:StopSound(trackingId: string): ()
	local sound = sounds[trackingId]
	if not sound then
		return
	end

	sounds[trackingId] = nil
	sound:Destroy()
end

return SoundServiceClient
