EnhancedReactors = {}

EnhancedReactors.Path = ...

LuaUserData.MakeMethodAccessible(Descriptors["Barotrauma.Explosion"], "GetObstacleDamageMultiplier")

dofile(EnhancedReactors.Path .. "/Lua/enhancedreactors.lua")
dofile(EnhancedReactors.Path .. "/Lua/hooks.lua")