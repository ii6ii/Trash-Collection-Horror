--!strict

local CollectionService = game:GetService("CollectionService")

local PartUtils = {}

local function hasCantPlaceTag(instance: Instance): boolean
	local current: Instance? = instance

	while current do
		if CollectionService:HasTag(current, "CantPlace") then
			return true
		end

		current = current.Parent
	end

	return false
end

function PartUtils.CanPlace(part: BasePart, offset: number, exclude: { Instance }?): boolean
	local randomOffset = Vector3.new(math.random(-offset, offset), 0, math.random(-offset, offset))

	local origin = part.Position + randomOffset

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude

	local filter: { Instance } = { part }

	if exclude then
		for _, instance in exclude do
			table.insert(filter, instance)
		end
	end

	raycastParams.FilterDescendantsInstances = filter

	local rayOrigin = origin

	while true do
		local result = workspace:Raycast(rayOrigin, Vector3.new(0, -1000, 0), raycastParams)

		if not result then
			return false
		end

		local hitPart = result.Instance

		if hitPart:IsA("BasePart") and hitPart.CanCollide and not hasCantPlaceTag(hitPart) then
			return true
		end

		table.insert(raycastParams.FilterDescendantsInstances, hitPart)
		rayOrigin = result.Position - Vector3.new(0, 0.01, 0)
	end
end

function PartUtils.placeOnGround(part: BasePart, offset: number, rotation: Vector3?, exclude: { Instance }?): boolean
	local originalAnchored = part.Anchored

	local randomOffset = Vector3.new(math.random(-offset, offset), 0, math.random(-offset, offset))

	local origin = part.Position + randomOffset

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude

	local filter: { Instance } = {
		part,
	}

	if exclude then
		for _, instance in exclude do
			table.insert(filter, instance)
		end
	end

	raycastParams.FilterDescendantsInstances = filter

	local rayOrigin = origin

	while true do
		local result = workspace:Raycast(rayOrigin, Vector3.new(0, -1000, 0), raycastParams)

		if not result then
			part.Anchored = originalAnchored
			return false
		end

		local hitPart = result.Instance

		if hitPart:IsA("BasePart") and hitPart.CanCollide and not hasCantPlaceTag(hitPart) then
			local targetRotation = rotation or Vector3.zero

			part.Anchored = true

			part.CFrame = CFrame.new(origin.X, result.Position.Y + part.Size.Y / 2, origin.Z)
				* CFrame.Angles(math.rad(targetRotation.X), math.rad(targetRotation.Y), math.rad(targetRotation.Z))

			return true
		end

		table.insert(raycastParams.FilterDescendantsInstances, hitPart)

		rayOrigin = result.Position - Vector3.new(0, 0.01, 0)
	end
end

return PartUtils
