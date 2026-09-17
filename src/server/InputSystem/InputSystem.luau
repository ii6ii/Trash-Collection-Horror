local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InputSystemTypes = require(ReplicatedStorage.Shared.InputSystem.InputSystemTypes)
local Input = require(script.Parent.Input)
local Networker = require(ReplicatedStorage.Packages.Networker).server

export type PlayerInputs = {
	EInput: Input.Input,
	GInput: Input.Input,
	FInput: Input.Input,
	SprintInput: Input.Input,
}

local playerInputs: { [Player]: PlayerInputs } = {}

local InputSystem = {}

function InputSystem.init()
	Networker.new("InputSystem", InputSystem, { InputSystem.beginInput, InputSystem.endInput })
end

function InputSystem.initPlayer(player: Player)
	playerInputs[player] = {
		EInput = Input.new(),
		GInput = Input.new(),
		FInput = Input.new(),
		SprintInput = Input.new(),
	}
end

function InputSystem.getInput(player: Player, name: string): Input.Input
	if not playerInputs[player] then
		InputSystem.initPlayer(player)
	end

	return (playerInputs[player] :: { [string]: Input.Input })[name]
end

function InputSystem:beginInput(player: Player, inputContext: InputSystemTypes.InputContext): ()
	InputSystem.getInput(player, inputContext.name):begin(inputContext)
end

function InputSystem:endInput(player: Player, inputContext: InputSystemTypes.InputContext): ()
	InputSystem.getInput(player, inputContext.name):finish(inputContext)
end

function InputSystem.getInputs(player: Player): PlayerInputs
	if not playerInputs[player] then
		InputSystem.initPlayer(player)
	end

	return playerInputs[player]
end

return InputSystem
