local constants = require(script.Parent.constants)

local config = {
	-- The text to show on the modal that appears after clicking the token
	-- tracker
	infoModalText = "Find all the tokens to complete",

	-- The speed at which the tokens rotate. Set to 0 to prevent rotation.
	tokenRotationSpeed = 20,

	navigationBeam = {	
		-- The color of the beam
		color = ColorSequence.new(Color3.fromRGB(255, 170, 0)),

		-- The light emission used to determine how much light the Beam
		lightEmission = 0.5,

		-- The light influence emitted by the Beam
		lightInfluence = 0,

		-- Determines whether the Beam.Segments of the Beam will always face
		-- the camera regardless of its orientation.
		faceCamera = constants.navigationBeam.faceCamera,

		-- The content ID of the texture to be displayed on the Beam.
		texture = constants.navigationBeam.texture,

		-- Determines the manner in which the texture scales and repeats.
		textureMode = constants.navigationBeam.textureMode,

		-- Determines the transparency of the Beam across its segments.
		transparency = constants.navigationBeam.transparency,

		-- Curve size at the first attachment
        curveSize0 = 0,

        -- Curve size at the second attachment
        curveSize1 = 0,

        -- Z-offset for the beam
        zOffset = 0,

		-- Maximum distance (in studs) at which the beam will appear
		maxBeamDistance = 10,
	},

	-- If true then a beam from the player to the nearest token will be
	-- shown
	showNavigationBeam = constants.navigationBeam.shown,
}

return config
