--!strict

local InstanceRegistry = require(script.Parent.Parent.InstanceRegistry)

return function()
	describe("InstanceRegistry", function()
		it("returns nil for an unregistered instance", function()
			local registry = InstanceRegistry.new()
			local instance = Instance.new("Folder")

			expect(registry.get(instance)).to.equal(nil)

			instance:Destroy()
		end)

		it("returns the registered value for its instance", function()
			local registry = InstanceRegistry.new()
			local instance = Instance.new("Folder")

			registry.register(instance, "value")

			expect(registry.get(instance)).to.equal("value")

			instance:Destroy()
		end)

		it("keeps different instances independent", function()
			local registry = InstanceRegistry.new()
			local a = Instance.new("Folder")
			local b = Instance.new("Folder")

			registry.register(a, "a-value")
			registry.register(b, "b-value")

			expect(registry.get(a)).to.equal("a-value")
			expect(registry.get(b)).to.equal("b-value")

			a:Destroy()
			b:Destroy()
		end)

		it("unregister clears the value", function()
			local registry = InstanceRegistry.new()
			local instance = Instance.new("Folder")

			registry.register(instance, "value")
			registry.unregister(instance)

			expect(registry.get(instance)).to.equal(nil)

			instance:Destroy()
		end)

		it("unregistering an instance that was never registered does not error", function()
			local registry = InstanceRegistry.new()
			local instance = Instance.new("Folder")

			registry.unregister(instance)

			expect(registry.get(instance)).to.equal(nil)

			instance:Destroy()
		end)

		it("re-registering overwrites the previous value", function()
			local registry = InstanceRegistry.new()
			local instance = Instance.new("Folder")

			registry.register(instance, "first")
			registry.register(instance, "second")

			expect(registry.get(instance)).to.equal("second")

			instance:Destroy()
		end)

		it("two registries created with .new() do not share state", function()
			local registryA = InstanceRegistry.new()
			local registryB = InstanceRegistry.new()
			local instance = Instance.new("Folder")

			registryA.register(instance, "only-in-a")

			expect(registryA.get(instance)).to.equal("only-in-a")
			expect(registryB.get(instance)).to.equal(nil)

			instance:Destroy()
		end)
	end)
end
