local Config = load(LoadResourceFile(GetCurrentResourceName(), "config/shared.lua"))()

_plants = {}

local _weedTableReady = false
function EnsureWeedTable(callback)
	if _weedTableReady then
		if callback then
			callback()
		end
		return
	end
	plsr.Database:Query("CREATE TABLE IF NOT EXISTS `weed` (`id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY, `data` JSON NOT NULL)", nil, function()
		_weedTableReady = true
		if callback then
			callback()
		end
	end)
end

CreateThread(function()
	Startup()
	RegisterMiddleware()
	RegisterCallbacks()
	RegisterTasks()
	RegisterItems()
end)

AddEventHandler("Proxy:Shared:RegisterReady", function()
	exports["pulsar_core"]:RegisterComponent("Weed", WEED)
end)

function getStageByPct(pct)
	local stagePct = 100 / (#Config.Plants - 1)
	return math.floor((pct / stagePct) + 1.5)
end

function checkNearPlant(source, id)
	local coords = GetEntityCoords(GetPlayerPed(source))
	if _plants[id] ~= nil then
		return #(
				vector3(coords.x, coords.y, coords.z)
				- vector3(_plants[id].plant.location.x, _plants[id].plant.location.y, _plants[id].plant.location.z)
			) <= 5
	else
		return false
	end
end

WEED = {
	Planting = {
		Set = function(self, id, isUpdate, skipEvent)
			if _plants[id] ~= nil then
				local stage = getStageByPct(_plants[id].plant.growth)
				_plants[id].stage = stage

				if skipEvent then
					return { id = id, plant = _plants[id], update = isUpdate }
				else
					TriggerClientEvent("Weed:Client:Objects:Update", -1, id, _plants[id], isUpdate)
				end
			end
		end,
		Delete = function(self, id, skipRemove)
			if _plants[id] ~= nil then
				_plants[id] = nil
				TriggerClientEvent("Weed:Client:Objects:Delete", -1, id)
			end
		end,
		Create = function(self, isMale, location, material)
			local p = promise.new()
			local weed = {
				isMale = isMale,
				location = location,
				growth = 0,
				output = 1,
				material = material,
				planted = os.time(),
				water = 100.0,
			}
			EnsureWeedTable(function()
				plsr.Database:Insert("INSERT INTO `weed` (`data`) VALUES (?)", { json.encode(weed) }, function(success, newId)
					if not success then
						return p:resolve(nil)
					end
					weed._id = newId
					return p:resolve(weed)
				end)
			end)
			return Citizen.Await(p)
		end,
	},
}
