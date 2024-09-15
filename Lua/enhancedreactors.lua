EnhancedReactors.ManagedItems = {}

Util.RegisterItemGroup("reactors", function (item)
    return item.GetComponentString("Reactor") ~= nil
end)

local reactors = {
    ["reactor1"] = true,
    ["outpostreactor"] = true,
    ["ekdockyard_reactorslow_small"] = true,
    ["ekdockyard_reactor_mini"] = true,
    ["ekdockyard_reactor_small"] = true
}

local fuelRods = {
    ["fuelrod"] = 1,
    ["thoriumfuelrod"] = 1.1,
    ["fulguriumfuelrod"] = 2,
    ["fulguriumfuelrodvolatile"] = 3
}

EnhancedReactors.ProcessItem = function (item)
    if reactors[item.Prefab.Identifier.Value] then
        item.AddTag("lua_managed")
        table.insert(EnhancedReactors.ManagedItems, item)
    end

    if fuelRods[item.Prefab.Identifier.Value] then
        item.AddTag("lua_managed")
        item.AddTag("fuelrod")
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

local overheating = AfflictionPrefab.Prefabs["overheating"]
local radiationSickness = AfflictionPrefab.Prefabs["radiationsickness"]
local contaminated = AfflictionPrefab.Prefabs["contaminated"]
local radiationSounds = AfflictionPrefab.Prefabs["radiationsounds"]
local burn = AfflictionPrefab.Prefabs["burn"]

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
        local parentCharacter = nil

        if inventory then
            if LuaUserData.IsTargetType(inventory, "Barotrauma.ItemInventory") then
                parentItem = inventory.Owner
            else
                parentCharacter = inventory.Owner
            end
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

            if parentCharacter then
                local slot = inventory.FindIndex(item)

                if slot == inventory.FindLimbSlot(InvSlotType.RightHand) then
                    parentCharacter.CharacterHealth.ApplyAffliction(parentCharacter.AnimController.GetLimb(InvSlotType.RightHand), burn.Instantiate(1))
                elseif slot == inventory.FindLimbSlot(InvSlotType.LeftHand) then
                    parentCharacter.CharacterHealth.ApplyAffliction(parentCharacter.AnimController.GetLimb(InvSlotType.LeftHand), burn.Instantiate(1))
                end
            end
        end

        if reactor then
            if parentItem.ConditionPercentage < 75 then
                local strength = fuelRods[item.Prefab.Identifier.Value]
                for character in Character.CharacterList do
                    EnhancedReactors.ApplyAfflictionRadius(item, character, 750, 2, {
                        radiationSickness.Instantiate((0.45 - parentItem.ConditionPercentage * 0.006) * strength),
                        contaminated.Instantiate((0.45 - parentItem.ConditionPercentage * 0.006) * strength),
                        radiationSounds.Instantiate((2.9 - parentItem.ConditionPercentage * 0.038) * strength),
                        overheating.Instantiate((0.18 - parentItem.ConditionPercentage * 0.0024) * strength)
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