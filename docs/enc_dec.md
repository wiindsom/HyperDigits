---
sidebar_position: 2
---

# Leaderboard Pseudocode

---

What we have here is a pseudocode in how you would get this working with leaderboards.

IMPORTANT NOTE: fromString already handles JSONDecoding internally. Therefore why you don't see JSONDecode anywhere.

```lua
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local HyperDigits = require("HyperDigits")

local currentData = HyperDigits.fromString("1e123")

local leaderboardStore = DataStoreService:GetOrderedDataStore("qwerty")
local valueStore = DataStoreService:GetDataStore("abcdef")

type userData = { key: string, value: number }

local function saveData(player: Player, value: HyperDigits.HyperDigits)
	local current = value:encode()

	if typeof(current) ~= "number" then
		return
	end

	local key = tostring(player.UserId)
	leaderboardStore:UpdateAsync(key, function(old)
		old = old or 0
		if current > old then
			return current
		end
		return old
	end)

	local base = value:toBase()
	local json = HttpService:JSONEncode(base)
	valueStore:SetAsync(key, json)
end

local function getDisplayValue(userId: number, encoded: number)
	local key = tostring(userId)

	local success, value = pcall(function()
		return valueStore:GetAsync(key)
	end)

	if success and type(value) == "string" and value ~= "" then
		local toFormat = HyperDigits.fromString(value)
		return toFormat:toString()
	end

	return HyperDigits.decode(encoded):toString()
end

local function getTop(size: number)
	local pages = leaderboardStore:GetSortedAsync(true, size)
	local page = pages:GetCurrentPage()

	local rows = {}
	for rank, entry: userData in page do
		local userId = tonumber(entry.key)
		local encoded = entry.value

		if userId then
			local display = getDisplayValue(userId, encoded)
            
			table.insert(rows, {
				rank = rank;
				userId = userId;
				encoded = encoded;
				display = display;
			})
		end
	end
	return rows
end

local top_10 = getTop(10)

for _, row in top_10 do
	print(`Rank: {row.rank}`)
	print(`Player: {Players:GetPlayerByUserId(row.userId).Name}`)
	print(`Amount: {row.display}`)
end
```
