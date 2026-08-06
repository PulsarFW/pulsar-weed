local Config = load(LoadResourceFile(GetCurrentResourceName(), "config/shared.lua"))()
local ServerConfig = load(LoadResourceFile(GetCurrentResourceName(), "config/server.lua"))()

local _packagesAvailable = 5
local _weedBuyers = {}

function RegisterCallbacks()
	plsr.Callbacks:RegisterServerCallback("Weed:CheckPlant", function(source, pid, cb)
		if pid ~= nil and _plants[pid] then
			if checkNearPlant(source, pid) then
				cb({
					plant = _plants[pid].plant,
					ground = ServerConfig.GroundTypes[Config.Materials[_plants[pid].plant.material].groundType],
				})
			else
				cb(nil)
			end
		else
			cb(nil)
		end
	end)

	plsr.Callbacks:RegisterServerCallback("Weed:WaterPlant", function(source, pid, cb)
		if pid ~= nil and _plants[pid] then
			if checkNearPlant(source, pid) then
				local char = plsr.Fetch:CharacterSource(source)
				if char ~= nil then
					if _plants[pid] ~= nil then
						if _plants[pid].plant.water < 100 then
							if plsr.Inventory.Items:Has(char:GetData("SID"), 1, "water", 1) then
								plsr.Inventory.Items:Remove(char:GetData("SID"), 1, "water", 1)
								local amt = 10.0
								if 100 - _plants[pid].plant.water < 10 then
									amt = (100 - _plants[pid].plant.water) + 0.0
								end
								_plants[pid].plant.water = _plants[pid].plant.water + amt
							else
								plsr.Execute:Client(source, "Notification", "Error", "You Don't Have Water")
							end
						else
							plsr.Execute:Client(source, "Notification", "Error", "Plant Is Already Watered")
						end
					else
						plsr.Execute:Client(source, "Notification", "Error", "Invalid Plant")
					end
				end
			else
				cb(nil)
			end
		end
	end)

	plsr.Callbacks:RegisterServerCallback("Weed:FertilizePlant", function(source, data, cb)
		if data and data.id and _plants[data.id] then
			if checkNearPlant(source, data.id) then
				local char = plsr.Fetch:CharacterSource(source)
				if char ~= nil then
					if _plants[data.id] ~= nil then
						if _plants[data.id].plant.fertilizer == nil then
							if
								plsr.Inventory.Items:Has(char:GetData("SID"), 1, string.format("fertilizer_%s", data.type), 1)
							then
								plsr.Inventory.Items:Remove(
									char:GetData("SID"),
									1,
									string.format("fertilizer_%s", data.type),
									1
								)
								_plants[data.id].plant.fertilizer = {
									type = data.type,
									time = ServerConfig.Fertilizer[data.type].time,
									value = ServerConfig.Fertilizer[data.type].value,
								}
							else
								plsr.Execute:Client(source, "Notification", "Error", "You Don't Have Fertilizer")
							end
						else
							plsr.Execute:Client(source, "Notification", "Error", "Plant Is Already Fertilized")
						end
					else
						plsr.Execute:Client(source, "Notification", "Error", "Invalid Plant")
					end
				end
			else
				cb(nil)
			end
		end
	end)

	plsr.Callbacks:RegisterServerCallback("Weed:HarvestPlant", function(source, pid, cb)
		if pid then
			if checkNearPlant(source, pid) then
				if _plants[pid] ~= nil then
					local char = plsr.Fetch:CharacterSource(source)
					if char ~= nil then
						local stage = Config.Plants[getStageByPct(_plants[pid].plant.growth)]
						if stage.harvestable then
							if _plants[pid].plant.isMale then
								local luck = math.random(100)
								local giving = "weedseed_male"
								if luck >= (100 - ServerConfig.FemSeedChance) then
									giving = "weedseed_female"
								end
								if
									plsr.Inventory:AddItem(
										char:GetData("SID"),
										giving,
										math.random(math.ceil(_plants[pid].plant.output / 16)),
										{},
										1
									)
								then
									plsr.Weed.Planting:Delete(pid)
									plsr.Logger:Info(
										"Weed",
										string.format(
											"%s %s (%s) Harvested A Weed Plant",
											char:GetData("First"),
											char:GetData("Last"),
											char:GetData("SID")
										)
									)
									cb(true)
								else
									cb(false)
								end
							else
								local t = math.random(math.ceil((_plants[pid].plant.output / 4)))
								if t < 1 then
									t = 3
								end

								if plsr.Inventory:AddItem(char:GetData("SID"), "weed_bud", t, {}, 1) then
									plsr.Weed.Planting:Delete(pid)
									cb(true)
								else
									cb(false)
								end
							end
						else
							cb(nil)
						end
					else
						cb(nil)
					end
				else
					cb(nil)
				end
			else
				cb(nil)
			end
		else
			cb(nil)
		end
	end)

	plsr.Callbacks:RegisterServerCallback("Weed:DestroyPlant", function(source, pid, cb)
		local char = plsr.Fetch:CharacterSource(source)
		if char ~= nil then
			if pid and _plants[pid] then
				if checkNearPlant(source, pid) then
					plsr.Weed.Planting:Delete(pid)
					plsr.Logger:Info(
						"Weed",
						string.format(
							"%s %s (%s) Destroyed A Weed Plant",
							char:GetData("First"),
							char:GetData("Last"),
							char:GetData("SID")
						)
					)
					plsr.Execute:Client(source, "Notification", "Success", "Plant Has Been Destroyed")
				else
					cb(nil)
				end
			else
				cb(nil)
			end
		else
			cb(nil)
		end
	end)

	plsr.Callbacks:RegisterServerCallback("Weed:PDDestroyPlant", function(source, pid, cb)
		if pid and _plants[pid] then
			if checkNearPlant(source, pid) then
				local char = plsr.Fetch:CharacterSource(source)
				if char ~= nil then
					if plsr.State:Player(source).onDuty == "police" then
						plsr.Weed.Planting:Delete(pid)
						plsr.Logger:Info(
							"Weed",
							string.format(
								"%s %s (%s) PD Destroyed A Weed Plant",
								char:GetData("First"),
								char:GetData("Last"),
								char:GetData("SID")
							)
						)
						plsr.Execute:Client(source, "Notification", "Success", "Plant Has Been Destroyed")
					else
						cb(nil)
					end
				else
					cb(nil)
				end
			else
				cb(nil)
			end
		else
			cb(nil)
		end
	end)

	plsr.Callbacks:RegisterServerCallback("Weed:BuyPackage", function(source, data, cb)
		local char = plsr.Fetch:CharacterSource(source)

		if char ~= nil then
			if _packagesAvailable > 0 and not _weedBuyers[char:GetData("ID")] then
				if plsr.Wallet:Modify(source, -ServerConfig.PackagePrice) then
					plsr.Logger:Info(
						"Weed",
						string.format(
							"%s %s (%s) Bought Weed Package",
							char:GetData("First"),
							char:GetData("Last"),
							char:GetData("SID")
						)
					)
					_packagesAvailable -= 1
					_weedBuyers[char:GetData("ID")] = true

					local luck = math.random(100)
					local giving = "weedseed_male"
					local giving2 = "fertilizer_nitrogen"
					if luck >= 95 then
						giving = "weedseed_female"
					end

					if luck >= 66 then
						giving2 = "fertilizer_phosphorus"
					elseif luck >= 33 then
						giving2 = "fertilizer_potassium"
					end

					--Reputation.Modify:Add(source, "weed", 1000)
					plsr.Inventory:AddItem(char:GetData("SID"), giving, 2, {}, 1)
					plsr.Inventory:AddItem(char:GetData("SID"), giving2, 2, {}, 1)
				else
					plsr.Logger:Info(
						"Weed",
						string.format(
							"%s %s (%s) Bought Weed Package",
							char:GetData("First"),
							char:GetData("Last"),
							char:GetData("SID")
						)
					)
					plsr.Execute:Client(source, "Notification", "Error", "Dont Have Enough Cash")
					cb(false)
				end
			else
				plsr.Logger:Info(
					"Weed",
					string.format(
						"%s %s (%s) Bought Weed Package",
						char:GetData("First"),
						char:GetData("Last"),
						char:GetData("SID")
					)
				)
				if _packagesAvailable > 0 then
					plsr.Execute:Client(source, "Notification", "Error", "You've Already Bought A Package")
				else
					plsr.Execute:Client(source, "Notification", "Error", "No Packages Available")
				end
				cb(false)
			end
		else
			cb(false)
		end
	end)
end
