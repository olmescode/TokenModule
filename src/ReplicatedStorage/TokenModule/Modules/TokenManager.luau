local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local TokenModule = script:FindFirstAncestor("TokenModule")

local t = require(TokenModule.Packages.t)
local config = require(TokenModule.config)
local events = require(TokenModule.events)
local animateHighlight = require(TokenModule.Components.animateHighlight)

local tokensFolder = TokenModule.Tokens
local spawnPromptTemplate = TokenModule.SpawnPrompt

-- Constants
local RESPAWN_TIME = 10
local TOKEN_DESTROY_DELAY = 1

local tokens = {}

local TokenManager = {}
TokenManager.__index = TokenManager

type Token = BasePart | Model
type RBXConnection = RBXScriptConnection

type TokenManager = {
	_connections: { RBXScriptConnection },
	_token: Token,
	_tokenName: string,
	_spawnLocation: Vector3,
	_respawnable: boolean,
	_enabled: boolean,
	_respawnTime: number,
	_tokenCollected: BindableEvent?
}

--[[
	Creates a new TokenManager that manages the current token in use in the experience.

	Parameters:
		tokenName: (string) Optional. The type of the token to create. If not provided, a random token will be selected.
		spawnLocation: (Vector3) The initial spawn location for the token.
		shouldRespawn: (boolean) Whether the token should respawn after being collected.
]]
function TokenManager.new(tokenName, tokenSpawn, tokenRespawn)
	if tokenName ~= nil then
		assert(tokens[tokenName], "Bad argument #1 to TokenModule.createToken: invalid token name")
	end
	assert(t.CFrame(tokenSpawn), "Bad argument #2 to TokenModule.createToken: expected a CFrame")
	assert(t.boolean(tokenRespawn), "Bad argument #3 to TokenModule.createToken: expected a boolean")

	local self: TokenManager = setmetatable({}, TokenManager)

	self._connections = {}

	self._token = nil
	self._tokenName = nil
	self._spawnLocation = tokenSpawn
	self._respawnable = tokenRespawn
	self._enabled = true
	self._respawnTime = RESPAWN_TIME
	self._tokenCollected = events.tokenCollected

	local availableTokens = tokensFolder:GetChildren()
	assert(#availableTokens > 0, "No tokens registered. Please register tokens first")
	
	for _, child in ipairs(availableTokens) do
		tokens[child.Name] = child
	end

	-- Check if the tokenName is provided
	if tokenName then
		self._token = tokens[tokenName]:Clone()
	else
		-- Select a random token from the available tokens
		local randomIndex = math.random(1, #availableTokens)
		self._token = availableTokens[randomIndex]:Clone()
	end

	self._tokenName = self._token:GetFullName()

	self:_initialize()

	return self
end

function TokenManager:_initialize()
	self.tween = nil
	self.tokenCollector = nil
	self.location = self._spawnLocation
	self.respawnable = self._respawnable
	self.rotationEnabled = false
	self.tokenRotationSpeed = 0

	-- Set up event connections
	self.attributeConnection = self._token.AttributeChanged:Connect(function(attributeName)
		if attributeName == "TokenCollected" then
			self._tokenCollected:Fire(self._tokenName, self.tokenCollector)

			-- Clean up the current token instance
			task.delay(TOKEN_DESTROY_DELAY, function()
				self:_destroyToken()
				self:_respawn()
			end)
		end
	end)

	--[[
	local touchedEvent, touchEndedEvent

	if self._token:IsA("BasePart") or self._token:IsA("MeshPart") then
		touchedEvent = self._token.Touched
		touchEndedEvent = self._token.TouchEnded
	elseif self._token:IsA("Model") then
		if self._token.PrimaryPart then
			touchedEvent = self._token.PrimaryPart.Touched
			touchEndedEvent = self._token.PrimaryPart.TouchEnded
		else
			warn(string.format("The Model %s needs to have a PrimaryPart.", self._token.Name))
			return false
		end
	else
		warn(string.format("The token %s needs to be a Model or BasePart.", self._token.Name))
		return false
	end

	self._collisionConnections = {
		touchedEvent:Connect(function(otherPart)
			self:onTouched(self._tokenName, otherPart)
		end),
		touchEndedEvent:Connect(function(otherPart)
			self:onTouchEnded(self._tokenName, otherPart)
		end),
	}
	--]]

	-- Set up proximity prompt
	self:_setupProximityPrompt()
end

function TokenManager:_setupProximityPrompt()
	local spawnPrompt = self._token:FindFirstChildOfClass("ProximityPrompt")

	if not spawnPrompt then
		spawnPrompt = spawnPromptTemplate:Clone()
	end

	self.promptConnection = spawnPrompt.Triggered:Connect(function(player)
		if not self._enabled then
			return
		end

		self:_trackCollectorState(player)
		self._token:SetAttribute("TokenCollected", true)
	end)

	spawnPrompt.Parent = self._token
end

function TokenManager:_trackCollectorState(player)
	self.tokenCollector = player.Character

	local character = self.tokenCollector
	local humanoid = character:FindFirstChildOfClass("Humanoid") :: Humanoid

	-- Debounce to prevent duplicate events when humanoid dies
	local alreadyDied = false
	local diedConnection, removedConnection

	local function onDied()
		if alreadyDied then
			return
		end
		alreadyDied = true

		diedConnection:Disconnect()
		removedConnection:Disconnect()

		self.tokenCollector = nil
		self:_respawn()
	end

	diedConnection = humanoid.Died:Connect(onDied)

	removedConnection = character.AncestryChanged:Connect(function()
		if not character:IsDescendantOf(workspace) then
			onDied()
		end
	end)

	table.insert(self._connections, diedConnection)
	table.insert(self._connections, removedConnection)
end

-- Spawn a token to the given location
function TokenManager:spawnToken()
	self._token:PivotTo(self._spawnLocation)
	self._token.Parent = workspace

	-- TODO: Animate in the client
	self:_handleTokenEffects()

	return true
end

function TokenManager:_handleTokenEffects()
	self.tween = animateHighlight(self._token)
	-- Uncomment if rotation is needed
	-- self:enableRotation()
end

function TokenManager:_cloneNewToken()
	return tokens[self._tokenName]:Clone()
end

function TokenManager:_respawn()
	if not self._respawnable or self.tokenCollector then
		return
	end

	-- Clone a new token instance
	self._token = self:_cloneNewToken()

	-- Schedule a new task for respawn
	self.respawnTask = task.delay(self._respawnTime, function()
		self.respawnTask = nil

		self:_initialize()
		self:spawnToken()
	end)
end

function TokenManager:enableRotation()
	self.rotationEnabled = true
	self.tokenRotationSpeed = config.tokenRotationSpeed

	self.rotationHeartbeatConnection = RunService.Heartbeat:Connect(function(deltaTime)
		if not self.rotationEnabled then return end

		local angle = CFrame.Angles(0, math.rad(1) * deltaTime * self.tokenRotationSpeed, 0)
		local token = self._token

		if token:IsA("Model") then
			token:SetPrimaryPartCFrame(token.PrimaryPart.CFrame * angle)
		else
			token.CFrame = token.CFrame * angle
		end
	end)
end

function TokenManager:disableRotation()
	self.rotationEnabled = false
	self.tokenRotationSpeed = 0

	if self.rotationHeartbeatConnection then
		self.rotationHeartbeatConnection:Disconnect()
		self.rotationHeartbeatConnection = nil
	end
end

-- Returns the current owner of the token
function TokenManager:getCurrentOwner()
	return self.tokenCollector
end

-- Returns the current token
function TokenManager:getToken(): Token
	return self._token
end

--[[
	Called when there is a collision with a token. If the part that collided
	with the token is a player, that player is informed that the token has
	been collected
]]
function TokenManager:onTouched(tokenName: string, otherPart: BasePart)
	if not self._enabled then
		return
	end

	self._token:SetAttribute("TokenCollected", nil)

	-- Look for a humanoid in the parent
	if otherPart.Name == "HumanoidRootPart" and otherPart.Parent then
		local humanoid = otherPart.Parent:FindFirstChildWhichIsA("Humanoid")
		if humanoid then
			local player = Players:GetPlayerFromCharacter(humanoid.Parent)
			if player then
				self.hittingTarget = player.Character
				self._token:SetAttribute("TokenCollected", true)
			end
		end
	end
end

--[[
	Called when the collision with a token ends. If the part that collided
	with the token is a player, that player is informed that they have stopped
	colliding with the token
]]
function TokenManager:onTouchEnded(token: BasePart, otherPart: BasePart)
	if not self._enabled then
		return
	end

	-- This event is only relevant when a humanoid stops touching the part
	if otherPart.Name == "HumanoidRootPart" and otherPart.Parent then
		local humanoid = otherPart.Parent:FindFirstChildWhichIsA("Humanoid")
		if humanoid then
			local player = Players:GetPlayerFromCharacter(humanoid.Parent)
			if player then
				self._tokenCollected:Fire(self._tokenName, self.tokenCollector)
			end
		end
	end
end

-- Allows tokens to be collected
function TokenManager:enable()
	self._enabled = true
end

-- Prevents tokens from being collected
function TokenManager:disable()
	self._enabled = false
end

function TokenManager:_destroyToken()
	self.promptConnection:Disconnect()
	--self.rotationHeartbeatConnection:Disconnect()

	if self._token then
		self._token:Destroy()
		self._token = nil
	end

	if self.tween then
		self.tween:Destroy()
		self.tween = nil
	end
end

function TokenManager:destroy()
	self._respawnable = false

	-- Clean up all connections
	for _, connection in ipairs(self._connections) do
		if connection then
			connection:Disconnect()
			connection = nil
		end
	end

	self.connections = nil

	if self.attributeConnection then
		self.attributeConnection:Disconnect()
		self.attributeConnection = nil
	end

	if self.promptConnection then
		self.promptConnection:Disconnect()
		self.promptConnection = nil
	end

	if self.rotationHeartbeatConnection then
		self.rotationHeartbeatConnection:Disconnect()
		self.rotationHeartbeatConnection = nil
	end

	-- Clean up instances
	if self._token then
		self._token:Destroy()
		self._token = nil
	end

	if self.tween then
		self.tween:Destroy()
		self.tween = nil
	end

	-- Cancel the previous scheduled task if it exists
	if self.respawnTask then
		task.cancel(self.respawnTask)
		self.respawnTask = nil
	end

	task.wait()
end

return TokenManager
