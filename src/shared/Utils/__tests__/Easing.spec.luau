--!strict

local Easing = require(script.Parent.Parent.Easing)

return function()
	describe("Easing.smoothstep", function()
		it("returns 0 at alpha 0", function()
			expect(Easing.smoothstep(0)).to.equal(0)
		end)

		it("returns 1 at alpha 1", function()
			expect(Easing.smoothstep(1)).to.equal(1)
		end)

		it("returns 0.5 at the midpoint", function()
			expect(Easing.smoothstep(0.5)).to.equal(0.5)
		end)

		it("is monotonically increasing across the range", function()
			local previous = Easing.smoothstep(0)

			for i = 1, 20 do
				local current = Easing.smoothstep(i / 20)
				expect(current >= previous).to.equal(true)
				previous = current
			end
		end)

		it("starts slower than linear near 0 (ease-in)", function()
			expect(Easing.smoothstep(0.1) < 0.1).to.equal(true)
		end)

		it("ends slower than linear near 1 (ease-out)", function()
			expect(Easing.smoothstep(0.9) > 0.9).to.equal(true)
		end)
	end)
end
