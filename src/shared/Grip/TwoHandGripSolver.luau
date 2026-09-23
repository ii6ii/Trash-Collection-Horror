--!strict

-- Кадр двуручного хвата по двум точкам хвата кистей. Чистая математика:
-- ни одного Roblox-сервиса и ни одного Instance, только CFrame/Vector3 -
-- поэтому проверяется TestEz без персонажа, Workspace и запуска игры.
--
-- Позиция кадра - ровно середина между кистями, поэтому размер аватара и
-- расстояние между руками учитываются сами собой. Ось X кадра - линия
-- левая кисть -> правая кисть, ориентация - усреднённая ротация кистей:
-- отсюда берётся и поворот за персонажем по Y, и наклон рук вверх/вниз.

local EPSILON = 1e-4

local TwoHandGripSolver = {}

-- nil означает вырожденный вход (кисти в одной точке; ориентация кистей
-- выродилась в ось рук) - осмысленного кадра не существует, и вызывающий
-- должен оставить предмет на месте, а не ставить его в мусорный CFrame.
function TwoHandGripSolver.solve(leftGrip: CFrame, rightGrip: CFrame): CFrame?
	local axis = rightGrip.Position - leftGrip.Position
	local span = axis.Magnitude

	if span < EPSILON then
		return nil
	end

	local xAxis = axis / span

	-- Среднее двух кистей, а не одна из них: взять ориентацию у одной руки -
	-- значит перекосить предмет, как только вторая уйдёт своей анимацией.
	local blended = leftGrip.Rotation:Lerp(rightGrip.Rotation, 0.5)

	-- Грам-Шмидт: из ориентации кистей убираем составляющую вдоль измеренной
	-- оси рук. Ось рук задаёт X кадра точно, остальное достраивается под неё,
	-- иначе кадр перестаёт быть ортонормированным и предмет "плывёт".
	local zAxis = blended.ZVector - xAxis * blended.ZVector:Dot(xAxis)

	if zAxis.Magnitude < EPSILON then
		zAxis = blended.YVector - xAxis * blended.YVector:Dot(xAxis)

		if zAxis.Magnitude < EPSILON then
			return nil
		end
	end

	zAxis = zAxis.Unit

	local midPosition = leftGrip.Position + axis * 0.5

	return CFrame.fromMatrix(midPosition, xAxis, zAxis:Cross(xAxis), zAxis)
end

return TwoHandGripSolver
