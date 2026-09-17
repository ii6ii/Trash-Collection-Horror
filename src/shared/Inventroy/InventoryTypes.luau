export type SlotData = {
	type: string?,
	isLock: boolean,
}

export type ItemData = {
	type: string,
	weight: number,
	size: number,
	canTakeInHands: boolean,
	canPutInBackpack: boolean,
	instance: BasePart,
	attachment: Attachment?,
}

export type Item = {
	getItemData: (self: Item) -> ItemData,
	setOwner: (self: Item, owner: Player?) -> (),
	getOwner: (self: Item) -> Player?,
	onEquipped: (self: Item) -> (),
	onUnequipped: (self: Item) -> (),
}

return {}
