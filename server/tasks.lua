local Config = load(LoadResourceFile(GetCurrentResourceName(), "config/shared.lua"))()
local ServerConfig = load(LoadResourceFile(GetCurrentResourceName(), "config/server.lua"))()

local _run = false

function SaveAllPlants()
	local docs = {}
	for k, v in pairs(_plants) do
		if v and v.plant then
			table.insert(docs, v.plant)
		end
	end
	if #docs > 0 then
		plsr.Logger:Info("Weed", string.format("Saving ^2%s^7 Plants", #docs))
		EnsureWeedTable(function()
			local queries = { { query = "DELETE FROM `weed`", values = {} } }
			for k, doc in ipairs(docs) do
				table.insert(queries, {
					query = "INSERT INTO `weed` (`id`, `data`) VALUES (?, ?)",
					values = { doc._id, json.encode(doc) },
				})
			end
			plsr.Database:Transaction(queries)
		end)
	end
end

AddEventHandler("Core:Server:ForceSave", SaveAllPlants)

function RegisterTasks()
	if _run then return end
	_run = true
	
	CreateThread(function()
		while true do
			Wait((1000 * 60) * 10)
			SaveAllPlants()
		end
	end)
	
	CreateThread(function()
		while true do
			Wait((1000 * 60) * 10)
			plsr.Logger:Trace("Weed", "Growing Plants")
			local updatingStuff = {}

			for k, v in pairs(_plants) do
				if (os.time() - v.plant.planted) >= ServerConfig.Lifetime then
					plsr.Logger:Trace("Weed", "Deleting Weed Plant Because Some Dumb Cunt Didn't Harvest It")
					plsr.Weed.Planting:Delete(k)
				else
					if v.plant.growth < 100 then
						local mat = Config.Materials[v.plant.material]
						if mat ~= nil then
							local gt = ServerConfig.GroundTypes[mat.groundType]
							if gt ~= nil then
								local phosphorus = gt.phosphorus
								if v.plant.fertilizer ~= nil and v.plant.fertilizer.type == "phosphorus" then
									phosphorus = phosphorus + v.plant.fertilizer.value
								end
								v.plant.growth = v.plant.growth + (1 + phosphorus)
								if v.stage ~= getStageByPct(v.plant.growth) then
									local res = plsr.Weed.Planting:Set(k, true, true)
									if res then
										table.insert(updatingStuff, res)
									end
								end
							else
								plsr.Weed.Planting:Delete(k)
							end
						else
							plsr.Weed.Planting:Delete(k)
						end
					end
				end
			end

			if #updatingStuff > 0 then
				TriggerLatentClientEvent("Weed:Client:Objects:UpdateMany", -1, 30000, updatingStuff)
			end
		end
	end)
	
	CreateThread(function()
		while true do
			Wait((1000 * 60) * 20)
			plsr.Logger:Trace("Weed", "Increasing Plant Outputs")
			for k, v in pairs(_plants) do
				if v.plant.growth < 100 then
					local mat = Config.Materials[v.plant.material]
					if mat ~= nil then
						local gt = ServerConfig.GroundTypes[mat.groundType]
						if gt ~= nil then
							local nitrogen = gt.nitrogen
							if v.plant.fertilizer ~= nil and v.plant.fertilizer.type == "nitrogen" then
								nitrogen = nitrogen + v.plant.fertilizer.value
							end
							v.plant.output = (v.plant.output or 0) + (1 * (1 + nitrogen))
						end
					end
				end
			end
		end
	end)
	
	CreateThread(function()
		while true do
			Wait((1000 * 60) * 10)
			plsr.Logger:Trace("Weed", "Degrading Water")
			for k, v in pairs(_plants) do
				if v.plant.water > -25 then
					local mat = Config.Materials[v.plant.material]
					if mat ~= nil then
						local gt = ServerConfig.GroundTypes[mat.groundType]
						if gt ~= nil then
							local potassium = gt.potassium
							if v.plant.fertilizer ~= nil and v.plant.fertilizer.type == "potassium" then
								potassium = potassium + v.plant.fertilizer.value
							end
	
							v.plant.water = v.plant.water - ((1.0 * (1.0 + (1.0 - potassium))) - gt.water)
						else
							plsr.Weed.Planting:Delete(k)
						end
					else
						plsr.Weed.Planting:Delete(k)
					end
				else
					plsr.Logger:Trace("Weed", "Deleting Weed Plant Because Some Dumb Cunt Didn't Water It")
					plsr.Weed.Planting:Delete(k)
				end
			end
		end
	end)
	
	CreateThread(function()
		while true do
			Wait((1000 * 60) * 1)
			plsr.Logger:Trace("Weed", "Ticking Down Fertilizer")
			for k, v in pairs(_plants) do
				if v.plant.fertilizer ~= nil then
					if v.plant.fertilizer.time > 0 then
						v.plant.fertilizer.time = v.plant.fertilizer.time - 1
					else
						v.plant.fertilizer = nil
					end
				end
			end
		end
	end)
end
