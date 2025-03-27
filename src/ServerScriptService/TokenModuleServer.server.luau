local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local TokenModule = require(ReplicatedStorage:WaitForChild("TokenModule"))

local SPAWN_OFFSET = Vector3.new(0, 2, 0)

local tokens = {}

local function registerTokens()
	local customTokensFolder = ReplicatedStorage:FindFirstChild("CustomTokens")

	for _, tokenInstance in ipairs(customTokensFolder:GetChildren()) do
        if tokenInstance:IsA("BasePart") or tokenInstance:IsA("Model") then
			TokenModule.registerToken(tokenInstance)
        end
    end
end
local function spawnToken(tokenSpawn)
	if tokenSpawn then
		local tokenName = nil --tokenSpawn.TokenName.Value
		local spawnLocation = tokenSpawn.CFrame + SPAWN_OFFSET
		local tokenRespawn = tokenSpawn.Respawn.Value
		
		local token = TokenModule.createToken(tokenName, spawnLocation, tokenRespawn)
		token:spawnToken()
		
		-- Add the spawned token to the tokens table
		table.insert(tokens, token)
	else
		warn("One or more of the arguments to spawnToken are nil")
	end
end

local function spawnTokens()
	local tokenSpawners = CollectionService:GetTagged("TokenSpawn")
	for _, tokenSpawn in pairs(tokenSpawners) do
		spawnToken(tokenSpawn)
	end
end

local function cleanUpTokens()
	for _, token in ipairs(tokens) do
		token:destroy()
		token = nil
	end
	
	tokens = nil
end

-- Connect event for a token collected
TokenModule.onTokenCollected:Connect(function(tokenName, playerCharacter)
	print("Token collected: ", tokenName, playerCharacter)
end)

-- 
registerTokens()

-- Spawn tokens
spawnTokens()
