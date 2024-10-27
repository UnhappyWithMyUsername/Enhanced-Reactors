Hook.Add("item.created", "EnhancedReactors.ItemCreated", function (item)
    EnhancedReactors.ProcessItem(item)
end)

Hook.Add("item.removed", "EnhancedReactors.ItemRemoved", function (item)
    EnhancedReactors.RemoveItem(item)
end)

for item in Item.ItemList do
    EnhancedReactors.ProcessItem(item)
end

Hook.Add("think", "EnhancedReactors.Update", function ()
    EnhancedReactors.Update()
end)

Hook.Add("EnhancedReactors.Disable", function ()
    return true
end)