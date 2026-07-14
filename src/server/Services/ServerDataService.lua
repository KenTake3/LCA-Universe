--!strict

export type ResultCode =
	"OK"
	| "INVALID_PLAYER"
	| "NOT_FOUND"
	| "NOT_INITIALIZED"
	| "ALREADY_ACTIVE"
	| "NOT_LOADED"
	| "LOAD_FAILED"
	| "SAVE_FAILED"
	| "INVALID_DATA"
	| "SAVE_IN_PROGRESS"
	| "FINALIZING"
	| "RELEASED"

export type SaveReason = "Manual" | "Autosave" | "PlayerRemoving" | "Shutdown"
export type FinalizeReason = "PlayerRemoving" | "Shutdown"
export type SessionState = "Loading" | "Loaded" | "LoadFailed" | "Saving" | "Released"

export type Session = {
	userId: number,
	player: Player,
	data: { [any]: any },
	state: SessionState,
	revision: number,
	savedRevision: number,
	dirty: boolean,
	saveInFlight: boolean,
	finalizeRequested: boolean,
	lastResult: ResultCode?,
}

export type SessionRepository = {
	createSession: (player: Player) -> Session?,
	getSession: (player: Player) -> Session?,
	removeSession: (player: Player) -> boolean,
	getDefaultData: () -> { [any]: any },
	migrateData: (data: { [any]: any }) -> ({ [any]: any }?, boolean, string?),
	buildSyncPacket: (player: Player) -> { [any]: any }?,
	buildQuestSyncPacket: (player: Player) -> { [any]: any }?,
}

export type ReadResult = {
	ok: boolean,
	code: "OK" | "NOT_FOUND" | "LOAD_FAILED" | "INVALID_DATA",
	data: { [any]: any }?,
}

export type WriteResult = {
	ok: boolean,
	code: "OK" | "SAVE_FAILED" | "INVALID_DATA",
}

export type PersistenceAdapter = {
	read: (userId: number) -> ReadResult,
	write: (userId: number, snapshot: { [any]: any }, reason: SaveReason) -> WriteResult,
}

export type Dependencies = {
	sessions: SessionRepository,
	persistence: PersistenceAdapter,
	sendDataSync: (player: Player, packet: any) -> (),
	sendQuestSync: (player: Player, packet: any) -> (),
}

local ServerDataService = {}

-- RECOVERY_PROVISIONAL: no original serialization depth limit survived.
-- This internal safety bound is intentionally not gameplay balance.
local MAX_CLONE_DEPTH = 32
local MAX_SAFE_INTEGER = 9_007_199_254_740_991

local dependencies: Dependencies? = nil

local SESSION_STATES: { [string]: boolean } = {
	Loading = true,
	Loaded = true,
	LoadFailed = true,
	Saving = true,
	Released = true,
}

local SAVE_REASONS: { [string]: boolean } = {
	Manual = true,
	Autosave = true,
	PlayerRemoving = true,
	Shutdown = true,
}

local FINALIZE_REASONS: { [string]: boolean } = {
	PlayerRemoving = true,
	Shutdown = true,
}

local function isFiniteInteger(value: any): boolean
	return type(value) == "number"
		and value == value
		and value ~= math.huge
		and value ~= -math.huge
		and value == math.floor(value)
end

local function isPlayer(value: any): boolean
	if typeof(value) ~= "Instance" or not value:IsA("Player") then
		return false
	end
	return isFiniteInteger((value :: Player).UserId)
end

local function cloneValue(value: any, depth: number, active: { [any]: boolean }): (any?, string?)
	if depth > MAX_CLONE_DEPTH then
		return nil, "Maximum table depth exceeded"
	end

	local valueType = type(value)
	if value == nil or valueType == "boolean" or valueType == "string" then
		return value, nil
	end
	if valueType == "number" then
		if value ~= value or value == math.huge or value == -math.huge then
			return nil, "Non-finite number"
		end
		return value, nil
	end
	if valueType ~= "table" then
		return nil, "Unsupported value type"
	end

	if active[value] then
		return nil, "Cyclic table"
	end
	active[value] = true

	local result = {}
	for key, nestedValue in pairs(value) do
		local keyType = type(key)
		if keyType ~= "string" and not isFiniteInteger(key) then
			active[value] = nil
			return nil, "Unsupported table key"
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

local function validRevision(value: any): boolean
	return isFiniteInteger(value) and value >= 0 and value <= MAX_SAFE_INTEGER
end

local function updateDirty(session: Session)
	session.dirty = session.revision > session.savedRevision
end

local function validateSession(session: any, player: Player, requireLoading: boolean): boolean
	if type(session) ~= "table"
		or session.player ~= player
		or session.userId ~= player.UserId
		or type(session.data) ~= "table"
		or type(session.state) ~= "string"
		or not SESSION_STATES[session.state]
		or not validRevision(session.revision)
		or not validRevision(session.savedRevision)
		or session.savedRevision > session.revision
		or type(session.dirty) ~= "boolean"
		or session.dirty ~= (session.revision > session.savedRevision)
		or type(session.saveInFlight) ~= "boolean"
		or type(session.finalizeRequested) ~= "boolean"
	then
		return false
	end

	if requireLoading then
		return session.state == "Loading"
		and session.revision == 0
		and session.savedRevision == 0
		and not session.dirty
		and not session.saveInFlight
		and not session.finalizeRequested
	end

	return true
end

local function getDependencies(): Dependencies?
	return dependencies
end

local function protectedSession(player: Player): Session?
	local configured = getDependencies()
	if configured == nil then
		return nil
	end

	local ok, session = pcall(configured.sessions.getSession, player)
	if not ok or session == nil or not validateSession(session, player, false) then
		return nil
	end
	return session
end

local function setLoadAttributes(player: Player, loaded: boolean, failed: boolean): boolean
	local ok = pcall(function()
		player:SetAttribute("DataLoaded", loaded)
		player:SetAttribute("DataLoadFailed", failed)
	end)
	return ok
end

local function failLoad(session: Session, player: Player, code: ResultCode): (boolean, ResultCode)
	session.state = "LoadFailed"
	session.saveInFlight = false
	session.finalizeRequested = false
	session.lastResult = code
	setLoadAttributes(player, false, true)
	return false, code
end

local function normalizeSaveReason(reason: any): SaveReason
	if type(reason) == "string" and SAVE_REASONS[reason] then
		return reason :: SaveReason
	end
	return "Manual"
end

local function normalizeFinalizeReason(reason: any): FinalizeReason
	if type(reason) == "string" and FINALIZE_REASONS[reason] then
		return reason :: FinalizeReason
	end
	return "PlayerRemoving"
end

local function validateDependencies(candidate: any): Dependencies
	if type(candidate) ~= "table" then
		error("ServerDataService.init requires a dependency table", 3)
	end

	local expectedKeys = {
		sessions = true,
		persistence = true,
		sendDataSync = true,
		sendQuestSync = true,
	}
	for key in pairs(candidate) do
		if not expectedKeys[key] then
			error("ServerDataService.init received an unexpected dependency", 3)
		end
	end

	local sessions = candidate.sessions
	local persistence = candidate.persistence
	if type(sessions) ~= "table"
		or type(sessions.createSession) ~= "function"
		or type(sessions.getSession) ~= "function"
		or type(sessions.removeSession) ~= "function"
		or type(sessions.getDefaultData) ~= "function"
		or type(sessions.migrateData) ~= "function"
		or type(sessions.buildSyncPacket) ~= "function"
		or type(sessions.buildQuestSyncPacket) ~= "function"
		or type(persistence) ~= "table"
		or type(persistence.read) ~= "function"
		or type(persistence.write) ~= "function"
		or type(candidate.sendDataSync) ~= "function"
		or type(candidate.sendQuestSync) ~= "function"
	then
		error("ServerDataService.init received malformed dependencies", 3)
	end

	return table.freeze({
		sessions = sessions,
		persistence = persistence,
		sendDataSync = candidate.sendDataSync,
		sendQuestSync = candidate.sendQuestSync,
	}) :: Dependencies
end

function ServerDataService.init(candidate: Dependencies)
	local validated = validateDependencies(candidate)
	if dependencies ~= nil then
		if dependencies.sessions == validated.sessions
			and dependencies.persistence == validated.persistence
			and dependencies.sendDataSync == validated.sendDataSync
			and dependencies.sendQuestSync == validated.sendQuestSync
		then
			return
		end
		error("ServerDataService is already initialized with different dependencies", 2)
	end
	dependencies = validated
end

function ServerDataService.syncToClient(player: Player): boolean
	local configured = getDependencies()
	if configured == nil or not isPlayer(player) then
		return false
	end

	local session = protectedSession(player)
	if session == nil or (session.state ~= "Loaded" and session.state ~= "Saving") then
		return false
	end

	local packetOk, packet = pcall(configured.sessions.buildSyncPacket, player)
	if not packetOk or type(packet) ~= "table" then
		return false
	end
	local clonedPacket, cloneError = deepClone(packet)
	if cloneError ~= nil or type(clonedPacket) ~= "table" then
		return false
	end

	local sendOk = pcall(configured.sendDataSync, player, clonedPacket)
	return sendOk
end

function ServerDataService.syncQuestToClient(player: Player): boolean
	local configured = getDependencies()
	if configured == nil or not isPlayer(player) then
		return false
	end

	local session = protectedSession(player)
	if session == nil or (session.state ~= "Loaded" and session.state ~= "Saving") then
		return false
	end

	local packetOk, packet = pcall(configured.sessions.buildQuestSyncPacket, player)
	if not packetOk or type(packet) ~= "table" then
		return false
	end
	local clonedPacket, cloneError = deepClone(packet)
	if cloneError ~= nil or type(clonedPacket) ~= "table" then
		return false
	end

	local sendOk = pcall(configured.sendQuestSync, player, clonedPacket)
	return sendOk
end

function ServerDataService.loadPlayer(player: Player): (boolean, ResultCode)
	local configured = getDependencies()
	if configured == nil then
		return false, "NOT_INITIALIZED"
	end
	if not isPlayer(player) then
		return false, "INVALID_PLAYER"
	end

	local existingOk, existing = pcall(configured.sessions.getSession, player)
	if not existingOk then
		return false, "INVALID_DATA"
	end
	if existing ~= nil then
		if type(existing) ~= "table" or existing.state ~= "Released" then
			return false, "ALREADY_ACTIVE"
		end
		local removedOk, removed = pcall(configured.sessions.removeSession, player)
		if not removedOk or not removed then
			return false, "INVALID_DATA"
		end
	end

	local createOk, session = pcall(configured.sessions.createSession, player)
	if not createOk then
		return false, "INVALID_DATA"
	end
	if session == nil then
		return false, "ALREADY_ACTIVE"
	end
	if not validateSession(session, player, true) then
		return false, "INVALID_DATA"
	end
	local createdSession = session :: Session

	if not setLoadAttributes(player, false, false) then
		return failLoad(createdSession, player, "INVALID_PLAYER")
	end

	local readOk, readResult = pcall(configured.persistence.read, player.UserId)
	if not readOk then
		return failLoad(createdSession, player, "LOAD_FAILED")
	end
	if type(readResult) ~= "table" or type(readResult.ok) ~= "boolean" or type(readResult.code) ~= "string" then
		return failLoad(createdSession, player, "INVALID_DATA")
	end

	local isNewData = false
	local candidate: any = nil
	if readResult.ok == true and readResult.code == "NOT_FOUND" and readResult.data == nil then
		local defaultsOk, defaults = pcall(configured.sessions.getDefaultData)
		if not defaultsOk or type(defaults) ~= "table" then
			return failLoad(createdSession, player, "INVALID_DATA")
		end
		candidate = defaults
		isNewData = true
	elseif readResult.ok == true and readResult.code == "OK" and type(readResult.data) == "table" then
		candidate = readResult.data
	elseif readResult.ok == false and readResult.code == "LOAD_FAILED" then
		return failLoad(createdSession, player, "LOAD_FAILED")
	elseif readResult.ok == false and readResult.code == "INVALID_DATA" then
		return failLoad(createdSession, player, "INVALID_DATA")
	else
		return failLoad(createdSession, player, "INVALID_DATA")
	end

	local clonedCandidate, candidateError = deepClone(candidate)
	if candidateError ~= nil or type(clonedCandidate) ~= "table" then
		return failLoad(createdSession, player, "INVALID_DATA")
	end

	local migrationOk, migratedData, migrationChanged, migrationError = pcall(
		configured.sessions.migrateData,
		clonedCandidate
	)
	if not migrationOk
		or type(migratedData) ~= "table"
		or type(migrationChanged) ~= "boolean"
		or migrationError ~= nil
	then
		return failLoad(createdSession, player, "INVALID_DATA")
	end

	local ownedData, ownedError = deepClone(migratedData)
	if ownedError ~= nil or type(ownedData) ~= "table" then
		return failLoad(createdSession, player, "INVALID_DATA")
	end

	createdSession.data = ownedData
	if isNewData or migrationChanged then
		createdSession.revision = 1
		createdSession.savedRevision = 0
	else
		createdSession.revision = 0
		createdSession.savedRevision = 0
	end
	updateDirty(createdSession)
	createdSession.saveInFlight = false
	createdSession.finalizeRequested = false
	createdSession.state = "Loaded"
	createdSession.lastResult = "OK"
	setLoadAttributes(player, true, false)

	ServerDataService.syncToClient(player)
	return true, "OK"
end

function ServerDataService.markDirty(player: Player): (boolean, ResultCode)
	if getDependencies() == nil then
		return false, "NOT_INITIALIZED"
	end
	if not isPlayer(player) then
		return false, "INVALID_PLAYER"
	end

	local session = protectedSession(player)
	if session == nil then
		return false, "NOT_FOUND"
	end
	if session.state == "Loading" then
		return false, "NOT_LOADED"
	elseif session.state == "LoadFailed" then
		return false, "LOAD_FAILED"
	elseif session.state == "Released" then
		return false, "RELEASED"
	elseif session.finalizeRequested then
		return false, "FINALIZING"
	end
	if session.state ~= "Loaded" and session.state ~= "Saving" then
		return false, "NOT_LOADED"
	end
	if session.revision >= MAX_SAFE_INTEGER then
		return false, "INVALID_DATA"
	end

	session.revision += 1
	updateDirty(session)
	session.lastResult = "OK"
	return true, "OK"
end

local function saveSession(session: Session, player: Player, reason: SaveReason): (boolean, ResultCode)
	local configured = getDependencies()
	if configured == nil then
		return false, "NOT_INITIALIZED"
	end
	if session.saveInFlight or session.state == "Saving" then
		return false, "SAVE_IN_PROGRESS"
	end
	if not session.dirty then
		session.lastResult = "OK"
		return true, "OK"
	end

	local capturedRevision = session.revision
	local snapshot, snapshotError = deepClone(session.data)
	if snapshotError ~= nil or type(snapshot) ~= "table" then
		session.lastResult = "INVALID_DATA"
		return false, "INVALID_DATA"
	end

	session.saveInFlight = true
	session.state = "Saving"
	local writeOk, writeResult = pcall(
		configured.persistence.write,
		player.UserId,
		snapshot,
		reason
	)

	local resultCode: ResultCode
	local successful = false
	if not writeOk then
		resultCode = "SAVE_FAILED"
	elseif type(writeResult) ~= "table"
		or type(writeResult.ok) ~= "boolean"
		or type(writeResult.code) ~= "string"
	then
		resultCode = "INVALID_DATA"
	elseif writeResult.ok == true and writeResult.code == "OK" then
		successful = true
		resultCode = "OK"
	elseif writeResult.ok == false and writeResult.code == "SAVE_FAILED" then
		resultCode = "SAVE_FAILED"
	elseif writeResult.ok == false and writeResult.code == "INVALID_DATA" then
		resultCode = "INVALID_DATA"
	else
		resultCode = "INVALID_DATA"
	end

	if successful then
		session.savedRevision = math.max(session.savedRevision, capturedRevision)
	end
	updateDirty(session)
	session.saveInFlight = false
	session.state = "Loaded"
	session.lastResult = resultCode
	return successful, resultCode
end

function ServerDataService.savePlayer(player: Player, reason: SaveReason?): (boolean, ResultCode)
	if getDependencies() == nil then
		return false, "NOT_INITIALIZED"
	end
	if not isPlayer(player) then
		return false, "INVALID_PLAYER"
	end

	local session = protectedSession(player)
	if session == nil then
		return false, "NOT_FOUND"
	end
	if session.state == "Loading" then
		return false, "NOT_LOADED"
	elseif session.state == "LoadFailed" then
		return false, "LOAD_FAILED"
	elseif session.state == "Released" then
		return false, "RELEASED"
	elseif session.finalizeRequested then
		return false, "FINALIZING"
	elseif session.state == "Saving" or session.saveInFlight then
		return false, "SAVE_IN_PROGRESS"
	elseif session.state ~= "Loaded" then
		return false, "NOT_LOADED"
	end

	return saveSession(session, player, normalizeSaveReason(reason))
end

function ServerDataService.finalizePlayer(player: Player, reason: FinalizeReason?): (boolean, ResultCode)
	local configured = getDependencies()
	if configured == nil then
		return false, "NOT_INITIALIZED"
	end
	if not isPlayer(player) then
		return false, "INVALID_PLAYER"
	end

	local getOk, rawSession = pcall(configured.sessions.getSession, player)
	if not getOk then
		return false, "INVALID_DATA"
	end
	if rawSession == nil then
		return true, "RELEASED"
	end
	if not validateSession(rawSession, player, false) then
		return false, "INVALID_DATA"
	end
	local session = rawSession :: Session
	if session.state == "Released" then
		return true, "RELEASED"
	end

	session.finalizeRequested = true
	if session.saveInFlight or session.state == "Saving" then
		return false, "SAVE_IN_PROGRESS"
	end

	local saveSucceeded = true
	local saveResult: ResultCode = "OK"
	if session.state == "Loaded" and session.dirty then
		local finalizeReason = normalizeFinalizeReason(reason)
		saveSucceeded, saveResult = saveSession(session, player, finalizeReason :: SaveReason)
	end
	if not saveSucceeded then
		session.finalizeRequested = false
		session.state = "Loaded"
		session.saveInFlight = false
		session.lastResult = saveResult
		return false, saveResult
	end

	session.state = "Released"
	session.saveInFlight = false
	session.lastResult = saveResult
	setLoadAttributes(player, false, session.lastResult == "LOAD_FAILED")

	local removeOk, removed = pcall(configured.sessions.removeSession, player)
	if not removeOk or not removed then
		return false, "INVALID_DATA"
	end
	return saveSucceeded, saveResult
end

return table.freeze(ServerDataService)
