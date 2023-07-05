local TweenService = game:GetService("TweenService")

function animateHighlight(token)
	-- Get the Highlight effect from the token (assuming it's a child named "Highlight")
	local highlight = token:FindFirstChild("Highlight")
	
	if not highlight then
		return
	end

	-- Define the properties you want to animate
	local targetProperties = {
		FillTransparency = 1,  -- Example: Fade out the highlight by setting transparency to 1
		-- Add more properties you want to animate
	}

	-- Define the tween info (duration, easing style, etc.)
	local tweenInfo = TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, -1, true, 0)

	-- Create the tween
	local tween = TweenService:Create(highlight, tweenInfo, targetProperties)

	-- Play the tween
	tween:Play()
	
	return tween
end

return animateHighlight
