--!strict

export type Listener = (reducedMotion: boolean) -> ()

export type Connection = {
	read Disconnect: (self: Connection) -> (),
}

local PresentationPreferences = {}
local reducedMotion = false
local listeners: { [Listener]: boolean } = {}

function PresentationPreferences.getReducedMotion(): boolean
	return reducedMotion
end

function PresentationPreferences.setReducedMotion(value: boolean)
	if type(value) ~= "boolean" then
		error("PresentationPreferences.setReducedMotion requires a boolean", 2)
	end
	if value == reducedMotion then
		return
	end
	reducedMotion = value
	for listener in listeners do
		pcall(listener, reducedMotion)
	end
end

function PresentationPreferences.subscribe(listener: Listener): Connection
	if type(listener) ~= "function" then
		error("PresentationPreferences.subscribe requires a listener", 2)
	end
	listeners[listener] = true
	local connected = true
	return table.freeze({
		Disconnect = function(_self: Connection)
			if not connected then
				return
			end
			connected = false
			listeners[listener] = nil
		end,
	})
end

return table.freeze(PresentationPreferences)
