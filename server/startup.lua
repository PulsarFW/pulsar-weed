local ServerConfig = load(LoadResourceFile(GetCurrentResourceName(), "config/server.lua"))()

local _started
function Startup()
	if _started then
		return
	end
	_started = true

	EnsureWeedTable(function()
		plsr.Database:Query("SELECT `id`, `data` FROM `weed`", nil, function(success, results)
			if not success then
				return
			end
			local count = 0
			for k, row in ipairs(results) do
				local ok, v = pcall(json.decode, row.data)
				if ok and type(v) == "table" then
					v._id = row.id
					if os.time() - v.planted <= ServerConfig.Lifetime then
						_plants[v._id] = {
							plant = v,
							stage = getStageByPct(v.growth),
						}
						count = count + 1
					end
				end
			end
			plsr.Logger:Trace("Weed", string.format("Loaded ^2%s^7 Weed Plants", count), { console = true })
		end)
	end)

	plsr.Reputation:Create("weed", "Weed", {
		{ label = "Rank 1", value = 3000 },
		{ label = "Rank 2", value = 6000 },
		{ label = "Rank 3", value = 12000 },
		{ label = "Rank 4", value = 21000 },
		{ label = "Rank 5", value = 50000 },
	}, true)
end
