--!strict

local CollectionService = game:GetService("CollectionService")

local PartUtils = {}

function PartUtils.placeOnGround(part: BasePart, offset: number, rotation: Vector3?): ()
	part.Anchored = true

	local randomOffset = Vector3.new(math.random(-offset, offset), 0, math.random(-offset, offset))

	local origin = part.Position + randomOffset

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Include
	raycastParams.FilterDescendantsInstances = CollectionService:GetTagged("Ground")

	local result = workspace:Raycast(origin, Vector3.new(0, -1000, 0), raycastParams)
	if not result then
		return
	end
	part.CFrame = CFrame.new(origin.X, result.Position.Y + part.Size.Y / 2, origin.Z)
		* CFrame.Angles(
			math.rad(rotation and rotation.X or 0),
			math.rad(rotation and rotation.Y or 0),
			math.rad(rotation and rotation.Z or 0)
		)
end

return PartUtils
