--!strict

local CollectionService = game:GetService("CollectionService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local CharacterHands = require(ReplicatedStorage.Shared.Grip.CharacterHands)
local InventoryTypes = require(ReplicatedStorage.Shared.Types.InventoryTypes)
local InventoryConfig = require(ReplicatedStorage.Shared.Config.InventoryConfig)
local TwoHandedGrip = require(ReplicatedStorage.Shared.Grip.TwoHandedGrip)
local CharacterAnimator = require(ServerScriptService.Server.Core.Animator.CharacterAnimator)

local ITEM_STORAGE = Instance.new("Folder")
ITEM_STORAGE.Name = "ItemStorage"
ITEM_STORAGE.Parent = ServerStorage

local function toAngleOffset(rotationDegrees: Vector3): CFrame
	return CFrame.Angles(math.rad(rotationDegrees.X), math.rad(rotationDegrees.Y), math.rad(rotationDegrees.Z))
end

-- Фиксированный локальный офсет "рука -> точка хвата предмета" (см. InventoryConfig).
-- Используется как C0/C1 обычного Weld: Weld continuously поддерживает
-- Part1.CFrame = hand.CFrame * ONE_HANDED_GRIP_C0 * attachment.CFrame:Inverse()
-- из текущего CFrame руки, поэтому итоговая ориентация всегда одна и та же
-- относительно неё - не зависит от того, в какой позе была рука в момент экипа
-- (WeldConstraint так не может: он сам вычисляет и замораживает офсет по текущим
-- CFrame на момент создания, из-за чего хват "плавал" в зависимости от анимации/
-- стороны подхода - именно поэтому C0/C1 здесь заданы явно, а не отданы на откуп
-- автоматике WeldConstraint).
local ONE_HANDED_GRIP_C0 = toAngleOffset(InventoryConfig.OneHandedGripRotation)

-- Предмет, занимающий оба слота рук, цепляется не за конкретную руку, а за
-- середину между кистями: позиция и ориентация хвата считаются из фактических
-- кистей персонажа (см. TwoHandGripSolver), поэтому хват подходит любой модели
-- игрока и следует и за поворотом тела, и за наклоном рук. Держит предмет
-- обычный Motor6D - он реплицируется сам; середину между кистями каждая
-- сторона доводит у себя (TwoHandedGripFitter), потому что Motor6D.Transform
-- не реплицируется.
local function isTwoHanded(data: InventoryTypes.ItemData): boolean
	return data.size >= InventoryConfig.TwoHandedMinSize
end

local InventoryView = {}
InventoryView.__index = InventoryView

export type InventoryView = typeof(setmetatable(
	{} :: {
		owner: Player,
	},
	InventoryView
))

local function destroyGrip(item: InventoryTypes.Item): ()
	local instance = item:getItemData().instance

	-- Снятие тега - это ещё и сигнал клиентам прекратить доводку хвата,
	-- поэтому оно обязано происходить на каждом снятии предмета, а не только
	-- на уничтожении модели.
	CollectionService:RemoveTag(instance, TwoHandedGrip.Tag)

	local motor = instance:FindFirstChild(TwoHandedGrip.MotorName)

	if motor then
		motor:Destroy()
	end

	local weld = instance:FindFirstChildOfClass("Weld")

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

	local twoHanded = isTwoHanded(data)
	local hands: CharacterHands.Hands? = nil
	local gripCFrame: CFrame? = nil

	-- Всё, что может провалиться, проверяется до того, как предмет
	-- распакован и переложен в персонажа: иначе неудачный экип оставит
	-- предмет без коллизий и без хвата посреди мира.
	if twoHanded then
		local foundHands = CharacterHands.find(character)

		if not foundHands then
			return false
		end

		local foundGrip = TwoHandedGrip.gripCFrame(foundHands)

		if not foundGrip then
			return false
		end

		hands = foundHands
		gripCFrame = foundGrip
	end

	destroyGrip(item)

	for _, descendant in data.instance:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = false
			descendant.CanCollide = false
			descendant.Massless = true
		end
	end

	data.instance.Parent = character

	if hands and gripCFrame then
		local anchorOffset = TwoHandedGrip.anchorOffset(data.instance, primaty, attachment)

		primaty.CFrame = gripCFrame * anchorOffset:Inverse()

		local motor = TwoHandedGrip.createMotor(primaty, anchorOffset, hands, gripCFrame)
		motor.Parent = data.instance

		CollectionService:AddTag(data.instance, TwoHandedGrip.Tag)
	else
		primaty.CFrame = hand.CFrame * ONE_HANDED_GRIP_C0 * attachment.CFrame:Inverse()

		local weld = Instance.new("Weld")
		weld.Part0 = hand
		weld.Part1 = primaty
		weld.C0 = ONE_HANDED_GRIP_C0
		weld.C1 = attachment.CFrame
		weld.Parent = data.instance
	end

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

	-- Снимаем грип (в т.ч. тег двуручного хвата) ДО проверки на уничтожение -
	-- иначе при гонке на дисконнекте клиенты останутся с записью о хвате
	-- предмета, которого уже нет (см. isDestroyed ниже).
	destroyGrip(item)

	if isDestroyed(instance) then
		return
	end

	instance.Parent = ITEM_STORAGE
end

function InventoryView.moveToWorkspace(item: InventoryTypes.Item): ()
	local instance = item:getItemData().instance

	destroyGrip(item)

	if isDestroyed(instance) then
		return
	end

	instance.Parent = workspace
end

function InventoryView.updateAnimations(self: InventoryView, itemsInHands: { [number]: InventoryTypes.Item? }): ()
	CharacterAnimator.StopHandAnimations(self.owner)

	local leftItem = itemsInHands[1]
	local rightItem = itemsInHands[2]

	if leftItem then
		CharacterAnimator.HoldLeftHand(self.owner)

		if isTwoHanded(leftItem:getItemData()) then
			CharacterAnimator.HoldRightHand(self.owner)
		end
	end

	if rightItem then
		CharacterAnimator.HoldRightHand(self.owner)

		if isTwoHanded(rightItem:getItemData()) then
			CharacterAnimator.HoldLeftHand(self.owner)
		end
	end
end

function InventoryView.destroy(self: InventoryView) end

return InventoryView
