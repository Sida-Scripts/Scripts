-- [[¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯]] --
-- [[												]] --
-- [[			Sida's Lux - Double Rainbow			]] --
-- [[												]] --
-- [[_______________________________________________]] --

if myHero.charName ~= "Lux" then return end
local qPart, ePart, lastE = nil, nil, 0
local qSpeed, qDelay = 1.2, 234
local eSpeed, eDelay = 3.4, 220
local rSpeed, rDelay = 10, 500
local ts
local enemyMinions
local sparks = {}
local jungle = {
				Vilemaw = {obj = nil, name = "TT_Spiderboss7.1.1"},
				Baron = {obj = nil, name = "Worm12.1.1"},
				Dragon = {obj = nil, name = "Dragon6.1.1"},
				Golem1 = {obj = nil, name = "AncientGolem1.1.1"},
				Golem2 = {obj = nil, name = "AncientGolem7.1.1"},
				--LizardElder1 = {obj = nil, name = "LizardElder4.1.1"},
				--LizardElder2 = {obj = nil, name = "LizardElder10.1.1"},
}

LuxConfig = scriptConfig("Sida's Lux - Double Rainbow", "SidasLux")
LuxConfig:addParam("combo", "Combo", SCRIPT_PARAM_ONKEYDOWN, false, 219)
LuxConfig:addParam("harass", "Harras", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("D"))
LuxConfig:addParam("autoE", "Auto-pop E", SCRIPT_PARAM_ONOFF, true)
LuxConfig:addParam("killSteal", "Kill Steal", SCRIPT_PARAM_ONOFF, true)
LuxConfig:addParam("attackSpark", "Attack Spark", SCRIPT_PARAM_ONOFF, true)
LuxConfig:addParam("useUlt", "Auto Ult On Caged Enemy", SCRIPT_PARAM_ONOFF, true)
LuxConfig:addParam("useE", "Auto E On Caged Enemy", SCRIPT_PARAM_ONOFF, true)
LuxConfig:addParam("jungleSteal", "Jungle Steal", SCRIPT_PARAM_ONOFF, true)
LuxConfig:addParam("movement", "Move To Mouse", SCRIPT_PARAM_ONOFF, true)
LuxConfig:addParam("draw", "Draw Circles", SCRIPT_PARAM_ONOFF, true)
ts = TargetSelector(TARGET_LOW_HP_PRIORITY, 1190, DAMAGE_MAGIC, true)
ts.name = "Lux"
LuxConfig:addTS(ts)
enemyMinions = minionManager(MINION_ENEMY, 1190, player, MINION_SORT_HEALTH_ASC)

function OnTick()
	ts:update()
	enemyMinions:update()
	if LuxConfig.autoE then checkE() end
	if LuxConfig.killSteal then ultSteal() end
	foundQ()
	if LuxConfig.jungleSteal then checkJungleKillable() end
	if ts.target and ValidTarget(ts.target, 1190, true) then
		if LuxConfig.combo then Combo() end
		if LuxConfig.harass then Harass() end
	elseif LuxConfig.movement and (LuxConfig.harass or LuxConfig.combo) then
		myHero:MoveTo(mousePos.x, mousePos.z)
	end
end

function OnLoad()
	for i = 0, objManager.maxObjects do
		local obj = objManager:getObject(i)
		for _, mob in pairs(jungle) do
			if obj and obj.valid and obj.name:find(mob.name) then
				mob.obj = obj
			end
		end
	end
end

function Harass()
	castE(ts.target)
	if LuxConfig.attackSpark and hasSpark() then 
		myHero:Attack(ts.target)
	elseif LuxConfig.movement then
		myHero:MoveTo(mousePos.x, mousePos.z)
	end
end

function Combo()
	castQ(ts.target)
	if not CanCast(_Q) then castE(ts.target) end
	if LuxConfig.attackSpark and hasSpark() then 
		myHero:Attack(ts.target)
	elseif LuxConfig.movement then
		myHero:MoveTo(mousePos.x, mousePos.z)
	end
end

function castE(target)
	if CanCast(_E) and ePart == nil then
		local ePos = getPred(eSpeed, eDelay, target)
		if ePos and GetDistance(ePos) <= 1300 then
			CastSpell(_E, ePos.x, ePos.z)
		end
	end
end

function castQ(target)
	if CanCast(_Q) then
		local qPos = getPred(qSpeed, qDelay, target)
		if qPos and GetDistance(qPos) <= 1170 and not willHitMinion(qPos, 130) then
			CastSpell(_Q, qPos.x, qPos.z)
		end
	end
end

function ultSteal()
	for i = 1, heroManager.iCount do
		local enemy = heroManager:getHero(i)
		if CanCast(_R) and ValidTarget(enemy, 3000, true) and enemy.health < getDmg("R",enemy,myHero) - 50 then
			local rPos = getPred(rSpeed, rDelay, enemy)
			if rPos ~= nil and GetDistance(rPos) < 3000 then
				CastSpell(_R, rPos.x, rPos.z)
			end
		end
	end
end

function foundQ()
	if qPart ~= nil and qPart.valid then
		if CanCast(_E) and LuxConfig.useE then CastSpell(_E, qPart.x, qPart.z) end
		if CanCast(_R) and LuxConfig.useUlt then CastSpell(_R, qPart.x, qPart.z) end
	end
end

function OnCreateObj(obj)
	if obj ~= nil and obj.valid then
		if obj.name:lower():find("luxlightbinding") and isObjectOnEnemy(obj) then
			qPart = obj
		elseif obj.name:lower():find("luxlightstrike") and GetTickCount() < lastE + 2000 then
			ePart = obj;
		elseif obj.name:find("LuxDebuff") then
			table.insert(sparks, obj)
		else
			checkJungleCreated(obj)
		end
	end
end

function OnDeleteObj(obj)
	if obj == qPart then 
		qPart = nil
	elseif obj == ePart then 
		ePart = nil
	else
		deleteSpark(obj)
		checkJungleDeleted(obj)
	end
end

function OnProcessSpell(unit, spell)
	if unit.isMe and spell ~= nil and spell.name:lower():find("luxlightstrike") then
		lastE = GetTickCount()
	end
end	

function isObjectOnEnemy(obj)
	for i = 1, heroManager.iCount do
		local enemy = heroManager:getHero(i)
		if enemy.team ~= myHero.team and not enemy.dead and GetDistance(enemy, obj) < 50 then
			return true 
		end
	end
	return false
end

function CanCast(spell)
	return myHero:CanUseSpell(spell) == READY
end

function getPred(speed, delay, target)
	if target == nil then return nil end
	local travelDuration = (delay + GetDistance(myHero, target)/speed)
	travelDuration = (delay + GetDistance(GetPredictionPos(target, travelDuration))/speed)
	travelDuration = (delay + GetDistance(GetPredictionPos(target, travelDuration))/speed)
	travelDuration = (delay + GetDistance(GetPredictionPos(target, travelDuration))/speed) 	
	return GetPredictionPos(target, travelDuration)
end

function checkJungleDeleted(obj)
	for _, mob in pairs(jungle) do
		if obj ~= nil and obj.name == mob.name then mob.obj = nil end
	end
end

function checkJungleCreated(obj)
	for _, mob in pairs(jungle) do
		if obj ~= nil and obj.name == mob.name then mob.obj = obj end
	end
end

function checkJungleKillable()
	for _, mob in pairs(jungle) do
		if mob.obj ~= nil and mob.obj.valid and not mob.obj.dead 
		and GetDistance(mob.obj) < 2999 and CanCast(_R) 
		and mob.obj.health < getDmg("R",mob.obj,myHero) then
			CastSpell(_R, mob.obj.x, mob.obj.z)
		end
	end
end

function checkE()
	if ePart ~= nil and ePart.valid then
		for i = 1, heroManager.iCount do
			local enemy = heroManager:getHero(i)
			if ValidTarget(enemy, 1190, true) and GetDistance(ePart, enemy) < 300 then
				CastSpell(_E)
			end
		end
	end
end

function OnDraw()
	if not LuxConfig.draw then return end
	if ts.target ~= nil then
		DrawCircle(ts.target.x, ts.target.y, ts.target.z, 150, 0xFF00FF00)
		DrawCircle(ts.target.x, ts.target.y, ts.target.z, 151, 0xFF00FF00)
		DrawCircle(ts.target.x, ts.target.y, ts.target.z, 152, 0xFF00FF00)
		DrawCircle(ts.target.x, ts.target.y, ts.target.z, 153, 0xFF00FF00)
		--local qPos = getPred(rSpeed, rDelay, ts.target)
		--if qPos ~= nil then DrawCircle(qPos.x, qPos.y, qPos.z, 100, 0xFFFFFF) end
	end
	DrawCircle(myHero.x, myHero.y, myHero.z, 550, 0xFFFFFF)
end

function deleteSpark(obj)
	for _, spark in pairs(sparks) do
		if spark == obj then
			spark = nil
		end
	end
end

function hasSpark()
	for _, spark in pairs(sparks) do
		if spark ~= nil and spark.valid and GetDistance(ts.target) < 540 + getHitBoxRadius(ts.target) and GetDistance(spark, ts.target) < 100 then
			return true
		end
	end
	return false
end

function willHitMinion(predic, width)
	local hitCount = 0
	for _, minionObjectE in pairs(enemyMinions.objects) do
		 if minionObjectE ~= nil and string.find(minionObjectE.name,"Minion_") == 1 and minionObjectE.team ~= player.team and minionObjectE.dead == false then
			 if predic ~= nil and player:GetDistance(minionObjectE) < 900 then
				 ex = player.x
				 ez = player.z
				 tx = predic.x
				 tz = predic.z
				 dx = ex - tx
				 dz = ez - tz
				 if dx ~= 0 then
				 m = dz/dx
				 c = ez - m*ex
				 end
				 mx = minionObjectE.x
				 mz = minionObjectE.z
				 distanc = (math.abs(mz - m*mx - c))/(math.sqrt(m*m+1))
				 if distanc < width and math.sqrt((tx - ex)*(tx - ex) + (tz - ez)*(tz - ez)) > math.sqrt((tx - mx)*(tx - mx) + (tz - mz)*(tz - mz)) then
					hitCount = hitCount + 1
					if hitCount > 1 then
						return true
					end
				 end
			 end
		 end
	 end
	 return false
end

function getHitBoxRadius(target)
    return GetDistance(target.minBBox, target.maxBBox)/2
end

PrintChat("Sida's Lux Enabled")