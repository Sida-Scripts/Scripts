-- ###################################################################################################### --
-- #                                                                                                    # --
-- #                                           Shrooooooooooooooms                                      # --
-- #                                                by Sida                                             # --
-- #                                                                                                    # --
-- ###################################################################################################### --

------------- Configuration ------------------

local highEnabled 	  = true -- Enable High Priority Mushrooms
local medEnabled 	  = true -- Enable Medium Priority Mushrooms
local lowEnabled 	  = true -- Enable Low Priority Mushrooms
local blueEnabled 	  = true -- Enable Blue Team Mushrooms (in and around blue jungle)
local purpEnabled 	  = true -- Enable Purple Team Mushrooms (in and around purple jungle)

local autoShroomHigh  = true -- Auto-shroom high priority locations

local showLocationsInRange = 3000 -- When you press R, locations in this range will be shown
local showClose = true -- Show shroom locations that are close to you
local showCloseRange = 800

------------ > Don't touch anything below here unless changing colours/auto-shrooms < --------------

if myHero.charName ~= "Teemo" then return end

red, yellow, green, blue, purple = 0x990000, 0x993300, 0x00FF00, 0x000099, 0x660066

shroomSpots = {
	-- High priority for both sides
	HighPriority = 	{ 
						Locations = {
										{ x = 3316.20, 	y = -74.06, z = 9334.85},
										{ x = 4288.76, 	y = -71.71, z = 9902.76},
										{ x = 3981.86, 	y = 39.54, 	z = 11603.55},
										{ x = 6435.51, 	y = 47.51, 	z = 9076.02},
										{ x = 9577.91, 	y = 45.97, 	z = 6634.53},
										{ x = 7635.25, 	y = 45.09, 	z = 5126.81},
										{ x = 10731.51, y = -30.77, z = 5287.01},
										{ x = 9662.24, 	y = -70.79, z = 4536.15},
										{ x = 10080.45, y = 44.48, 	z = 2829.56}  
									},
						Colour = red,
						Enabled = highEnabled,
						Auto = autoShroomHigh
					},
-- Medium priority for both sides
	MediumPriority ={
						Locations = {
										{ x = 3283.18, 	y = -69.64, z = 10975.15},
										{ x = 2595.85, 	y = -74.00, z = 11044.66},
										{ x = 2524.10, 	y = 23.36, 	z = 11912.28},
										{ x = 4347.64, 	y = 43.34, 	z = 7796.28},
										{ x = 6093.20, 	y = -67.90, z = 8067.45},
										{ x = 7960.99, 	y = -73.41, z = 6233.09},
										{ x = 10652.57, y = -58.96, z = 3507.64},
										{ x = 11460.14, y = -63.94, z = 3544.83},
										{ x = 11401.81, y = -11.72, z = 2626.61}  
									},
						Colour = yellow,
						Enabled = medEnabled,
						Auto = false
					},
-- Low priority/situational for both sides
	LowPriority =	{
						Locations = {
										{ x = 1346.10, 	y = 26.56, 	z = 11064.81},
										{ x = 705.87,  	y = 26.93, 	z = 11359.88},
										{ x = 762.80,  	y = 26.15, 	z = 12210.61},
										{ x = 1355.53, 	y = 24.13, 	z = 12936.99},
										{ x = 1926.92, 	y = 25.14, 	z = 11567.44},
										{ x = 1752.22, 	y = 24.02, 	z = 13176.95},
										{ x = 2512.96, 	y = 21.74, 	z = 13524.44},
										{ x = 3577.42, 	y = 25.27, 	z = 12429.88},
										{ x = 5246.01, 	y = 30.91, 	z = 12508.33},
										{ x = 5549.60, 	y = 42.94, 	z = 10917.27},
										{ x = 6552.56, 	y = 47.09, 	z = 9688.99},
										{ x = 5806.41, 	y = 46.01, 	z = 9918.99},
										{ x = 7112.27, 	y = 46.86, 	z = 8443.55},
										{ x = 4896.10, 	y = -72.08, z = 8964.81},
										{ x = 3096.10, 	y = 45.41, 	z = 8164.81},
										{ x = 2390.53, 	y = 46.57, 	z = 5232.34},
										{ x = 4358.81, 	y = 45.83, 	z = 5834.64},
										{ x = 5746.10, 	y = 42.52, 	z = 4864.81},
										{ x = 6307.66, 	y = 46.07, 	z = 7165.92},
										{ x = 5443.82, 	y = 45.64, 	z = 7110.85},
										{ x = 5153.75, 	y = 45.41, 	z = 3358.76},
										{ x = 6876.07, 	y = 46.44, 	z = 5897.48},
										{ x = 6881.30, 	y = 46.08, 	z = 6555.85},
										{ x = 8555.10, 	y = 46.36, 	z = 7267.04},
										{ x = 7946.10, 	y = 44.19, 	z = 7214.81},
										{ x = 9088.99, 	y = -73.12, z = 5441.11},
										{ x = 7687.96, 	y = 46.12, 	z = 5203.08},
										{ x = 8559.97, 	y = 47.97, 	z = 3477.87},
										{ x = 8841.04, 	y = 52.28, 	z = 1944.09},
										{ x = 10582.93, y = 43.25, 	z = 1707.35},
										{ x = 11046.10, y = 43.26, 	z = 964.81},
										{ x = 11682.20, y = 43.40, 	z = 1061.03},
										{ x = 12420.51, y = 46.87, 	z = 1532.34},
										{ x = 12819.32, y = 45.74, 	z = 1931.32},
										{ x = 13275.52, y = 45.38, 	z = 2873.69},
										{ x = 11978.71, y = 45.49, 	z = 2914.69},
										{ x = 13379.36, y = 45.37, 	z = 3499.62},
										{ x = 12818.08, y = 45.38, 	z = 3625.44},
										{ x = 10985.17, y = 45.69, 	z = 6305.81},
										{ x = 11580.80, y = 41.26, 	z = 9214.09},
										{ x = 9574.88, 	y = 44.40, 	z = 8679.65},
										{ x = 8359.96, 	y = 44.37, 	z = 9595.58},
										{ x = 8927.12, 	y = 48.17, 	z = 11175.70}  
									},
						Colour = green,
						Enabled = lowEnabled,
						Auto = false
					},
-- blue team areas
	BlueOnly = {
						Locations = {
										{ x = 2112.87, y = 43.81, z = 7047.48},
										{ x = 2646.25, y = 45.84, z = 7545.78},
										{ x = 1926.95, y = 44.83, z = 9515.71},
										{ x = 4239.97, y = 44.40, z = 7132.02},
										{ x = 6149.34, y = 42.51, z = 4481.88},
										{ x = 6630.28, y = 46.56, z = 2836.88},
										{ x = 7687.62, y = 45.54, z = 3210.98},
										{ x = 7050.22, y = 46.46, z = 2351.33}   
									},
						Colour = blue,
						Enabled = blueEnabled,
						Auto = false
				},
-- purple team areas
	PurpleOnly = 	{
					Locations = {
									{ x = 7466.52, y = 41.54, z = 11720.22},
									{ x = 6945.85, y = 43.53, z = 11901.30},
									{ x = 6636.28, y = 45.03, z = 11079.65},
									{ x = 7878.53, y = 43.83, z = 10042.65},
									{ x = 9701.57, y = 45.72, z = 7298.22},
									{ x = 11358.86, y = 45.71, z = 6872.10},
									{ x = 11946.10, y = 45.80, z = 7414.81},
									{ x = 12169.52, y = 44.03, z = 4858.85}  
								},
					Colour = purple,
					Enabled = purpEnabled,
					Auto = false
				}
}


drawShroomSpots = false

function OnLoad()
	PrintChat(" >> Sida's Shrooooooooooooooms Loaded")
end

function OnTick()
	for i,group in pairs(shroomSpots) do
		for x, shroomSpot in pairs(group.Locations) do
			if group.Enabled and group.Auto and GetDistance(shroomSpot) <= 250 and not shroomExists(shroomSpot) then
				CastSpell(_R, shroomSpot.x, shroomSpot.z)
			end
		end
	end
end

function shroomExists(shroomSpot)
	for i=1, objManager.maxObjects do
	local obj = objManager:getObject(i)
		if obj ~= nil and obj.name:find("Noxious Trap") then
			if GetDistance(obj) <= 260 then
				return true
			end
		end
	end	
	return false
end

function OnWndMsg(msg,key)
	if msg == KEY_DOWN and key == 82 then
		if player:CanUseSpell(_R) == READY then
			drawShroomSpots = true
		end
	elseif msg == WM_LBUTTONDOWN and drawShroomSpots then
		for i,group in pairs(shroomSpots) do
			for x, shroomSpot in pairs(group.Locations) do
				if group.Enabled then
					if GetDistance(shroomSpot, mousePos) <= 250 then
							CastSpell(_R, shroomSpot.x, shroomSpot.z)
					end
				end
			end
		end
	elseif msg == WM_RBUTTONDOWN and drawShroomSpots then
                drawShroomSpots = false
	end
end

function drawCircles(x,y,z,colour)
	DrawCircle(x, y, z, 28, colour)
	DrawCircle(x, y, z, 29, colour)
	DrawCircle(x, y, z, 30, colour)
	DrawCircle(x, y, z, 31, colour)
	DrawCircle(x, y, z, 32, colour)
	DrawCircle(x, y, z, 250, colour)
	if colour == red or colour == blue
		or colour == purple or colour == yellow then
		DrawCircle(x, y, z, 251, colour)
		DrawCircle(x, y, z, 252, colour)
		DrawCircle(x, y, z, 253, colour)
		DrawCircle(x, y, z, 254, colour)
	end
end

function OnDraw()
	for i,group in pairs(shroomSpots) do
		if group.Enabled == true then
			if drawShroomSpots then
				for x, shroomSpot in pairs(group.Locations) do
					if GetDistance(shroomSpot) < showLocationsInRange then
						if GetDistance(shroomSpot, mousePos) <= 250 then
							shroomColour = 0xFFFFFF
						else
							shroomColour = group.Colour
						end
						drawCircles(shroomSpot.x, shroomSpot.y, shroomSpot.z,shroomColour)
					end
				end
			elseif showClose then
				for x, shroomSpot in pairs(group.Locations) do
					if GetDistance(shroomSpot) <= showCloseRange then
						if GetDistance(shroomSpot, mousePos) <= 250 then
							shroomColour = 0xFFFFFF
						else
							shroomColour = group.Colour
						end
						drawCircles(shroomSpot.x, shroomSpot.y, shroomSpot.z,shroomColour)
					end
				end
			end
		end
	end	
end