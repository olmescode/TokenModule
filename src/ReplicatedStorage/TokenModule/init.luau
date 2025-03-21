print("Required TokenModule")

local NavigationBeam = require(script.Components.NavigationBeam)
local events = require(script.events)

local TokenModule = {
	-- Configurations
	
	-- Server and client APIs
	createToken = require(script.Api.createToken), 
	
	-- Events
	collected = events.collected.Event,
	tokenRespawn = events.tokenRespawn.Event,
	
	-- Remotes
	remotes = script.Remotes
}

return TokenModule
