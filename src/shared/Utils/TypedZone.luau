--!strict

-- Типизированная обёртка над ZonePlus (Packages.ZonePlus): сам пакет не
-- экспортирует ни одного Luau-типа (проверено и в установленной версии 3.2.0,
-- и в актуальном upstream main ветки 1ForeverHD/ZonePlus - typed-альтернативы
-- на wally не существует). wally-package-types тут ничем не поможет: он умеет
-- только переизвлекать уже существующие export type, а тут их нет.
--
-- Не редактировать Packages/ZonePlus.lua напрямую - это авто-генерируемый
-- wally-thunk, `wally install` перезапишет любые ручные правки. Все места
-- в проекте, которым нужны типы, должны require'ить этот модуль вместо
-- ReplicatedStorage.Packages.ZonePlus напрямую.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RealZonePlus = require(ReplicatedStorage.Packages.ZonePlus)

export type ZoneConnection = {
	Disconnect: (self: ZoneConnection) -> (),
}

export type ZoneSignal<T...> = {
	Connect: (self: ZoneSignal<T...>, callback: (T...) -> ()) -> ZoneConnection,
	Once: (self: ZoneSignal<T...>, callback: (T...) -> ()) -> ZoneConnection,
	Wait: (self: ZoneSignal<T...>) -> T...,
}

export type Zone = {
	-- События входа/выхода. "local" - только на клиенте, для LocalPlayer.
	playerEntered: ZoneSignal<Player>,
	playerExited: ZoneSignal<Player>,
	localPlayerEntered: ZoneSignal<>,
	localPlayerExited: ZoneSignal<>,
	partEntered: ZoneSignal<BasePart>,
	partExited: ZoneSignal<BasePart>,
	itemEntered: ZoneSignal<any>,
	itemExited: ZoneSignal<any>,
	updated: ZoneSignal<>,

	findLocalPlayer: (self: Zone) -> boolean,
	findPlayer: (self: Zone, player: Player) -> boolean,
	findPart: (self: Zone, part: BasePart) -> boolean,
	findItem: (self: Zone, item: any) -> boolean,
	findPoint: (self: Zone, positionOrCFrame: Vector3 | CFrame) -> (boolean, number?),

	getPlayers: (self: Zone) -> { Player },
	getItems: (self: Zone) -> { any },
	getParts: (self: Zone) -> { BasePart },
	getRandomPoint: (self: Zone) -> (Vector3, CFrame),
	getCheckerPart: (self: Zone) -> BasePart,

	setAccuracy: (self: Zone, enumIdOrName: string) -> (),
	setDetection: (self: Zone, enumIdOrName: string) -> (),

	trackItem: (self: Zone, instance: Instance) -> (),
	untrackItem: (self: Zone, instance: Instance) -> (),

	bindToGroup: (self: Zone, settingsGroupName: string) -> (),
	unbindFromGroup: (self: Zone) -> (),

	relocate: (self: Zone) -> (),
	destroy: (self: Zone) -> (),
}

export type ZonePlusModule = {
	new: (container: Instance | { Instance }) -> Zone,
	fromRegion: (cframe: CFrame, size: Vector3) -> Zone,
}

return RealZonePlus :: ZonePlusModule
