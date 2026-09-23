--!strict

local CollectionService = game:GetService("CollectionService")

local CollectionServiceUtils = {}

-- Вызывает onAdded для уже тегированных instance'ов и для всех будущих;
-- onRemoved (опционально) - когда тег снят или instance уничтожен.
-- Используется server/client BinController, чтобы не дублировать
-- одинаковый цикл GetTagged/GetInstanceAddedSignal.
function CollectionServiceUtils.watchTag(
	tag: string,
	onAdded: (instance: Instance) -> (),
	onRemoved: ((instance: Instance) -> ())?
): ()
	for _, instance in CollectionService:GetTagged(tag) do
		onAdded(instance)
	end

	CollectionService:GetInstanceAddedSignal(tag):Connect(onAdded)

	if onRemoved then
		CollectionService:GetInstanceRemovedSignal(tag):Connect(onRemoved)
	end
end

return CollectionServiceUtils
