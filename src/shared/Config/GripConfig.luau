--!strict

-- Что садится ровно между кистями:
-- "ModelCenter" - центр bounding box предмета (ориентация всё равно берётся
--   от Attachment, чтобы поворот настраивался там же, где у одноручного хвата);
-- "Attachment" - точка хвата предмета целиком. Attachment сделан под ОДНУ руку
--   и обычно смещён к ручке, поэтому центровка по нему уводит предмет вбок
--   на половину его ширины.
export type Anchor = "ModelCenter" | "Attachment"

export type Config = {
	TwoHandedAnchor: Anchor,

	-- Поворот предмета относительно кадра, построенного по кистям
	-- (TwoHandGripSolver): X - наклон, Y - разворот, Z - крен, в градусах.
	TwoHandedRotationOffset: Vector3,

	-- Доводка положения в осях кадра рук: +X - в сторону правой руки,
	-- +Y - вверх, -Z - вперёд от игрока. Нули = ровно посередине между
	-- кистями; смещать стоит только чтобы предмет не резался кистями.
	TwoHandedPositionOffset: Vector3,

	-- Доводка хвата по фактической позе кистей каждый кадр - и на клиентах,
	-- и на сервере. Выключить - предмет останется в позе, снятой в момент
	-- экипа: дешевле, но расходится с руками, как только анимация их разводит.
	TwoHandedLiveFit: boolean,
}

local GripConfig: Config = {
	TwoHandedAnchor = "ModelCenter",
	TwoHandedRotationOffset = Vector3.new(0, 0, 0),
	TwoHandedPositionOffset = Vector3.zero,
	TwoHandedLiveFit = true,
}

return GripConfig
