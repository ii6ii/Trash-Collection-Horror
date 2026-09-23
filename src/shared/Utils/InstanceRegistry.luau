--!strict

-- Generic Instance -> T lookup. InventoryItemRegistry и UsableItemsRegistry
-- были буквально одинаковым кодом (register/unregister/get над {[Instance]: T}) -
-- вынесено сюда один раз, конкретные реестры остаются тонкими обёртками
-- со своим типом T и не меняют публичный API для вызывающего кода.

export type InstanceRegistry<T> = {
	register: (instance: Instance, item: T) -> (),
	unregister: (instance: Instance) -> (),
	get: (instance: Instance) -> T?,
}

local InstanceRegistry = {}

function InstanceRegistry.new<T>(): InstanceRegistry<T>
	local items: { [Instance]: T } = {}

	return {
		register = function(instance: Instance, item: T): ()
			items[instance] = item
		end,

		unregister = function(instance: Instance): ()
			items[instance] = nil
		end,

		get = function(instance: Instance): T?
			return items[instance]
		end,
	}
end

return InstanceRegistry
