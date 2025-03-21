local constants = {
	navigationBeam = {
		faceCamera = true,
		texture = "rbxassetid://8081777495",
		textureMode = Enum.TextureMode.Wrap,
		transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.15, 1),
			NumberSequenceKeypoint.new(1, 1),
		}),
		color = ColorSequence.new(Color3.fromRGB(255, 255, 255)),
		textureLength = 1,
		textureSpeed = 1,
		segments = 10,
		width0 = 1,
		width1 = 1,
		shown = true
	}
}

return constants
