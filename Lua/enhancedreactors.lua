Util.RegisterItemGroup("reactors", function (item)
    return item.GetComponentString("Reactor") ~= nil
end)

EnhancedReactors.ProcessItem = function (item)
    if item.GetComponentString("Reactor") then
        item.AddTag("lua_managed")
    end
end

EnhancedReactors.ApplyAfflictionRadius = function (item, character, maxDistance, penetration, afflictionPrefab, amount)
    if Vector2.Distance(character.WorldPosition, item.WorldPosition) > maxDistance then
        return
    end

    local position = item.Position

    if afflictionPrefab.LimbSpecific then
        for limb in pairs(character.AnimController.Limbs) do
            local factor = math.min(Explosion.GetObstacleDamageMultiplier(ConvertUnits.ToSimUnits(position), position, limb.SimPosition) * penetration, 1)
            factor = factor * (1 - Vector2.Distance(character.WorldPosition, item.WorldPosition) / maxDistance)

            character.CharacterHealth.ApplyAffliction(limb, afflictionPrefab.Instantiate(amount * factor))
        end
    else
        local factor = math.min(Explosion.GetObstacleDamageMultiplier(ConvertUnits.ToSimUnits(position), position, character.SimPosition) * penetration, 1)
        factor = factor * (1 - Vector2.Distance(character.WorldPosition, item.WorldPosition) / maxDistance)

        print(factor)

        character.CharacterHealth.ApplyAffliction(nil, afflictionPrefab.Instantiate(amount * factor))
    end
end

local overheating = AfflictionPrefab.Prefabs["overheating"]

local timer = 0
EnhancedReactors.Update = function ()
    if Timer.GetTime() < timer then
        return
    end

    timer = Timer.GetTime() + 0.1

    for item in Util.GetItemGroup("reactors") do
        local reactor = item.GetComponentString("Reactor")
        if reactor.Temperature > 40 then
            for character in Character.CharacterList do
                EnhancedReactors.ApplyAfflictionRadius(item, character, 750, 2, overheating, 0.1)
            end
        end
    end
end