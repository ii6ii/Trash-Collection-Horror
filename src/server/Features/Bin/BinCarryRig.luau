--!strict

-- Физическая механика переноса Bin игроком: weld к персонажу, временное
-- отключение коллизий/анкера частей на время переноса и восстановление
-- при сбросе, поиск точки приземления на земле. Не знает про инвентарь,
-- движение игрока, анимации или GUI - только про физику самого Bin.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BinConfig = require(ReplicatedStorage.Shared.Config.BinConfig)

export type BinModel = Model & {
	Model: Model,
	BillboardGui: BillboardGui,
}

local PUSH_OFFSET = BinConfig.CarryOffset
local PUSH_ROTATION = BinConfig.CarryRotation

local GROUND_RAY_DISTANCE = 1000
local GROUND_OFFSET = 0.01

local DROP_OFFSET = BinConfig.DropOffset

type PartProperties = {
	Anchored: boolean,
	CanCollide: boolean,
	CanTouch: boolean,
	CanQuery: boolean,
	Massless: boolean,
}

local BinCarryRig = {}
BinCarryRig.__index = BinCarryRig

export type BinCarryRig = typeof(setmetatable(
	{} :: {
		model: BinModel,

		pushWeld: WeldConstraint?,
		carrier: Player?,

		originalPartProperties: { [BasePart]: PartProperties }?,
	},
	BinCarryRig
))

function BinCarryRig.new(model: BinModel): BinCarryRig
	return setmetatable({
		model = model,
		pushWeld = nil,
		carrier = nil,
		originalPartProperties = nil,
	}, BinCarryRig)
end

function BinCarryRig.isCarried(self: BinCarryRig): boolean
	return self.pushWeld ~= nil
end

function BinCarryRig.getCarrier(self: BinCarryRig): Player?
	return self.carrier
end

function BinCarryRig.attachToPlayer(self: BinCarryRig, player: Player): boolean
	if self.pushWeld then
		return false
	end

	local character = player.Character

	if not character then
		return false
	end

	local root = character:FindFirstChild("HumanoidRootPart")

	if not root or not root:IsA("BasePart") then
		return false
	end

	local binModel = self.model.Model
	local primaryPart = binModel.PrimaryPart

	if not primaryPart then
		warn(`{binModel:GetFullName()} has no PrimaryPart`)
		return false
	end

	local originalPartProperties: { [BasePart]: PartProperties } = {}

	for _, part in binModel:GetDescendants() do
		if part:IsA("BasePart") then
			originalPartProperties[part] = {
				Anchored = part.Anchored,
				CanCollide = part.CanCollide,
				CanTouch = part.CanTouch,
				CanQuery = part.CanQuery,
				Massless = part.Massless,
			}

			part.Anchored = false
			part.CanCollide = false
			part.CanTouch = false
			part.CanQuery = false
			part.Massless = true
		end
	end

	self.originalPartProperties = originalPartProperties

	binModel:PivotTo(
		root.CFrame
			* CFrame.new(PUSH_OFFSET)
			* CFrame.Angles(math.rad(PUSH_ROTATION.X), math.rad(PUSH_ROTATION.Y), math.rad(PUSH_ROTATION.Z))
	)

	local weld = Instance.new("WeldConstraint")
	weld.Name = "BinPlayerWeld"
	weld.Part0 = root
	weld.Part1 = primaryPart
	weld.Parent = primaryPart

	self.pushWeld = weld
	self.carrier = player

	self.model.BillboardGui.Enabled = false

	return true
end

function BinCarryRig.detachFromPlayer(self: BinCarryRig): ()
	if self.pushWeld then
		self.pushWeld:Destroy()
		self.pushWeld = nil
	end

	self.carrier = nil
end

-- itemInstances: инстансы предметов, лежащих внутри Bin - исключаются
-- из raycast поиска земли, чтобы не приземлиться на собственное содержимое.
function BinCarryRig.drop(self: BinCarryRig, itemInstances: { Instance }): ()
	local binModel = self.model.Model
	local character = self.carrier and self.carrier.Character

	self:detachFromPlayer()

	self.model.BillboardGui.Enabled = true

	for _, part in binModel:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = true
		end
	end

	-- Выравниваем Bin, сохраняя только Y-поворот.
	local pivot = binModel:GetPivot()
	local _, y = pivot:ToOrientation()

	binModel:PivotTo(CFrame.new(pivot.Position) * CFrame.Angles(0, y, 0))

	local worldDropOffset = Vector3.zero
	local root = character and character:FindFirstChild("HumanoidRootPart")

	if root and root:IsA("BasePart") then
		worldDropOffset = root.CFrame:VectorToWorldSpace(DROP_OFFSET)
	end

	binModel:PivotTo(binModel:GetPivot() + worldDropOffset)

	local boxCFrame, boxSize = binModel:GetBoundingBox()

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude

	local filter: { Instance } = { self.model }
	for _, instance in itemInstances do
		table.insert(filter, instance)
	end
	if character then
		table.insert(filter, character)
	end

	raycastParams.FilterDescendantsInstances = filter

	local rayOrigin = boxCFrame.Position + Vector3.new(0, boxSize.Y / 2 + 1, 0)

	local result = workspace:Raycast(rayOrigin, Vector3.new(0, -GROUND_RAY_DISTANCE, 0), raycastParams)

	if result then
		local bottomY = boxCFrame.Position.Y - boxSize.Y / 2
		local offsetY = result.Position.Y - bottomY + GROUND_OFFSET

		binModel:PivotTo(binModel:GetPivot() + Vector3.new(0, offsetY, 0))
	end

	if self.originalPartProperties then
		for part, properties in self.originalPartProperties do
			if part.Parent then
				part.Anchored = properties.Anchored
				part.CanCollide = properties.CanCollide
				part.CanTouch = properties.CanTouch
				part.CanQuery = properties.CanQuery
				part.Massless = properties.Massless
			end
		end
	end

	self.originalPartProperties = nil
end

function BinCarryRig.destroy(self: BinCarryRig): ()
	self:detachFromPlayer()
end

return BinCarryRig
