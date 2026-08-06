function RegisterItems()
	plsr.Inventory.Items:RegisterUse("weedseed_male", "Weed", function(source, item)
		if GlobalState[string.format("%s:House", source)] == nil then
			local char = plsr.Fetch:CharacterSource(source)
			local veh = GetVehiclePedIsIn(GetPlayerPed(source))
			if veh == 0 then
				plsr.Callbacks:ClientCallback(source, "Weed:PlantingAnim", {}, function(data)
					if data.error == nil then
						plsr.Inventory.Items:RemoveList(char:GetData("SID"), 1, { { name = "weedseed_male", count = 1 } })
						local plant = plsr.Weed.Planting:Create(
							true,
							{ x = data.coords.x, y = data.coords.y, z = data.coords.z },
							data.material
						)
	
						_plants[plant._id] = {
							plant = plant,
						}
	
						plsr.Weed.Planting:Set(plant._id, false)
					else
						if data.error == 2 then
							plsr.Execute:Client(source, "Notification", "Error", "Need Better Soil")
						elseif data.error == 3 then
							plsr.Execute:Client(source, "Notification", "Error", "Too Close")
						end
					end
				end)
			else
				plsr.Execute:Client(source, "Notification", "Error", "Can't Plan While In A Vehicle")
			end
		else
			plsr.Execute:Client(source, "Notification", "Error", "Plant Needs Natural Light")
		end
	end)

	plsr.Inventory.Items:RegisterUse("weedseed_female", "Weed", function(source, item)
		if GlobalState[string.format("%s:House", source)] == nil then
			local char = plsr.Fetch:CharacterSource(source)
			local veh = GetVehiclePedIsIn(GetPlayerPed(source))
			if veh == 0 then
				plsr.Callbacks:ClientCallback(source, "Weed:PlantingAnim", {}, function(data)
					if data.error == nil then
						plsr.Inventory.Items:RemoveList(char:GetData("SID"), 1, { { name = "weedseed_female", count = 1 } })
						local plant = plsr.Weed.Planting:Create(
							false,
							{ x = data.coords.x, y = data.coords.y, z = data.coords.z },
							data.material
						)
	
						_plants[plant._id] = {
							plant = plant,
						}
	
						plsr.Weed.Planting:Set(plant._id, false)
					else
						if data.error == 2 then
							plsr.Execute:Client(source, "Notification", "Error", "Need Better Soil")
						elseif data.error == 3 then
							plsr.Execute:Client(source, "Notification", "Error", "Too Close")
						end
					end
				end)
			else
				plsr.Execute:Client(source, "Notification", "Error", "Can't Plan While In A Vehicle")
			end
		else
			plsr.Execute:Client(source, "Notification", "Error", "Plant Needs Natural Light")
		end
	end)

	plsr.Inventory.Items:RegisterUse("rolling_paper", "Weed", function(source, item)
		local char = plsr.Fetch:CharacterSource(source)
		if plsr.Inventory.Items:Has(char:GetData("SID"), 1, "weed_bud", 1) then
			plsr.Callbacks:ClientCallback(source, "Weed:RollingAnim", {}, function(success)
				if success then
					plsr.Inventory.Items:RemoveList(
						char:GetData("SID"),
						1,
						{ { name = "rolling_paper", count = 1 }, { name = "weed_bud", count = 1 } }
					)
					plsr.Inventory:AddItem(char:GetData("SID"), "weed_joint", 2, {}, 1)
				end
			end)
		else
			plsr.Execute:Client(source, "Notification", "Error", "You need bud you fucking idiot")
		end
	end)

	plsr.Inventory.Items:RegisterUse("weed_joint", "Weed", function(source, item)
		local char = plsr.Fetch:CharacterSource(source)
		plsr.Callbacks:ClientCallback(source, "Weed:SmokingAnim", {}, function(success, count)
			plsr.Inventory.Items:RemoveList(char:GetData("SID"), 1, { { name = "weed_joint", count = 1 } })

			local stressTicks = {}
			for i = 0, count do
				table.insert(stressTicks, "3")
			end
			--Player(source).state.armorTicks = { "2", "2", "2", "2", "2" }
			--TriggerClientEvent("Damage:Client:Ticks:Armor", source)
			plsr.State:Player(source).stressTicks = stressTicks
		end)
	end)

	plsr.Inventory.Items:RegisterUse("weed_brick", "Weed", function(source, item)
		local char = plsr.Fetch:CharacterSource(source)
		if plsr.Inventory.Items:Has(char:GetData("SID"), 1, "weed_brick", 1) then
			plsr.Callbacks:ClientCallback(source, "Weed:MakingBrick", {
				label = "Unpacking Brick",
				time = 10,
			}, function(success)
				if success then
					plsr.Inventory.Items:RemoveList(char:GetData("SID"), 1, { { name = "weed_brick", count = 1 } })
					plsr.Inventory:AddItem(char:GetData("SID"), "weed_bud", 200, {}, 1)
				end
			end)
		else
			plsr.Execute:Client(source, "Notification", "Error", "You need 200 bud you fucking idiot")
		end
	end)

	plsr.Inventory.Items:RegisterUse("weed_baggy", "Weed", function(source, item)
		local char = plsr.Fetch:CharacterSource(source)
		if plsr.Inventory.Items:Has(char:GetData("SID"), 1, "weed_baggy", 1) then
			plsr.Callbacks:ClientCallback(source, "Weed:MakingBrick", {
				label = "Removing Bud",
				time = 3,
			}, function(success)
				if success then
					plsr.Inventory.Items:RemoveList(char:GetData("SID"), 1, { { name = "weed_baggy", count = 1 } })
					plsr.Inventory:AddItem(char:GetData("SID"), "weed_bud", 2, {}, 1)
				end
			end)
		else
			plsr.Execute:Client(source, "Notification", "Error", "You need 200 bud you fucking idiot")
		end
	end)
end
