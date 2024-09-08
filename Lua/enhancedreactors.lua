EnhancedReactors.ManagedItems = {}

Util.RegisterItemGroup("reactors", function (item)
    return item.GetComponentString("Reactor") ~= nil
end)

EnhancedReactors.ProcessItem = function (item)
    if item.GetComponentString("Reactor") then
        item.AddTag("lua_managed")

        table.insert(EnhancedReactors.ManagedItems, item)
    end

    if item.HasTag("fuelrod") then
        item.AddTag("lua_managed")
        table.insert(EnhancedReactors.ManagedItems, item)
    end
end

EnhancedReactors.ApplyAfflictionRadius = function (item, character, maxDistance, penetration, afflictions, noLimbCheck)
    if Vector2.Distance(character.WorldPosition, item.WorldPosition) > maxDistance then
        return
    end

    local position = item.Position

    if not noLimbCheck then
        for limb in pairs(character.AnimController.Limbs) do
            local factor = math.min(Explosion.GetObstacleDamageMultiplier(ConvertUnits.ToSimUnits(position), position, limb.SimPosition) * penetration, 1)
            factor = factor * (1 - Vector2.Distance(character.WorldPosition, item.WorldPosition) / maxDistance)

            for affliction in afflictions do
                affliction.Strength = affliction.Strength * factor
                if affliction.Prefab.LimbSpecific then
                    character.CharacterHealth.ApplyAffliction(limb, affliction)
                else
                    character.CharacterHealth.ApplyAffliction(nil, affliction)
                end
            end
        end
    else
        local factor = math.min(Explosion.GetObstacleDamageMultiplier(ConvertUnits.ToSimUnits(position), position, character.SimPosition) * penetration, 1)
        factor = factor * (1 - Vector2.Distance(character.WorldPosition, item.WorldPosition) / maxDistance)

        for affliction in afflictions do
            affliction.Strength = affliction.Strength * factor
            character.CharacterHealth.ApplyAffliction(nil, affliction)
        end
    end
end

local delta = 1/10

local overheating = AfflictionPrefab.Prefabs["overheating"]
local radiationSickness = AfflictionPrefab.Prefabs["radiationsickness"]
local contaminated = AfflictionPrefab.Prefabs["contaminated"]
local radiationSounds = AfflictionPrefab.Prefabs["radiationsounds"]

EnhancedReactors.ProcessItemUpdate = function (item)
    local reactor = item.GetComponentString("Reactor")
    if reactor then
        if reactor.Temperature > 40 then
            for character in Character.CharacterList do
                EnhancedReactors.ApplyAfflictionRadius(item, character, 750, 2, { overheating.Instantiate(0.05) }, true)
            end
        end
    end

    if item.HasTag("fuelrod") and item.HasTag("activefuelrod") then
        local inventory = item.ParentInventory

        local parentItem = nil

        if inventory and LuaUserData.IsTargetType(inventory, "Barotrauma.ItemInventory") then
            parentItem = inventory.Owner
        end

        local reactor = parentItem and parentItem.GetComponentString("Reactor") or nil

        if not parentItem or (not parentItem.HasTag("deepdivinglarge") and not parentItem.HasTag("containradiation")) then
            for character in Character.CharacterList do
                EnhancedReactors.ApplyAfflictionRadius(item, character, 750, 2, {
                    radiationSickness.Instantiate(1),
                    contaminated.Instantiate(1),
                    radiationSounds.Instantiate(1.25),
                    overheating.Instantiate(0.05)
            }, true)
            end

            if math.random() < 0.05 then
                FireSource(item.WorldPosition)
            end
        end

        if reactor then
            if parentItem.ConditionPercentage < 75 then
                for character in Character.CharacterList do
                    EnhancedReactors.ApplyAfflictionRadius(item, character, 750, 2, {
                        radiationSickness.Instantiate(0.45 - parentItem.ConditionPercentage * 0.006),
                        contaminated.Instantiate(0.45 - parentItem.ConditionPercentage * 0.006),
                        radiationSounds.Instantiate(2.9 - parentItem.ConditionPercentage * 0.038),
                        overheating.Instantiate(0.18 - parentItem.ConditionPercentage * 0.0024)
                    }, true)
                end
            end
        end
    end
end

local timer = 0
EnhancedReactors.Update = function ()
    if Timer.GetTime() < timer then
        return
    end

    timer = Timer.GetTime() + 0.1

    for item in EnhancedReactors.ManagedItems do
        EnhancedReactors.ProcessItemUpdate(item)
    end
end