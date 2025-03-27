local tokensFolder = script.Parent.Parent:FindFirstChild("Tokens")

return function(tokenInstance, tokenName)
	assert(tokenInstance and (tokenInstance:IsA("BasePart") or tokenInstance:IsA("Model")), 
		"registerToken: Token must be a BasePart or Model")

	-- Use instance name if no name provided
	tokenName = tokenName or tokenInstance.Name
	assert(type(tokenName) == "string", 
		"registerToken: Token name must be a string")
	
    local tokenClone = tokenInstance:Clone()
    tokenClone.Name = tokenName
	tokenClone.Parent = tokensFolder
end
