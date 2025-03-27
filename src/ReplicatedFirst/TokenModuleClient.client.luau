local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local TokenModule = require(ReplicatedStorage:WaitForChild("TokenModule"))

local tokenSpawnZone1 = CollectionService:GetTagged("TokenSpawnZone1")

local SPAWN_OFFSET = Vector3.new(0, 2, 0)

local tokens = {}
local connections = {}

--[[
	Disconnects existing connections
]]
local function disconnectOldConnections()
	for _, connection in ipairs(connections) do
		if connection then
			connection:Disconnect()
		end
	end

	connections = {}
end

local function spawnToken(tokenSpawn)
	if tokenSpawn then
		local tokenType = nil --tokenSpawn.TokenType.Value
		local spawnLocation = tokenSpawn.CFrame + SPAWN_OFFSET
		local tokenRespawn = tokenSpawn.Respawn.Value

		local token = TokenModule.createToken(tokenType, spawnLocation, tokenRespawn)
		token:spawnToken()
		
		-- Add the spawned token to the tokens table
		table.insert(tokens, token)
	else
		warn("One or more of the arguments to spawnToken are nil")
	end
end

local function spawnTokens()
	-- Create a local connection for this specific player
	local playerConnection = TokenModule.collected:Connect(function(player, tokenType)
		print(player, tokenType)
	end)
	
	local tokenConnection = TokenModule.tokenRespawn:Connect(function(player, tokenType, spawnLocation)
		print(player, tokenType, spawnLocation)
	end)
	
	-- Add the player connection to the connections table
	table.insert(connections, playerConnection)
	table.insert(connections, tokenConnection)

	-- Spawn tokens for the specific player
	for _, tokenSpawn in pairs(tokenSpawnZone1) do
		spawnToken(tokenSpawn)
	end
end

local function deleteTokens()
	-- Destroy and clean up all spawned tokens
	for _, token in pairs(tokens) do
		token:cleanupToken()
		token = nil
	end

	-- Clean up old data if it exists
	disconnectOldConnections()
end

spawnTokens()
