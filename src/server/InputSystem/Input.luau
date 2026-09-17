local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GoodSignal = require(ReplicatedStorage.Packages.GoodSignal)
local InputSystemTypes = require(ReplicatedStorage.Shared.InputSystem.InputSystemTypes)

local Input = {}
Input.__index = Input

export type Input = typeof(setmetatable(
	{} :: {
		Started: GoodSignal.Signal<InputSystemTypes.InputContext>,
		Ended: GoodSignal.Signal<InputSystemTypes.InputContext>,
		Switched: GoodSignal.Signal<InputSystemTypes.InputContext>,

		isStarted: boolean,
	},
	Input
))

function Input.new(): Input
	return setmetatable({
		Started = GoodSignal.new(),
		Ended = GoodSignal.new(),
		Switched = GoodSignal.new(),
		isStarted = false,
	}, Input)
end

function Input.begin(self: Input, context: InputSystemTypes.InputContext): ()
	if self.isStarted then
		return
	end

	self.isStarted = true
	self.Switched:Fire(context)
	self.Started:Fire(context)
end

function Input.finish(self: Input, context: InputSystemTypes.InputContext): ()
	if not self.isStarted then
		return
	end

	self.isStarted = false
	self.Switched:Fire(context)
	self.Ended:Fire(context)
end

return Input
