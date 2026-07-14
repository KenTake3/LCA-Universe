--!strict

export type SaveReason = "Manual" | "Autosave" | "PlayerRemoving" | "Shutdown"

export type ReadResult = {
	ok: boolean,
	code: "OK" | "NOT_FOUND" | "LOAD_FAILED" | "INVALID_DATA",
	data: { [any]: any }?,
}

export type WriteResult = {
	ok: boolean,
	code: "OK" | "SAVE_FAILED" | "INVALID_DATA",
}

local MemoryPersistenceAdapter = {}
local snapshots: { [number]: { [any]: any } } = {}

-- RECOVERY_PROVISIONAL: no original serialization-depth bound survived.
local MAX_CLONE_DEPTH = 32

local SAVE_REASONS: { [string]: boolean } = {
	Manual = true,
	Autosave = true,
	PlayerRemoving = true,
	Shutdown = true,
}

local function isFiniteNumber(value: any): boolean
	return type(value) == "number"
		and value == value
		and value ~= math.huge
		and value ~= -math.huge
end

local function isFiniteInteger(value: any): boolean
	return isFiniteNumber(value) and value == math.floor(value)
end

local function cloneValue(value: any, depth: number, active: { [any]: boolean }): (any?, string?)
	if depth > MAX_CLONE_DEPTH then
		return nil, "MAX_DEPTH_EXCEEDED"
	end

	local valueType = type(value)
	if value == nil or valueType == "boolean" or valueType == "string" then
		return value, nil
	elseif valueType == "number" then
		if not isFiniteNumber(value) then
			return nil, "NON_FINITE_NUMBER"
		end
		return value, nil
	elseif valueType ~= "table" then
		return nil, "UNSUPPORTED_VALUE"
	end

	if active[value] then
		return nil, "CYCLIC_TABLE"
	end
	active[value] = true

	local result = {}
	for key, nestedValue in pairs(value) do
		if type(key) ~= "string" and not isFiniteInteger(key) then
			active[value] = nil
			return nil, "UNSUPPORTED_TABLE_KEY"
		end

		local clonedValue, cloneError = cloneValue(nestedValue, depth + 1, active)
		if cloneError ~= nil then
			active[value] = nil
			return nil, cloneError
		end
		result[key] = clonedValue
	end

	active[value] = nil
	return result, nil
end

local function deepClone(value: any): (any?, string?)
	return cloneValue(value, 0, {})
end

local function validUserId(userId: any): boolean
	return isFiniteInteger(userId)
end

function MemoryPersistenceAdapter.read(userId: number): ReadResult
	if not validUserId(userId) then
		return { ok = false, code = "INVALID_DATA", data = nil }
	end

	local snapshot = snapshots[userId]
	if snapshot == nil then
		return { ok = true, code = "NOT_FOUND", data = nil }
	end

	local cloned, cloneError = deepClone(snapshot)
	if cloneError ~= nil or type(cloned) ~= "table" then
		return { ok = false, code = "INVALID_DATA", data = nil }
	end
	return { ok = true, code = "OK", data = cloned }
end

function MemoryPersistenceAdapter.write(userId: number, snapshot: { [any]: any }, reason: SaveReason): WriteResult
	if not validUserId(userId) or type(reason) ~= "string" or not SAVE_REASONS[reason] then
		return { ok = false, code = "INVALID_DATA" }
	end
	if type(snapshot) ~= "table" then
		return { ok = false, code = "INVALID_DATA" }
	end

	local cloned, cloneError = deepClone(snapshot)
	if cloneError ~= nil or type(cloned) ~= "table" then
		return { ok = false, code = "INVALID_DATA" }
	end

	snapshots[userId] = cloned
	return { ok = true, code = "OK" }
end

return table.freeze(MemoryPersistenceAdapter)
