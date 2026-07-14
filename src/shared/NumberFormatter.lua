--!strict

local NumberFormatter = {}

local SUFFIXES = {
	{ threshold = 1e3, suffix = "K" },
	{ threshold = 1e6, suffix = "M" },
	{ threshold = 1e9, suffix = "B" },
	{ threshold = 1e12, suffix = "T" },
	{ threshold = 1e15, suffix = "Qa" },
}

local SCIENTIFIC_THRESHOLD = 1e18
local SMALL_SCIENTIFIC_THRESHOLD = 0.01

local function toFiniteNumber(value: any): number?
	if type(value) ~= "number" and type(value) ~= "string" then
		return nil
	end

	local numberValue = tonumber(value)
	if numberValue == nil or numberValue ~= numberValue then
		return nil
	end
	if numberValue == math.huge or numberValue == -math.huge then
		return nil
	end

	return numberValue
end

local function trimDecimal(text: string): string
	local trimmed = string.gsub(text, "(%..-)0+$", "%1")
	trimmed = string.gsub(trimmed, "%.$", "")
	if trimmed == "-0" then
		return "0"
	end
	return trimmed
end

local function formatRounded(value: number): string
	return trimDecimal(string.format("%.2f", value))
end

local function formatScientific(absoluteValue: number): string
	local raw = string.format("%.2e", absoluteValue)
	local mantissa, exponent = string.match(raw, "^([^e]+)e([%+%-]?%d+)$")
	if mantissa == nil or exponent == nil then
		return "0"
	end

	local exponentNumber = tonumber(exponent)
	if exponentNumber == nil then
		return "0"
	end

	return trimDecimal(mantissa) .. "e" .. tostring(exponentNumber)
end

function NumberFormatter.format(value: any): string
	local numberValue = toFiniteNumber(value)
	if numberValue == nil or numberValue == 0 then
		return "0"
	end

	local sign = if numberValue < 0 then "-" else ""
	local absoluteValue = math.abs(numberValue)

	if absoluteValue >= SCIENTIFIC_THRESHOLD or absoluteValue < SMALL_SCIENTIFIC_THRESHOLD then
		return sign .. formatScientific(absoluteValue)
	end

	local suffixIndex = 0
	for index = #SUFFIXES, 1, -1 do
		if absoluteValue >= SUFFIXES[index].threshold then
			suffixIndex = index
			break
		end
	end

	-- Promote values that round across a suffix boundary, so the UI never shows
	-- awkward output such as 1000K when 1M is both shorter and clearer.
	while true do
		local divisor = if suffixIndex == 0 then 1 else SUFFIXES[suffixIndex].threshold
		local scaled = absoluteValue / divisor
		local rounded = math.floor(scaled * 100 + 0.5) / 100

		if rounded >= 1000 then
			if suffixIndex < #SUFFIXES then
				suffixIndex += 1
			else
				return sign .. formatScientific(absoluteValue)
			end
		else
			local suffix = if suffixIndex == 0 then "" else SUFFIXES[suffixIndex].suffix
			return sign .. formatRounded(rounded) .. suffix
		end
	end
end

local function twoDigits(value: number): string
	return string.format("%02d", value)
end

function NumberFormatter.formatTime(seconds: any): string
	local numberValue = toFiniteNumber(seconds)
	if numberValue == nil or numberValue <= 0 then
		return "0s"
	end

	local totalSeconds = math.floor(numberValue)
	if totalSeconds < 60 then
		return tostring(totalSeconds) .. "s"
	end

	if totalSeconds < 60 * 60 then
		local minutes = math.floor(totalSeconds / 60)
		local remainingSeconds = totalSeconds % 60
		return tostring(minutes) .. "m " .. twoDigits(remainingSeconds) .. "s"
	end

	if totalSeconds < 24 * 60 * 60 then
		local hours = math.floor(totalSeconds / (60 * 60))
		local remainingMinutes = math.floor(totalSeconds / 60) % 60
		return tostring(hours) .. "h " .. twoDigits(remainingMinutes) .. "m"
	end

	local days = math.floor(totalSeconds / (24 * 60 * 60))
	local remainingHours = math.floor(totalSeconds / (60 * 60)) % 24
	return NumberFormatter.format(days) .. "d " .. twoDigits(remainingHours) .. "h"
end

return NumberFormatter
