--!strict

-- Контракт двуручного хвата между сервером и клиентами и сборка кадра хвата
-- из кистей персонажа.
--
-- Разделение обязанностей: сервер решает, кто что держит, и создаёт Motor6D -
-- он реплицируется сам. Позу хвата каждая сторона считает у себя по своим
-- кистям (см. TwoHandedGripFitter): Motor6D.Transform не реплицируется, а
-- гнать позу через сервер бессмысленно - она отстанет на круг репликации от
-- анимации, которая эти кисти и двигает.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CharacterHands = require(ReplicatedStorage.Shared.Grip.CharacterHands)
local GripConfig = require(ReplicatedStorage.Shared.Config.GripConfig)
local TwoHandGripSolver = require(ReplicatedStorage.Shared.Grip.TwoHandGripSolver)

local ROTATION_OFFSET = CFrame.Angles(
	math.rad(GripConfig.TwoHandedRotationOffset.X),
	math.rad(GripConfig.TwoHandedRotationOffset.Y),
	math.rad(GripConfig.TwoHandedRotationOffset.Z)
)

-- Смещение - в осях кадра рук, до поворота предмета: иначе подбор поворота
-- в конфиге каждый раз уводил бы и смещение вместе с собой.
local POSITION_OFFSET = CFrame.new(GripConfig.TwoHandedPositionOffset)

local TwoHandedGrip = {}

-- Тег вешает сервер на модель предмета; по нему клиенты находят активные хваты.
TwoHandedGrip.Tag = "TwoHandedGrip"
TwoHandedGrip.MotorName = "TwoHandedGripMotor"

-- Мировой кадр хвата по текущей позе кистей. nil - поза вырождена (см. солвер).
function TwoHandedGrip.gripCFrame(hands: CharacterHands.Hands): CFrame?
	local leftGrip, rightGrip = CharacterHands.gripCFrames(hands)
	local frame = TwoHandGripSolver.solve(leftGrip, rightGrip)

	if not frame then
		return nil
	end

	return frame * POSITION_OFFSET * ROTATION_OFFSET
end

-- Что именно садится в кадр хвата. По умолчанию - центр предмета: Attachment
-- у предмета один и сделан под одноручный хват (обычно у ручки), так что
-- центровка по нему кладёт между кистями ручку, а сам предмет уезжает вбок
-- на половину своей ширины.
function TwoHandedGrip.anchorOffset(model: Model, primaryPart: BasePart, attachment: Attachment): CFrame
	if GripConfig.TwoHandedAnchor == "Attachment" then
		return attachment.CFrame
	end

	-- GetBoundingBox и CFrame детали берутся в один момент, поэтому смещение
	-- не зависит от того, где предмет лежит сейчас.
	local boxCFrame = model:GetBoundingBox()
	local centerOffset = primaryPart.CFrame:Inverse() * boxCFrame

	-- Позиция - центр предмета, ориентация - от Attachment. Ориентацию у
	-- bounding box брать нельзя: она идёт от PrimaryPart, и настроенный поворот
	-- хвата пришлось бы подбирать заново, отдельно от одноручного.
	return CFrame.new(centerOffset.Position) * attachment.CFrame.Rotation
end

-- C1 = anchorOffset, поэтому Part0.CFrame * C0 * Transform - это прямо кадр
-- хвата, а не положение PrimaryPart: и посадка, и живая доводка считают одно
-- и то же, а разница между "центром предмета" и "точкой хвата" живёт в одном
-- месте (anchorOffset).
function TwoHandedGrip.createMotor(
	primaryPart: BasePart,
	anchorOffset: CFrame,
	hands: CharacterHands.Hands,
	gripCFrame: CFrame
): Motor6D
	local motor = Instance.new("Motor6D")
	motor.Name = TwoHandedGrip.MotorName

	-- Part0 - правая кисть, но привязка не "за правую руку": C0 ставит предмет
	-- в середину между кистями, а живая доводка правит расхождение каждый кадр.
	-- Кисть как Part0 нужна лишь потому, что у Motor6D один родительский part,
	-- и от кисти предмет уже наследует и поворот тела, и наклон руки.
	motor.Part0 = hands.right
	motor.Part1 = primaryPart
	motor.C0 = hands.right.CFrame:Inverse() * gripCFrame
	motor.C1 = anchorOffset

	return motor
end

-- Пишем в Transform, а не в C0: C0 реплицируется, и правка его на каждой
-- стороне разъехалась бы с чужой. Только RunService.Stepped - из Heartbeat/
-- RenderStepped запись до отрисовки не доживает.
--
-- C0 в формуле сокращается, поэтому результат не зависит от того, в какой позе
-- был персонаж в момент экипа и успела ли доехать репликация C0.
function TwoHandedGrip.applyLiveFit(motor: Motor6D, gripCFrame: CFrame): ()
	local part0 = motor.Part0

	if not part0 then
		return
	end

	motor.Transform = motor.C0:Inverse() * part0.CFrame:Inverse() * gripCFrame
end

return TwoHandedGrip
