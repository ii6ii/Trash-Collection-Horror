--!strict

-- Живая доводка двуручного хвата. Запускается и на сервере, и на каждом клиенте.
--
-- Сервер создаёт Motor6D и вешает тег на модель предмета - этого достаточно,
-- чтобы предмет держался за персонажем сам. Но взаимное положение кистей меняет
-- анимация, и офсет, снятый в момент экипа, перестаёт быть серединой между
-- руками, как только руки разъезжаются.
--
-- Поэтому каждая сторона каждый кадр пересчитывает кадр хвата по ФАКТИЧЕСКИМ
-- кистям персонажа, который есть у неё: клиенты - по локально анимированным,
-- сервер - по реплицированным. Motor6D.Transform не реплицируется, поэтому
-- иначе никак: доводка только на клиентах оставила бы сервер с позой, снятой
-- в момент экипа, и всё, что сервер делает по положению предмета (сброс,
-- raycast, зоны), считалось бы по неправильному месту.

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CharacterHands = require(ReplicatedStorage.Shared.Grip.CharacterHands)
local CollectionServiceUtils = require(ReplicatedStorage.Shared.Utils.CollectionServiceUtils)
local GripConfig = require(ReplicatedStorage.Shared.Config.GripConfig)
local TwoHandedGrip = require(ReplicatedStorage.Shared.Grip.TwoHandedGrip)

type Entry = {
	motor: Motor6D?,
	hands: CharacterHands.Hands?,
}

local TwoHandedGripFitter = {}

local entries: { [Model]: Entry } = {}
local steppedConnection: RBXScriptConnection? = nil

-- Мотор и кисти кешируются: искать их в дереве каждый кадр незачем. Но и
-- держать вечно нельзя - предмет перекладывают из рук в руки, персонаж
-- респавнится, поэтому кеш перед каждым использованием проверяется на живость
-- и при расхождении собирается заново.
local function resolve(model: Model, entry: Entry): (Motor6D?, CharacterHands.Hands?)
	entry.motor = nil
	entry.hands = nil

	local motor = model:FindFirstChild(TwoHandedGrip.MotorName)

	if not motor or not motor:IsA("Motor6D") then
		return nil, nil
	end

	-- Модель предмета лежит в персонаже (InventoryView.equipItem), но на клиенте
	-- тег может прийти раньше самой модели и мотора: тогда просто ждём кадра,
	-- на котором репликация их довезёт.
	local character = model.Parent

	if not character or not character:IsA("Model") then
		return nil, nil
	end

	local hands = CharacterHands.find(character)

	if not hands then
		return nil, nil
	end

	entry.motor = motor
	entry.hands = hands

	return motor, hands
end

local function prepare(model: Model, entry: Entry): (Motor6D?, CharacterHands.Hands?)
	local motor = entry.motor
	local hands = entry.hands

	if motor and motor.Parent == model and hands and CharacterHands.isAlive(hands) then
		return motor, hands
	end

	return resolve(model, entry)
end

local function update(): ()
	for model, entry in entries do
		local motor, hands = prepare(model, entry)

		if motor and hands then
			local gripCFrame = TwoHandedGrip.gripCFrame(hands)

			if gripCFrame then
				TwoHandedGrip.applyLiveFit(motor, gripCFrame)
			end
		end
	end
end

local function updateConnection(): ()
	local hasEntries = next(entries) ~= nil
	local connection = steppedConnection

	if hasEntries and not connection then
		steppedConnection = RunService.Stepped:Connect(update)
	elseif not hasEntries and connection then
		connection:Disconnect()
		steppedConnection = nil
	end
end

function TwoHandedGripFitter.init(): ()
	if not GripConfig.TwoHandedLiveFit then
		return
	end

	CollectionServiceUtils.watchTag(TwoHandedGrip.Tag, function(instance: Instance)
		if not instance:IsA("Model") then
			return
		end

		entries[instance] = { motor = nil, hands = nil }
		updateConnection()
	end, function(instance: Instance)
		-- Тег снимается и при Destroy предмета, так что отдельная подписка на
		-- Destroying не нужна: записи не переживают свои модели.
		if not instance:IsA("Model") then
			return
		end

		entries[instance] = nil
		updateConnection()
	end)
end

return TwoHandedGripFitter
