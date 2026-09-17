local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InputSystemTypes = require(ReplicatedStorage.Shared.InputSystem.InputSystemTypes)
local InventoryTypes = require(ReplicatedStorage.Shared.Inventroy.InventoryTypes)

export type TrashBag = {
	instance: BasePart,
	originalSize: Vector3,
	capacity: number,
	trashInside: number,
	tieProgress: number,
	attachment: Attachment,
	owner: Player?,
	currentState: TrashBagState,
	lastState: TrashBagState,

	allStates: {
		empty: TrashBagState,
		opened: TrashBagState,
		withTrash: TrashBagState,
		tying: TrashBagState,
		tied: TrashBagState,
		untying: TrashBagState,
		onGround: TrashBagState,
	},

	switchState: (self: TrashBag, newState: TrashBagState) -> (),
	getItemData: (self: TrashBag) -> InventoryTypes.ItemData,
	setOwner: (self: TrashBag, owner: Player?) -> (),
	getOwner: (self: TrashBag) -> Player?,
	handleInputStart: (self: TrashBag, context: InputSystemTypes.InputContext) -> (),
	handleInputEnd: (self: TrashBag, context: InputSystemTypes.InputContext) -> (),
	handleInputSwitch: (self: TrashBag, context: InputSystemTypes.InputContext) -> (),
	canHandleInput: (self: TrashBag, context: InputSystemTypes.InputContext) -> boolean,
	getWeight: (self: TrashBag) -> number,
	tryCollectTrash: (self: TrashBag, context: InputSystemTypes.InputContext) -> boolean,
	updateSize: (self: TrashBag) -> (),
}

export type TrashBagState = {
	onEnter: (self: TrashBagState) -> (),
	onExit: (self: TrashBagState) -> (),
	onEquipped: (self: TrashBagState) -> (),
	onUnequipped: (self: TrashBagState) -> (),
	handleInputStart: (self: TrashBagState, context: InputSystemTypes.InputContext) -> (),
	handleInputSwitch: (self: TrashBagState, context: InputSystemTypes.InputContext) -> (),
	handleInputEnd: (self: TrashBagState, context: InputSystemTypes.InputContext) -> (),
	canHandleInput: (self: TrashBagState, context: InputSystemTypes.InputContext) -> boolean,
	getItemData: (self: TrashBagState) -> InventoryTypes.ItemData,

	inputActions: { [string]: (self: TrashBag) -> () },
	context: TrashBag,
}

return {}
