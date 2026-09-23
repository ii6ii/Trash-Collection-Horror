--!strict

local Easing = {}

-- Smoothstep: 0 в alpha=0, 1 в alpha=1, нулевая производная на краях (мягкий
-- старт/финиш без рывка). Используется для dolly-переходов камеры.
function Easing.smoothstep(alpha: number): number
	return alpha * alpha * (3 - 2 * alpha)
end

return Easing
