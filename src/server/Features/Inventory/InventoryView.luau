--!strict

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local InventoryTypes = require(ReplicatedStorage.Shared.Types.InventoryTypes)
local CharacterAnimator = require(ServerScriptService.Server.Core.Animator.CharacterAnimator)

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
	local hrp = character:FindFirstChild("HumanoidRootPart")
	local hand = character:FindFirstChild(handName)

	if not hand or not hand:IsA("BasePart") then
		return false
	end

	if not hrp or not hrp:IsA("BasePart") then
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

-- На PlayerRemoving движок может успеть уничтожить Character (и всё, что было
-- к нему приварено) раньше или одновременно с нашей очисткой инвентаря - тогда
-- instance уже :Destroy()-нут, и его Parent залочен. Это ожидаемая гонка при
-- дисконнекте, а не programmer error, поэтому просто пропускаем перемещение.
local function isDestroyed(instance: Instance): boolean
	local ok = pcall(function()
		instance.Parent = instance.Parent
	end)

	return not ok
end

function InventoryView.moveToStorage(item: InventoryTypes.Item): ()
	local instance = item:getItemData().instance

	if isDestroyed(instance) then
		return
	end

	destroyWeld(item)
	instance.Parent = ITEM_STORAGE
end

function InventoryView.moveToWorkspace(item: InventoryTypes.Item): ()
	local instance = item:getItemData().instance

	if isDestroyed(instance) then
		return
	end

	destroyWeld(item)
	instance.Parent = workspace
end

function InventoryView.updateAnimations(self: InventoryView, itemsInHands: { [number]: InventoryTypes.Item? }): ()
	CharacterAnimator.StopHandAnimations(self.owner)

	local leftItem = itemsInHands[1]
	local rightItem = itemsInHands[2]

	if leftItem then
		CharacterAnimator.HoldLeftHand(self.owner)

		if leftItem:getItemData().size >= 2 then
			CharacterAnimator.HoldRightHand(self.owner)
		end
	end

	if rightItem then
		CharacterAnimator.HoldRightHand(self.owner)

		if rightItem:getItemData().size >= 2 then
			CharacterAnimator.HoldLeftHand(self.owner)
		end
	end
end

function InventoryView.destroy(self: InventoryView) end

return InventoryView
