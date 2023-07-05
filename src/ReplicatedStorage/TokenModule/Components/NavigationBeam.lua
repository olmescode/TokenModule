local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local CollectionService = game:GetService("CollectionService")

local TokenModule = script:FindFirstAncestor("TokenModule")

local Cryo = require(TokenModule.Packages.Cryo)
local constants = require(TokenModule.constants)
local config = require(TokenModule.config)

local NavigationBeam = {}

NavigationBeam.props = {
	tokens = {},
}

function NavigationBeam:mountBean()
	local attachmentGuid = HttpService:GenerateGUID(false)
	self.playerAttachmentName = attachmentGuid .. "_player"
	self.tokenAttachmentName = attachmentGuid .. "_token"
	
	self.navigationBeam = Instance.new("Beam")
	
	local character = Players.LocalPlayer.Character
	if not character then
		character = Players.LocalPlayer.CharacterAdded:Wait()
	end
	self.humanoid = character:WaitForChild("Humanoid")
	
	-- Function to handle player death
	self.onDied = function()
		-- Remove old navigation beam
		self.playerAttachment = nil
		self.tokenAttachment = nil
		
		task.spawn(function()
			-- Wait for the player's character to respawn
			local character = Players.LocalPlayer.CharacterAdded:Wait()
			self.setupBeam(character)
		end)
	end
	
	-- Function to setup the navigation beam
	self.setupBeam = function(playerCharacter)
		local character = playerCharacter or Players.LocalPlayer.Character
		local humanoid = character:WaitForChild("Humanoid")
		local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
		local closestToken = self.findClosestTokenToPosition(humanoidRootPart.Position)
		
		-- After the waiting done above we need to ensure the Navigation
		-- Beam is still mounted before setting its state
		if not self.mounted then
			return
		end

		if not closestToken then
			self.playerAttachment = nil
			self.tokenAttachment = nil
			return
		end

		local playerAttachment = humanoidRootPart:FindFirstChild(self.playerAttachmentName)
		if not playerAttachment then
			playerAttachment = Instance.new("Attachment")
			playerAttachment.Name = self.playerAttachmentName
			playerAttachment.Parent = humanoidRootPart
		end

		local tokenAttachment = closestToken:FindFirstChild(self.tokenAttachmentName)
		if not tokenAttachment then
			tokenAttachment = Instance.new("Attachment")
			tokenAttachment.Name = self.tokenAttachmentName
			tokenAttachment.Parent = closestToken
		end

		self.playerAttachment = playerAttachment
		self.tokenAttachment = tokenAttachment
		self.humanoid = humanoid
		
		-- Render the navigation beam
		self:renderBean()
	end
	
	-- Function to find the closest token to a given position
	self.findClosestTokenToPosition = function(position)
		local closestToken = nil
		local lowestMagnitude = math.huge
		for _, token in ipairs(self.props.tokens) do
			-- Tokens can be Models or BaseParts
			local tokenBasePart = token:IsA("Model") and token.PrimaryPart or token
			local magnitude = (position - tokenBasePart.Position).Magnitude
			if magnitude < lowestMagnitude then
				closestToken = tokenBasePart
				lowestMagnitude = magnitude
			end
		end

		return closestToken
	end
	
	-- Event connection for player death
	self.humanoid.Died:Connect(self.onDied)
end

function NavigationBeam:renderBean()
	local navigationBeamConfig = Cryo.Dictionary.join(constants.navigationBeam, config.navigationBeam)
	
	self.navigationBeam.Attachment0 = self.playerAttachment
	self.navigationBeam.Attachment1 = self.tokenAttachment
	self.navigationBeam.Color = navigationBeamConfig.color
	self.navigationBeam.CurveSize0 = navigationBeamConfig.curveSize0
	self.navigationBeam.CurveSize1 = navigationBeamConfig.curveSize1
	self.navigationBeam.Enabled = navigationBeamConfig.shown
	self.navigationBeam.FaceCamera = navigationBeamConfig.faceCamera
	self.navigationBeam.LightEmission = navigationBeamConfig.lightEmission
	self.navigationBeam.LightInfluence = navigationBeamConfig.lightInfluence
	self.navigationBeam.Segments = navigationBeamConfig.segments
	self.navigationBeam.Texture = navigationBeamConfig.texture
	self.navigationBeam.TextureLength = navigationBeamConfig.textureLength
	self.navigationBeam.TextureMode = navigationBeamConfig.textureMode
	self.navigationBeam.TextureSpeed = navigationBeamConfig.textureSpeed
	self.navigationBeam.Transparency = navigationBeamConfig.transparency
	self.navigationBeam.Width0 = navigationBeamConfig.width0
	self.navigationBeam.Width1 = navigationBeamConfig.width1
	self.navigationBeam.ZOffset = navigationBeamConfig.zOffset
	self.navigationBeam.Parent = workspace
end

function NavigationBeam:init()
	self.mounted = true
	self.props.tokens = CollectionService:GetTagged("Token")
	
	self:mountBean()
	-- Every second, check for the closest token to the player and update the navigation beam
	task.spawn(function()
		while self.mounted do
			self:didUpdate()
			self.setupBeam()
			task.wait(1)
		end
	end)
end

function NavigationBeam:didUpdate()
	local newProps = CollectionService:GetTagged("Token")
	if self.props.tokens ~= newProps then
		self.props.tokens = nil
		self.props.tokens = newProps
	end
end

function NavigationBeam:unmount()
	self.mounted = false
end

NavigationBeam:init()

return NavigationBeam
