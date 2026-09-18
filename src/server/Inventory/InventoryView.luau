--!strict

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Networker = require(ReplicatedStorage.Packages.Networker).server
local InventoryTypes = require(ReplicatedStorage.Shared.Inventroy.InventoryTypes)

local ITEM_STORAGE = Instance.new("Folder")
ITEM_STORAGE.Name = "ItemStorage"
ITEM_STORAGE.Parent = ServerStorage

local RIGHT_HAND_ANGLE_OFFSET = CFrame.Angles(math.rad(-90), 0, 0)

local InventoryView = {}
InventoryView.__index = InventoryView

export type InventoryView = typeof(setmetatable(
	{} :: {
		owner: Player,
	},
	InventoryView
))

local animatorNetworker = Networker.new("Animator")

local function destroyWeld(item: InventoryTypes.Item): ()
	local instance = item:getItemData().instance
	local weld = instance:FindFirstChildOfClass("WeldConstraint")

	if weld then
		weld:Destroy()
	end
end

function InventoryView.new(player: Player): InventoryView
	return setmetatable({
		owner = player,
	}, InventoryView)
end

function InventoryView.equipItem(self: InventoryView, item: InventoryTypes.Item, slotId: number): boolean
	local character = self.owner.Character
	if not character then
		return false
	end

	local handName = slotId == 1 and "LeftHand" or "RightHand"
	local hand = character:FindFirstChild(handName)

	if not hand or not hand:IsA("BasePart") then
		return false
	end

	local data = item:getItemData()
	local primaty = data.instance.PrimaryPart :: BasePart
	local attachment = data.attachment

	if not attachment then
		return false
	end

	destroyWeld(item)

	for _, descendant in data.instance:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = false
			descendant.CanCollide = false
			descendant.Massless = true
		end
	end

	data.instance.Parent = character

	local targetCFrame = hand.CFrame * RIGHT_HAND_ANGLE_OFFSET
	primaty.CFrame = targetCFrame * attachment.CFrame:Inverse()

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = hand
	weld.Part1 = primaty
	weld.Parent = data.instance

	return true
end

function InventoryView.moveToStorage(item: InventoryTypes.Item): ()
	local instance = item:getItemData().instance

	destroyWeld(item)
	instance.Parent = ITEM_STORAGE
end

function InventoryView.moveToWorkspace(item: InventoryTypes.Item): ()
	local instance = item:getItemData().instance

	destroyWeld(item)
	instance.Parent = workspace
end

function InventoryView.updateAnimations(self: InventoryView, itemsInHands: { [number]: InventoryTypes.Item? }): ()
	animatorNetworker:fire(self.owner, "StopHandAnimations")

	local leftItem = itemsInHands[1]
	local rightItem = itemsInHands[2]

	if leftItem then
		animatorNetworker:fire(self.owner, "HoldLeftHand")

		if leftItem:getItemData().size >= 2 then
			animatorNetworker:fire(self.owner, "HoldRightHand")
		end
	end

	if rightItem then
		animatorNetworker:fire(self.owner, "HoldRightHand")

		if rightItem:getItemData().size >= 2 then
			animatorNetworker:fire(self.owner, "HoldLeftHand")
		end
	end
end
function InventoryView.destroy(self: InventoryView) end

return InventoryView
