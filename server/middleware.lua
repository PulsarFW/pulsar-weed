local ServerConfig = load(LoadResourceFile(GetCurrentResourceName(), "config/server.lua"))()

_weedDealer = ServerConfig.Locations[tostring(os.date("%w"))]

function RegisterMiddleware()
	plsr.Middleware:Add("Characters:Spawning", function(source)
		TriggerClientEvent("Weed:Client:Login", source, _weedDealer)

		TriggerLatentClientEvent("Weed:Client:Objects:Init", source, 10000, _plants)
	end)
end

