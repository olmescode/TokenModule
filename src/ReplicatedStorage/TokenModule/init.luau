print("Required TokenModule")

--local NavigationBeam = require(script.Components.NavigationBeam)
local events = require(script.events)

local TokenModule = {
	-- Configurations
	
	-- Server and client APIs
	createToken = require(script.Api.createToken),
	registerToken = require(script.Api.registerToken),
	
	-- Events
	onTokenCollected = events.tokenCollected.Event,

	-- Remotes
	remotes = script.Remotes
}

return TokenModule
