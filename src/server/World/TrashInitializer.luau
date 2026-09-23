--!strict

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local TRASH_TAG = "Trash"
local TRASH_SIZE_ATTRIBUTE = "TrashSize"

local FLOAT_HEIGHT = 0.3
local FLOAT_SPEED = 3
local ROTATION_SPEED = math.rad(60)

local RED_COLOR = "#FF4444"

type Trash = Model & {
	BillboardGui: BillboardGui & {
		SpaceText: TextLabel,
	},
}

local TrashInitializer = {}

function TrashInitializer.init(): ()
	for _, trash in CollectionService:GetTagged(TRASH_TAG) do
		TrashInitializer.initTrash(trash :: Trash)
	end

	CollectionService:GetInstanceAddedSignal(TRASH_TAG):Connect(function(trash)
		TrashInitializer.initTrash(trash :: Trash)
	end)
end

function TrashInitializer.initTrash(trash: Trash): ()
	local trashSize = trash:GetAttribute(TRASH_SIZE_ATTRIBUTE) :: number

	local billboardGui = trash.BillboardGui
	local spaceText = billboardGui.SpaceText

	spaceText.RichText = true
	spaceText.Text = `Bag space: <font color="{RED_COLOR}">{trashSize}</font>`

	local primaryPart = trash.PrimaryPart :: BasePart
	local startCFrame = primaryPart.CFrame

	local elapsed = 0

	local connection: RBXScriptConnection
	connection = RunService.Heartbeat:Connect(function(deltaTime: number)
		if not trash.Parent then
			connection:Disconnect()
			return
		end

		elapsed += deltaTime

		local y = math.sin(elapsed * FLOAT_SPEED) * FLOAT_HEIGHT
		local rotation = elapsed * ROTATION_SPEED

		trash:PivotTo(startCFrame * CFrame.new(0, y, 0) * CFrame.Angles(0, rotation, 0))
	end)
end

return TrashInitializer
