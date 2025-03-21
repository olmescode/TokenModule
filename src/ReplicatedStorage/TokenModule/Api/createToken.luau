local TokenManager = require(script.Parent.Parent.Modules.TokenManager)

return function(tokenType, tokenRespawn, spawnLocation)
	return TokenManager.new(tokenType, tokenRespawn, spawnLocation)
end
