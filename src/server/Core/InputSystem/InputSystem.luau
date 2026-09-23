--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InputSystemTypes = require(ReplicatedStorage.Shared.Types.InputSystemTypes)
local InputConfig = require(ReplicatedStorage.Shared.Config.InputConfig)
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

local function isKnownInputName(name: any): boolean
	return typeof(name) == "string" and table.find(InputConfig, name) ~= nil
end

function InputSystem.init()
	local networker = Networker.new("InputSystem")
	networker:addClientAccess(InputSystem, { InputSystem.beginInput, InputSystem.endInput })
end

function InputSystem.initPlayer(player: Player)
	playerInputs[player] = {
		EInput = Input.new(),
		GInput = Input.new(),
		FInput = Input.new(),
		SprintInput = Input.new(),
	}
end

function InputSystem.getInput(player: Player, name: InputSystemTypes.InputName): Input.Input
	if not playerInputs[player] then
		InputSystem.initPlayer(player)
	end

	return (playerInputs[player] :: { [string]: Input.Input })[name]
end

-- Точка входа с клиента: inputContext.name - недоверенная строка,
-- неизвестное имя молча игнорируется вместо падения callback'а.
function InputSystem:beginInput(player: Player, inputContext: InputSystemTypes.InputContext): ()
	if not isKnownInputName(inputContext.name) then
		return
	end

	InputSystem.getInput(player, inputContext.name :: InputSystemTypes.InputName):begin(inputContext)
end

function InputSystem:endInput(player: Player, inputContext: InputSystemTypes.InputContext): ()
	if not isKnownInputName(inputContext.name) then
		return
	end

	InputSystem.getInput(player, inputContext.name :: InputSystemTypes.InputName):finish(inputContext)
end

function InputSystem.getInputs(player: Player): PlayerInputs
	if not playerInputs[player] then
		InputSystem.initPlayer(player)
	end

	return playerInputs[player]
end

function InputSystem.destroyPlayer(player: Player): ()
	local inputs = playerInputs[player]

	if not inputs then
		return
	end

	for _, input in inputs :: { [string]: Input.Input } do
		input:destroy()
	end

	playerInputs[player] = nil
end

return InputSystem
