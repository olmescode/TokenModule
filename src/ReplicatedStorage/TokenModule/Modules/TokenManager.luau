local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local TokenModule = script:FindFirstAncestor("TokenModule")

local config = require(TokenModule.config)
local collected = require(TokenModule.events)
local animateHighlight = require(TokenModule.Components.animateHighlight)

local tokenCollected = TokenModule.Remotes.TokenCollected

local tokensFolder = TokenModule.Tokens

local tokens = {}
for _, child in ipairs(tokensFolder:GetChildren()) do
	tokens[child.Name] = child
end

local TokenManager = {}
TokenManager.__index = TokenManager

type Token = BasePart | Model

type TokenManager = {
	collisionConnections: { [string]: { RBXScriptConnection } },
	enabled: boolean,
	token: Token,
	respawnable: boolean,
	location: Vector3,
	tokenCollected: RemoteEvent,
	tokenRespawn : BindableEvent,
	collected: BindableEvent,
	tween: Tween,
	rotationEnabled: boolean,
	tokenRotationSpeed: number,
	rotationHeartbeatConnection: RBXScriptConnection
}

--[[
	Creates a new TokenManager that manages the current tokens in use in the experience.

	Parameters:
		tokenType: (string) Optional. The type of the token to create. If not provided, a random token will be selected.
		spawnLocation: (Vector3) The initial spawn location for the token.
		shouldRespawn: (boolean) Whether the token should respawn after being collected.
]]
function TokenManager.new(tokenType, spawnLocation, shouldRespawn)
	local self: TokenManager = {
		collisionConnections = {},
		enabled = true,
		token = nil,
		respawnable = shouldRespawn,
		location = spawnLocation,
		tokenCollected = tokenCollected,
		tokenRespawn = collected.tokenRespawn,
		collected = collected.collected,
		tween = nil,
		rotationEnabled = false,
		tokenRotationSpeed = 0,
		rotationHeartbeatConnection = nil
	}
	
	if tokenType then
		self.token = tokens[tokenType]:Clone()
	else
		local newTokens = {}
		for index, value in pairs(tokens) do
			table.insert(newTokens, value)
		end
		-- Get a random token from the tokens dictionary
		local randomIndex = math.random(1, #newTokens)
		--local randomKey = next(tokens, randomIndex)
		self.token = newTokens[randomIndex]:Clone()
	end
	
	setmetatable(self, TokenManager)
	
	self:spawnToken()
	self.tween = animateHighlight(self.token)
	
	return self
end

--[[
	Spawn a token to the given location

	Returns:
	True if the token was added to the workspace
]]
function TokenManager:spawnToken()
	local destination = self.location
	local touchedEvent, touchEndedEvent
	
	if self.token:IsA("BasePart") or self.token:IsA("MeshPart") then
		self.token.CFrame = CFrame.new(destination.Position)
		self.token.CanCollide = false
		touchedEvent = self.token.Touched
		touchEndedEvent = self.token.TouchEnded
	elseif self.token:IsA("Model") then
		if self.token.PrimaryPart then
			self.token.PrimaryPart.Position = destination.Position
			touchedEvent = self.token.PrimaryPart.Touched
			touchEndedEvent = self.token.PrimaryPart.TouchEnded

			for _, child in ipairs(self.token:GetDescendants()) do
				if child:IsA("BasePart") then
					child.CanCollide = false
				end
			end
		else
			warn(string.format("The Model %s needs to have a PrimaryPart.", self.token.Name))
			return false
		end
	else
		warn(string.format("The token %s needs to be a Model or BasePart.", self.token.Name))
		return false
	end

	self.collisionConnections[self.token.Name] = {
		touchedEvent:Connect(function(otherPart)
			self:onTouched(self.token, otherPart)
		end),
		touchEndedEvent:Connect(function(otherPart)
			self:onTouchEnded(self.token, otherPart)
		end),
	}
	
	self.token.Parent = workspace
	
	self:enableRotation()
	
	return true
end

--[[
	Add the token rotation functionality
]]
function TokenManager:enableRotation()
	self.rotationEnabled = true
	self.tokenRotationSpeed = config.tokenRotationSpeed
	
	self.rotationHeartbeatConnection = RunService.Heartbeat:Connect(function(deltaTime)
		if self.rotationEnabled then
			local angle = CFrame.Angles(0, math.rad(1) * deltaTime * self.tokenRotationSpeed, 0)

			-- Rotate tokens and not regions
			if self.token:IsA("Model") then
				self.token:SetPrimaryPartCFrame(self.token.PrimaryPart.CFrame * angle)
			else
				self.token.CFrame = self.token.CFrame * angle
			end
		end
	end)
end

--[[
	Disable the token rotation functionality
]]
function TokenManager:disableRotation()
	self.rotationEnabled = false
	self.tokenRotationSpeed = 0

	if self.rotationHeartbeatConnection then
		self.rotationHeartbeatConnection:Disconnect()
		self.rotationHeartbeatConnection = nil
	end
end

--[[
	Removes a token from the workspace

	Returns:
	The token that was removed or nil if there was no a token
]]
function TokenManager:removeToken(): Token
	local removedToken = self.token

	if removedToken then
		self.token.Parent = nil

		if self.collisionConnections[self.token.Name] then
			for _, connection in ipairs(self.collisionConnections[self.token.Name]) do
				connection:Disconnect()
			end
			self.collisionConnections[self.token.Name] = nil
		end
	end

	return removedToken
end

--[[
	Returns the current collection of tokens

	Returns:
	The current collectioned token
]]
function TokenManager:getToken(): Token
	return self.token
end

--[[
	Called when there is a collision with a token. If the part that collided
	with the token is a player, that player is informed that the token has
	been collected. Also checks if all tokens have been collected

	Parameters:
	token: The token that has been collided into
	otherPart: The BasePart that has collided with the token
]]
function TokenManager:onTouched(token: BasePart, otherPart: BasePart)
	if not self.enabled then
		return
	end

	-- Look for a humanoid in the parent
	if otherPart.Name == "HumanoidRootPart" and otherPart.Parent then
		local humanoid = otherPart.Parent:FindFirstChildWhichIsA("Humanoid")
		if humanoid then
			local player = Players:GetPlayerFromCharacter(humanoid.Parent)
			if player then
				self.collected:Fire(player, token.Name)
			end
		end
	end
end

--[[
	Called when the collision with a token ends. If the part that collided
	with the token is a player, that player is informed that they have stopped
	colliding with the token.

	Parameters:
	token: The token that has been stopped being collided into
	otherPart: The BasePart that was colliding with the token
]]
function TokenManager:onTouchEnded(token: BasePart, otherPart: BasePart)
	if not self.enabled then
		return
	end

	-- This event is only relevant when a humanoid stops touching the part
	if otherPart.Name == "HumanoidRootPart" and otherPart.Parent then
		local humanoid = otherPart.Parent:FindFirstChildWhichIsA("Humanoid")
		if humanoid then
			local player = Players:GetPlayerFromCharacter(humanoid.Parent)
			if player then
				self.tokenCollected:FireServer(token.Name)
				
				if self.respawnable then
					self.tokenRespawn:Fire(player, token.Name, self.location)
				end
				
				self:cleanupToken()
			end
		end
	end
end

--[[
	Allows tokens to be collected
]]
function TokenManager:enable()
	self.enabled = true
end

--[[
	Prevents tokens from being collected
]]
function TokenManager:disable()
	self.enabled = false
end

--[[
	Frees resources used by the tokens currently tracked. Keeps current player
	userids around so that players can be properly informed of changes
]]
function TokenManager:cleanupToken()
	for _, connections in pairs(self.collisionConnections) do
		for _, connection in ipairs(connections) do
			if connection then
				connection:Disconnect()
			end
		end
	end

	self.collisionConnections = {}
	
	if self.rotationHeartbeatConnection then
		self.rotationHeartbeatConnection:Disconnect()
		self.rotationHeartbeatConnection = nil
	end
	
	if self.token then
		self.token:Destroy()
		self.tokens = nil
	end
	
	if self.tween then
		self.tween:Destroy()
		self.tween = nil
	end
	
	self.enabled = nil
	self.respawnable = nil
	self.location = nil
	self.tokenCollected = nil
	self.tokenRespawn = nil
	self.collected = nil
	self.rotationEnabled = nil
	self.tokenRotationSpeed = nil
end

return TokenManager
