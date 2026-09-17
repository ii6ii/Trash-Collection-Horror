local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local UsableItemsRegistry = require(script.Parent.UsableItemsRegistry)
local InputSystem = require(ServerScriptService.Server.InputSystem.InputSystem)
local Input = require(ServerScriptService.Server.InputSystem.Input)
local Inventory = require(ServerScriptService.Server.Inventory.Inventory)
local GoodSignal = require(ReplicatedStorage.Packages.GoodSignal)
local InputSystemTypes = require(ReplicatedStorage.Shared.InputSystem.InputSystemTypes)

local allUseableItemsControllers: { [Player]: UsableItemsController } = {}

local UsableItemsController = {}
UsableItemsController.__index = UsableItemsController

export type UsableItemsController = typeof(setmetatable(
	{} :: {
		player: Player,
		connections: { GoodSignal.Connection },
	},
	UsableItemsController
))

function UsableItemsController.new(player: Player): UsableItemsController
	local inputs = InputSystem.getInputs(player)
	local connections: { GoodSignal.Connection } = {}

	local self = setmetatable({
		player = player,
		connections = connections,
	}, UsableItemsController)

	for _, input: Input.Input in inputs do
		table.insert(
			connections,
			input.Started:Connect(function(context)
				local useableItem = self:getUseableItem(context)
				if useableItem then
					useableItem:handleInputStart(context)
				end
			end)
		)

		table.insert(
			connections,
			input.Ended:Connect(function(context)
				local useableItem = self:getUseableItem(context)
				if useableItem then
					useableItem:handleInputEnd(context)
				end
			end)
		)

		table.insert(
			connections,
			input.Switched:Connect(function(context)
				local useableItem = self:getUseableItem(context)
				if useableItem then
					useableItem:handleInputSwitch(context)
				end
			end)
		)
	end

	allUseableItemsControllers[player] = self

	return self
end

function UsableItemsController.destroy(self: UsableItemsController): ()
	for _, connection in self.connections do
		connection:Disconnect()
	end
	self.connections = {}
	allUseableItemsControllers[self.player] = nil
end

function UsableItemsController.getUseableItem(
	self: UsableItemsController,
	context: InputSystemTypes.InputContext
): UsableItemsRegistry.UsableItem?
	local inventory = Inventory.getPlayerInventory(self.player)
	local items = inventory:getItemsInHands()

	for slotId = 2, 1, -1 do
		local item = items[slotId]
		if not item then
			continue
		end

		local useableItem = UsableItemsRegistry.get(item:getItemData().instance)
		if useableItem and useableItem:canHandleInput(context) then
			return useableItem
		end
	end

	return nil
end
function UsableItemsController.getPlayerController(player: Player): UsableItemsController
	if not allUseableItemsControllers[player] then
		UsableItemsController.new(player)
	end

	return allUseableItemsControllers[player]
end

return UsableItemsController
