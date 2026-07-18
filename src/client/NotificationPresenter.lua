--!strict

export type Priority = "routine" | "failure" | "majorProgression"

export type Dependencies = {
	read container: GuiObject,
	read tweenService: TweenService,
	read textColor: Color3,
}

type Entry = {
	label: TextLabel,
	priority: Priority,
	key: string,
	fadeIn: Tween?,
	fadeOut: Tween?,
	alive: boolean,
}

type Recent = {
	key: string,
	time: number,
}

local NotificationPresenter = {}
local MAX_VISIBLE = 3
local DEDUP_SECONDS = 1.0
local HOLD_SECONDS = 3.0
local FADE_IN_SECONDS = 0.2
local FADE_OUT_SECONDS = 0.5
local MAX_RECENT = 8

local dependencies: Dependencies? = nil
local entries: { Entry } = {}
local recent: { Recent } = {}

local function reindex()
	for index, entry in entries do
		entry.label.LayoutOrder = index
	end
end

local function removeEntry(entry: Entry)
	if not entry.alive then
		return
	end
	entry.alive = false
	if entry.fadeIn ~= nil then
		entry.fadeIn:Cancel()
	end
	if entry.fadeOut ~= nil then
		entry.fadeOut:Cancel()
	end
	for index, candidate in entries do
		if candidate == entry then
			table.remove(entries, index)
			break
		end
	end
	entry.label:Destroy()
	reindex()
end

local function recentlyShown(key: string): boolean
	local now = os.clock()
	local writeIndex = 1
	local found = false
	for _, item in recent do
		if now - item.time <= DEDUP_SECONDS then
			recent[writeIndex] = item
			writeIndex += 1
			if item.key == key then
				found = true
			end
		end
	end
	for index = #recent, writeIndex, -1 do
		table.remove(recent, index)
	end
	if found then
		return true
	end
	return false
end

local function recordRecent(key: string)
	table.insert(recent, { key = key, time = os.clock() })
	if #recent > MAX_RECENT then
		table.remove(recent, 1)
	end
end

local function oldestIndex(priority: Priority?): number?
	for index, entry in entries do
		if priority == nil or entry.priority == priority then
			return index
		end
	end
	return nil
end

local function makeRoom(priority: Priority): boolean
	if #entries < MAX_VISIBLE then
		return true
	end
	local replaceIndex = oldestIndex("routine")
	if replaceIndex == nil and priority == "majorProgression" then
		replaceIndex = oldestIndex("failure") or oldestIndex("majorProgression")
	elseif replaceIndex == nil and priority == "failure" then
		replaceIndex = oldestIndex("failure")
	end
	if replaceIndex == nil then
		return false
	end
	removeEntry(entries[replaceIndex])
	return true
end

local function show(priority: Priority, text: string, color: Color3): boolean
	local configured = dependencies
	if configured == nil or text == "" or typeof(color) ~= "Color3" then
		return false
	end
	local key = priority .. "\0" .. text
	if (priority == "routine" or priority == "failure") and recentlyShown(key) then
		return false
	end
	if not makeRoom(priority) then
		return false
	end
	if priority == "routine" or priority == "failure" then
		recordRecent(key)
	end

	local label = Instance.new("TextLabel")
	label.Name = "PresentationNotification"
	label.Text = text
	label.TextSize = 14
	label.Size = UDim2.new(1, 0, 0, 35)
	label.BackgroundColor3 = color
	label.BackgroundTransparency = 1
	label.TextColor3 = configured.textColor
	label.TextTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.Active = false
	label.Parent = configured.container
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = label

	local entry: Entry = {
		label = label,
		priority = priority,
		key = key,
		fadeIn = nil,
		fadeOut = nil,
		alive = true,
	}
	table.insert(entries, entry)
	reindex()
	local fadeIn = configured.tweenService:Create(
		label,
		TweenInfo.new(FADE_IN_SECONDS, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ BackgroundTransparency = 0.2, TextTransparency = 0 }
	)
	entry.fadeIn = fadeIn
	fadeIn:Play()

	task.delay(HOLD_SECONDS, function()
		if not entry.alive then
			return
		end
		if entry.fadeIn ~= nil then
			entry.fadeIn:Cancel()
			entry.fadeIn = nil
		end
		local fadeOut = configured.tweenService:Create(
			label,
			TweenInfo.new(FADE_OUT_SECONDS, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ BackgroundTransparency = 1, TextTransparency = 1 }
		)
		entry.fadeOut = fadeOut
		fadeOut:Play()
		task.delay(FADE_OUT_SECONDS, function()
			removeEntry(entry)
		end)
	end)
	return true
end

function NotificationPresenter.init(candidate: Dependencies)
	if not candidate.container:IsA("GuiObject")
		or not candidate.tweenService:IsA("TweenService")
		or typeof(candidate.textColor) ~= "Color3"
	then
		error("NotificationPresenter.init received malformed dependencies", 2)
	end
	if dependencies ~= nil then
		if dependencies.container == candidate.container
			and dependencies.tweenService == candidate.tweenService
			and dependencies.textColor == candidate.textColor
		then
			return
		end
		error("NotificationPresenter is already initialized with different dependencies", 2)
	end
	dependencies = table.freeze({
		container = candidate.container,
		tweenService = candidate.tweenService,
		textColor = candidate.textColor,
	})
end

function NotificationPresenter.showRoutine(text: string, color: Color3): boolean
	return show("routine", text, color)
end

function NotificationPresenter.showFailure(text: string, color: Color3): boolean
	return show("failure", text, color)
end

function NotificationPresenter.showMajorProgression(text: string, color: Color3): boolean
	return show("majorProgression", text, color)
end

function NotificationPresenter.destroy()
	for index = #entries, 1, -1 do
		removeEntry(entries[index])
	end
	table.clear(recent)
	dependencies = nil
end

return table.freeze(NotificationPresenter)
