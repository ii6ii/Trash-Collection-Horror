--!strict

local InputSystemTypes = require(script.Parent.Parent.Types.InputSystemTypes)

-- Единственный источник правды для имён инпутов: клиент по нему строит
-- Pressed/Released подписки, сервер - валидирует имя от клиента и собирает
-- набор Input на игрока.
local InputConfig: { InputSystemTypes.InputName } = {
	"EInput",
	"GInput",
	"FInput",
	"SprintInput",
}

return InputConfig
