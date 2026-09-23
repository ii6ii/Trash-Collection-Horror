--!strict

local TwoHandGripSolver = require(script.Parent.Parent.TwoHandGripSolver)

local EPSILON = 1e-4

local function isClose(actual: Vector3, expected: Vector3): boolean
	return (actual - expected).Magnitude < EPSILON
end

local function isOrthonormal(cframe: CFrame): boolean
	local x, y, z = cframe.XVector, cframe.YVector, cframe.ZVector

	local unit = math.abs(x.Magnitude - 1) < EPSILON
		and math.abs(y.Magnitude - 1) < EPSILON
		and math.abs(z.Magnitude - 1) < EPSILON

	local perpendicular = math.abs(x:Dot(y)) < EPSILON
		and math.abs(y:Dot(z)) < EPSILON
		and math.abs(x:Dot(z)) < EPSILON

	-- Правая тройка: левая дала бы зеркальный хват, и предмет смотрел бы назад.
	local rightHanded = isClose(x:Cross(y), z)

	return unit and perpendicular and rightHanded
end

return function()
	describe("TwoHandGripSolver.solve", function()
		it("puts the grip exactly between the hands", function()
			local frame = TwoHandGripSolver.solve(CFrame.new(-1, 5, 0), CFrame.new(1, 5, 0))

			expect(frame).to.be.ok()
			expect(isClose((frame :: CFrame).Position, Vector3.new(0, 5, 0))).to.equal(true)
		end)

		it("keeps the midpoint when hands are spread unevenly", function()
			local frame = TwoHandGripSolver.solve(CFrame.new(-0.2, 5, 0), CFrame.new(2, 5, 0))

			expect(isClose((frame :: CFrame).Position, Vector3.new(0.9, 5, 0))).to.equal(true)
		end)

		it("aligns its X axis with the line between the hands", function()
			local frame = TwoHandGripSolver.solve(CFrame.new(-1, 5, 0), CFrame.new(1, 5, 0))

			expect(isClose((frame :: CFrame).XVector, Vector3.new(1, 0, 0))).to.equal(true)
		end)

		it("follows the yaw of the hands", function()
			local yaw = CFrame.Angles(0, math.rad(90), 0)
			local left = yaw * CFrame.new(-1, 0, 0)
			local right = yaw * CFrame.new(1, 0, 0)

			local frame = TwoHandGripSolver.solve(left, right) :: CFrame

			expect(isClose(frame.XVector, Vector3.new(0, 0, -1))).to.equal(true)
			expect(isClose(frame.ZVector, Vector3.new(1, 0, 0))).to.equal(true)
		end)

		it("follows the pitch of the hands", function()
			local pitch = CFrame.Angles(math.rad(30), 0, 0)
			local left = CFrame.new(-1, 5, 0) * pitch
			local right = CFrame.new(1, 5, 0) * pitch

			local frame = TwoHandGripSolver.solve(left, right) :: CFrame

			-- Наклон приходит из ориентации кистей, а не из положения тела:
			-- в этом вся разница с хватом, привязанным к HumanoidRootPart.
			expect(isClose(frame.ZVector, pitch.ZVector)).to.equal(true)
			expect(isClose(frame.XVector, Vector3.new(1, 0, 0))).to.equal(true)
		end)

		it("averages the orientation of the two hands", function()
			local left = CFrame.new(-1, 5, 0) * CFrame.Angles(math.rad(40), 0, 0)
			local right = CFrame.new(1, 5, 0) * CFrame.Angles(math.rad(-40), 0, 0)

			local frame = TwoHandGripSolver.solve(left, right) :: CFrame

			expect(isClose(frame.ZVector, Vector3.new(0, 0, 1))).to.equal(true)
		end)

		it("handles hands stacked vertically without collapsing", function()
			local frame = TwoHandGripSolver.solve(CFrame.new(0, 4, 0), CFrame.new(0, 6, 0))

			expect(frame).to.be.ok()
			expect(isClose((frame :: CFrame).XVector, Vector3.new(0, 1, 0))).to.equal(true)
			expect(isOrthonormal(frame :: CFrame)).to.equal(true)
		end)

		it("stays orthonormal when the hands face along their own axis", function()
			local facing = CFrame.Angles(0, math.rad(-90), 0)
			local frame = TwoHandGripSolver.solve(CFrame.new(-1, 5, 0) * facing, CFrame.new(1, 5, 0) * facing)

			expect(frame).to.be.ok()
			expect(isOrthonormal(frame :: CFrame)).to.equal(true)
			expect(isClose((frame :: CFrame).XVector, Vector3.new(1, 0, 0))).to.equal(true)
		end)

		it("mirrors the frame when the hands are passed in the wrong order", function()
			local left = CFrame.new(-1, 5, 0)
			local right = CFrame.new(1, 5, 0)

			local straight = TwoHandGripSolver.solve(left, right) :: CFrame
			local swapped = TwoHandGripSolver.solve(right, left) :: CFrame

			expect(isClose(swapped.XVector, -straight.XVector)).to.equal(true)
			expect(isClose(swapped.Position, straight.Position)).to.equal(true)
		end)

		it("returns nil when both hands are in the same point", function()
			expect(TwoHandGripSolver.solve(CFrame.new(1, 5, 0), CFrame.new(1, 5, 0))).to.equal(nil)
		end)

		it("returns nil when the hands are closer than the solver tolerance", function()
			expect(TwoHandGripSolver.solve(CFrame.new(0, 5, 0), CFrame.new(0, 5, 1e-6))).to.equal(nil)
		end)

		it("produces an orthonormal frame for an arbitrary pose", function()
			local pose = CFrame.Angles(math.rad(17), math.rad(-53), math.rad(8))
			local left = CFrame.new(-0.7, 4.2, 1.3) * pose
			local right = CFrame.new(0.9, 4.9, 0.4) * pose

			expect(isOrthonormal(TwoHandGripSolver.solve(left, right) :: CFrame)).to.equal(true)
		end)
	end)
end
