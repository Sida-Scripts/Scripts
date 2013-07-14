--[[ Sida's Auto Carry Plugin: Vayne ]]--
		
if myHero.charName ~= "Vayne" then return end

require "MapPosition"

local Condemn = {spellKey = _E, range = 715, speed = 1.5, delay = 1000, width=200}
local mapPosition = MapPosition()

AutoCarry.PluginMenu:addParam("condemnAutoCarry", "Condemn In Auto Carry Mode", SCRIPT_PARAM_ONOFF, true)
AutoCarry.PluginMenu:addParam("condemnMixedMode", "Condemn In Mixed Mode", SCRIPT_PARAM_ONOFF, true)
AutoCarry.PluginMenu:addParam("pushDistance", "Push Distance", SCRIPT_PARAM_SLICE, 450, 0, 450, 0)

function PluginOnLoad()
	AutoCarry.SkillsCrosshair.range = 650
end

function PluginOnTick()
	if myHero.dead then return end
	local active = (AutoCarry.PluginMenu.condemnAutoCarry and AutoCarry.MainMenu.AutoCarry) or (AutoCarry.PluginMenu.condemnMixedMode and AutoCarry.MainMenu.MixedMode)
	if active and myHero:CanUseSpell(_E) == READY then
		local target = AutoCarry.GetAttackTarget()
		DoCondemn(target)
	end
end

function DoCondemn(enemy)
	if ValidTarget(enemy, 715) then
		local enemyPos = AutoCarry.GetPrediction(Condemn, enemy)
		if not enemyPos then return end
		local pushPos = GetDistance(enemyPos) > 65 and enemyPos + (Vector(enemyPos) - myHero):normalized()*AutoCarry.PluginMenu.pushDistance or nil
		if pushPos and enemyPos then
			local enemyPoint = Point(enemyPos.x, enemyPos.z)
			local condemnPoint = Point(pushPos.x, pushPos.z)
			local lineSegment = LineSegment(enemyPoint, condemnPoint)
			local wall = mapPosition:intersectsWall(lineSegment)
			if wall then
				CastSpell(_E, enemy)
			end
		end
	end
end