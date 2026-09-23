--!strict

-- Точки хвата кистей персонажа: единственное место, которое знает про имена
-- костей рига и про grip-attachment'ы. Attachment берётся не ради красоты -
-- это фактическая ладонь, и он масштабируется вместе с аватаром, поэтому
-- середина между двумя такими точками подходит любой модели игрока без
-- поправок на рост и пропорции.

local CharacterHands = {}

-- Второе имя - R6: отдельной кисти там нет, берём руку целиком. Предмет сядет
-- чуть выше ладони, но "строго между рук" при этом сохраняется.
local LEFT_HAND_NAMES = { "LeftHand", "Left Arm" }
local RIGHT_HAND_NAMES = { "RightHand", "Right Arm" }

local LEFT_GRIP_ATTACHMENT = "LeftGripAttachment"
local RIGHT_GRIP_ATTACHMENT = "RightGripAttachment"

export type Hands = {
	left: BasePart,
	right: BasePart,

	-- Нет у кастомных ригов и у R6 - тогда точкой хвата служит сама кисть.
	leftGrip: Attachment?,
	rightGrip: Attachment?,
}

local function findPart(character: Model, names: { string }): BasePart?
	for _, name in names do
		local part = character:FindFirstChild(name)

		if part and part:IsA("BasePart") then
			return part
		end
	end

	return nil
end

local function findGripAttachment(hand: BasePart, name: string): Attachment?
	local attachment = hand:FindFirstChild(name)

	return if attachment and attachment:IsA("Attachment") then attachment else nil
end

function CharacterHands.find(character: Model): Hands?
	local left = findPart(character, LEFT_HAND_NAMES)
	local right = findPart(character, RIGHT_HAND_NAMES)

	if not left or not right then
		return nil
	end

	return {
		left = left,
		right = right,
		leftGrip = findGripAttachment(left, LEFT_GRIP_ATTACHMENT),
		rightGrip = findGripAttachment(right, RIGHT_GRIP_ATTACHMENT),
	}
end

-- Персонаж мог развалиться (респавн, расчленение) уже после find: кеш кистей
-- надо перепроверять перед каждым использованием, а не только при создании.
function CharacterHands.isAlive(hands: Hands): boolean
	return hands.left.Parent ~= nil and hands.right.Parent ~= nil
end

function CharacterHands.gripCFrames(hands: Hands): (CFrame, CFrame)
	local leftGrip = hands.leftGrip
	local rightGrip = hands.rightGrip

	local leftCFrame = if leftGrip then leftGrip.WorldCFrame else hands.left.CFrame
	local rightCFrame = if rightGrip then rightGrip.WorldCFrame else hands.right.CFrame

	return leftCFrame, rightCFrame
end

return CharacterHands
