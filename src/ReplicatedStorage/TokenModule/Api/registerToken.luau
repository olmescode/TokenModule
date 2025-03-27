local TokenModule = script:FindFirstAncestor("TokenModule")
local tokenStore = require(TokenModule.Modules.TokenStore)

return function(tokenInstance, tokenName)
	assert(
		tokenInstance and (tokenInstance:IsA("BasePart") or tokenInstance:IsA("Model")),
		"registerToken: Token must be a BasePart or Model"
	)

	-- Use instance name if no name provided
	tokenName = tokenName or tokenInstance.Name
	assert(type(tokenName) == "string", "registerToken: Token name must be a string")

	local tokenClone = tokenInstance:Clone()
	tokenClone.Name = tokenName
	tokenClone.Parent = TokenModule.Tokens

	-- Update the shared token store dictionary
	tokenStore[tokenName] = tokenClone
end
