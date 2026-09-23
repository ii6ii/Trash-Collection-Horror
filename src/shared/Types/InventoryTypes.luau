export type SlotKind = "Hands" | "Backpack"

export type ClearReason = "Respawn" | "PlayerLeaving"

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
	instance: Model,
	attachment: Attachment?,
}

export type Item = {
	getItemData: (self: Item) -> ItemData,
	setOwner: (self: Item, owner: Player?) -> (),
	getOwner: (self: Item) -> Player?,
	onEquipped: (self: Item) -> (),
	onUnequipped: (self: Item) -> (),

	-- Вызывается инвентарём перед принудительным изъятием предмета
	-- (например, при очистке инвентаря на респавне). Предмет сам решает,
	-- как отреагировать (упасть на землю, высыпать содержимое и т.д.);
	-- инвентарь после вызова сам довыполнит изъятие, если предмет этого не сделал.
	onInventoryCleared: (self: Item, reason: ClearReason) -> (),
}

return {}
