local TokenManager = require(script.Parent.Parent.Modules.TokenManager)

return function(tokenName, spawnLocation, tokenRespawn)
	return TokenManager.new(tokenName, spawnLocation, tokenRespawn)
end
