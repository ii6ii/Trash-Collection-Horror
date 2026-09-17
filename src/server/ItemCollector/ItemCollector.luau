--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local InputSystem = require(ServerScriptService.Server.InputSystem.InputSystem)
local Inventory = require(ServerScriptService.Server.Inventory.Inventory)
local InventoryItemRegistry = require(ServerScriptService.Server.Inventory.InventoryItemRegistry)

local RAY_DISTANCE = 10

local ItemCollector = {}
ItemCollector.__index = ItemCollector

export type ItemCollector = typeof(setmetatable(
	{} :: {
		owner: Player,
		connection: RBXScriptConnection,
	},
	ItemCollector
))

function ItemCollector.new(player: Player): ItemCollector
	local self = setmetatable({
		owner = player,
		connection = nil :: any,
	}, ItemCollector)

	local input = InputSystem.getInput(player, "FInput")

	self.connection = input.Started:Connect(function(context)
		self:collect(context.cameraCFrame)
	end)

	return self
end

function ItemCollector.collect(self: ItemCollector, cameraCFrame: CFrame): ()
	local character = self.owner.Character
	if not character then
		return
	end

	local head = character:FindFirstChild("Head") :: BasePart?
	if not head then
		return
	end

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = { character }

	local result = workspace:Raycast(cameraCFrame.Position, cameraCFrame.LookVector * RAY_DISTANCE, raycastParams)

	if not result then
		return
	end

	local item = InventoryItemRegistry.get(result.Instance)
	if not item then
		return
	end
	if item:getOwner() ~= nil then
		return
	end

	Inventory.getPlayerInventory(self.owner):addItem(item)
end

function ItemCollector.destroy(self: ItemCollector): ()
	self.connection:Disconnect()
end

return ItemCollector
