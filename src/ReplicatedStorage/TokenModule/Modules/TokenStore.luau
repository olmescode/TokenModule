local TokenModule = script:FindFirstAncestor("TokenModule")
local tokensFolder = TokenModule.Tokens

local TokenStore = {}

-- Load initial tokens
for _, child in ipairs(tokensFolder:GetChildren()) do
	TokenStore[child.Name] = child
end

return TokenStore
