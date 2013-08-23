--[[
                Sida's Auto Carry: Revamped
                                v4.9
]]--
 
--[[ Configuration ]]--

local AutoCarryKey = 32
local LastHitKey = string.byte("X")
local MixedModeKey = string.byte("C")
local LaneClearKey = string.byte("V")

------------ > Don't touch anything below here < --------------
 
--[[ Vars ]] --
local projSpeed = 0
local startAttackSpeed = 0.665
local attackDelayOffset = 600
local lastAttack = 0
local projAt = 0
local Skills
local enemyMinions
local allyMinions
local lastEnemy
local lastRange
local killableMinion
local pluginMinion
local minionInfo = {}
local incomingDamage = {}
local jungleMobs = {}
local turretMinion = {timeToHit = 0, obj = nil}
local isMelee = myHero.range < 300
local movementStopped = false
local hasPlugin = false
local nextClick = 500
local TimedMode = false
local Tristana = false
local hudDisabled = false
local ChampInfo = {}
local useVIPCol = false
local lastAttacked = nil
local previousWindUp = 0
local previousAttackCooldown = 0
_G.AutoCarry = _G

 
--[[ Global Vars : Can be used by plugins ]]--
AutoCarry.Orbwalker = nil
AutoCarry.SkillsCrosshair = nil
AutoCarry.CanMove = true
AutoCarry.CanAttack = true
AutoCarry.MainMenu = nil
AutoCarry.PluginMenu = nil
AutoCarry.EnemyTable = nil
AutoCarry.shotFired = false
AutoCarry.OverrideCustomChampionSupport = false
AutoCarry.CurrentlyShooting = false
 
--[[ Global Functions ]]--
function getTrueRange()
    return myHero.range + GetDistance(myHero.minBBox)
end
 
function attackEnemy(enemy)
	if CustomAttackEnemy then CustomAttackEnemy(enemy) return end
    if enemy.dead or not enemy.valid or not AutoCarry.CanAttack then return end
	myHero:Attack(enemy)
	lastAttacked = enemy
	AutoCarry.shotFired = true
end
 
function getHitBoxRadius(target)
    return GetDistance(target.minBBox, target.maxBBox)/2
end
 
function timeToShoot()
	return (GetTickCount() + GetLatency()/2 > lastAttack + previousAttackCooldown)
end
 
function attackedSuccessfully()
    projAt = GetTickCount()
	if OnAttacked then OnAttacked() end
end
 
function heroCanMove()
	return (GetTickCount() + GetLatency()/2 > lastAttack + previousWindUp + 20 + 30)
end
 
function setMovement()
	if GetDistance(mousePos) <= AutoCarry.MainMenu.HoldZone and (AutoCarry.MainMenu.AutoCarry or AutoCarry.MainMenu.LastHit or AutoCarry.MainMenu.MixedMode or AutoCarry.MainMenu.LaneClear) then
		if not movementStopped then
			myHero:HoldPosition()
			movementStopped = true
		end
		AutoCarry.CanMove = false
	else
		movementStopped = false
		AutoCarry.CanMove = true
	end
end
 
function moveToCursor(range)
    if not disableMovement and AutoCarry.CanMove then
		local moveDist = 480 + (GetLatency()/10)
		if not range then
			if isMelee and AutoCarry.Orbwalker.target and AutoCarry.Orbwalker.target.type == myHero.type and GetDistance(AutoCarry.Orbwalker.target) < 80 then 
				attackEnemy(AutoCarry.Orbwalker.target)
				return
			elseif GetDistance(mousePos) < moveDist and GetDistance(mousePos) > 100 then 
				moveDist = GetDistance(mousePos) 
			end
		end
		local moveSqr = math.sqrt((mousePos.x - myHero.x)^2+(mousePos.z - myHero.z)^2)
		local moveX = myHero.x + (range and range or moveDist)*((mousePos.x - myHero.x)/moveSqr)
		local moveZ = myHero.z + (range and range or moveDist)*((mousePos.z - myHero.z)/moveSqr)
		if StreamingMenu.MinRand > StreamingMenu.MaxRand then
			PrintChat("You must set Max higher than Min in streaming menu")
		elseif StreamingMenu.ShowClick and GetTickCount() > nextClick then
			if StreamingMenu.Colour == 0 then
				ShowGreenClick(mousePos)
			else
				ShowRedClick(mousePos)
			end
			nextClick = GetTickCount() + math.random(StreamingMenu.MinRand, StreamingMenu.MaxRand)
		end
		myHero:MoveTo(moveX, moveZ)
	end
end
 
--[[ Orbwalking ]]--
 
function OrbwalkingOnLoad()
	AutoCarry.Orbwalker = TargetSelector(TARGET_LOW_HP_PRIORITY, getTrueRange(), DAMAGE_PHYSICAL, false)
	AutoCarry.Orbwalker:SetBBoxMode(true)
	AutoCarry.Orbwalker:SetDamages(0, myHero.totalDamage, 0)
	AutoCarry.Orbwalker.name = "AutoCarry"
	lastRange = getTrueRange()
	if ChampInfo ~= nil then
         if ChampInfo.projSpeed ~= nil then
             projSpeed = ChampInfo.projSpeed
         end
    end
end
 
function OrbwalkingOnTick()
	AutoCarry.Orbwalker.targetSelected = AutoCarry.MainMenu.Focused
	if GetTickCount() + GetLatency()/2 > lastAttack + previousWindUp + 20 and GetTickCount() + GetLatency()/2 < lastAttack + previousWindUp + 400 then attackedSuccessfully() end
	isMelee = myHero.range < 300
	if myHero.range ~= lastRange then
			AutoCarry.Orbwalker.range = myHero.range
			lastRange = myHero.range
	end
	AutoCarry.Orbwalker:update()
end
 
function OrbwalkingOnProcessSpell(unit, spell)
	if myHero.dead then return end
	
	if unit.isMe and (spell.name:lower():find("attack") or isSpellAttack(spell.name)) and not isNotAttack(spell.name) then
		lastAttack = GetTickCount() - GetLatency()/2
		previousWindUp = spell.windUpTime*1000
		previousAttackCooldown = spell.animationTime*1000
	elseif unit.isMe and refreshAttack(spell.name) then
		lastAttack = GetTickCount() - GetLatency()/2 - previousAttackCooldown
	end
end

function refreshAttack(spellName)
    return (
		--Blitzcrank
		spellName == "PowerFist"
		--Darius
		or spellName == "DariusNoxianTacticsONH"
		--Nidalee
		or spellName == "Takedown"
		--Sivir
		or spellName == "Ricochet"
		--Teemo
		or spellName == "BlindingDart"
		--Vayne
		or spellName == "VayneTumble"
		--Jax
		or spellName == "JaxEmpowerTwo"
		--Mordekaiser
		or spellName == "MordekaiserMaceOfSpades"
		--Nasus
		or spellName == "SiphoningStrikeNew"
		--Rengar
		or spellName == "RengarQ"
		--Wukong
		or spellName == "MonkeyKingDoubleAttack"
		--Yorick
		or spellName == "YorickSpectral"
		--Vi
		or spellName == "ViE"
		--Garen
		or spellName == "GarenSlash3"
		--Hecarim
		or spellName == "HecarimRamp"
		--XinZhao
		or spellName == "XenZhaoComboTarget"
		--Leona
		or spellName == "LeonaShieldOfDaybreak"
		--Shyvana
		or spellName == "ShyvanaDoubleAttack"
		or spellName == "shyvanadoubleattackdragon"
		--Talon
		or spellName == "TalonNoxianDiplomacy"
		--Trundle
		or spellName == "TrundleTrollSmash"
		--Volibear
		or spellName == "VolibearQ"
		--Poppy
		or spellName == "PoppyDevastatingBlow"
    )
end

function isSpellAttack(spellName)
	return (
		--Ashe
		spellName == "frostarrow"
		--Caitlyn
		or spellName == "CaitlynHeadshotMissile"
		--Kennen
		or spellName == "KennenMegaProc"
		--Quinn
		or spellName == "QuinnWEnhanced"
		--Trundle
		or spellName == "TrundleQ"
		--XinZhao
		or spellName == "XenZhaoThrust"
		or spellName == "XenZhaoThrust2"
		or spellName == "XenZhaoThrust3"
		--Garen
		or spellName == "GarenSlash2"
		--Renekton
		or spellName == "RenektonExecute"
		or spellName == "RenektonSuperExecute"
		--Yi
		or spellName == "MasterYiDoubleStrike"
    )
end
function isNotAttack(spellName)
	return (
		--Shyvana
		spellName == "shyvanadoubleattackdragon"
		or spellName == "ShyvanaDoubleAttack"
		--MonkeyKing
		or spellName == "MonkeyKingDoubleAttack"
		--JarvanIV
		--or spellName == "JarvanIVCataclysmAttack"
		--or spellName == "jarvanivcataclysmattack"
    )
end
 
function OrbwalkingOnDraw()
        if DisplayMenu.target and AutoCarry.Orbwalker.target ~= nil then
                for j=0, 5 do
                        DrawCircle(AutoCarry.Orbwalker.target.x, AutoCarry.Orbwalker.target.y, AutoCarry.Orbwalker.target.z, 100 + j, 0x00FF00)
                end
                DrawCircle(AutoCarry.Orbwalker.target.x, AutoCarry.Orbwalker.target.y, AutoCarry.Orbwalker.target.z, GetDistance(AutoCarry.Orbwalker.target, AutoCarry.Orbwalker.target.minBBox), 0xFFFFFF)
        elseif DisplayMenu.target and AutoCarry.SkillsCrosshair.target then
                for j=0, 5 do
                        DrawCircle(AutoCarry.SkillsCrosshair.target.x, AutoCarry.SkillsCrosshair.target.y, AutoCarry.SkillsCrosshair.target.z, 100 + j, 0x990000)
                end
                DrawCircle(AutoCarry.SkillsCrosshair.target.x, AutoCarry.SkillsCrosshair.target.y, AutoCarry.SkillsCrosshair.target.z, GetDistance(AutoCarry.SkillsCrosshair.target, AutoCarry.SkillsCrosshair.target.minBBox), 0xFFFFFF)
        end
end
 
function EnemyInRange(enemy)
        if ValidBBoxTarget(enemy, getTrueRange()) then
                return true
        end
    return false
end
 
--[[ Last Hitting ]]--
 
function LastHitOnLoad()
	minionInfo[(myHero.team == 100 and "Blue" or "Red").."_Minion_Basic"] =      { aaDelay = 400, projSpeed = 0    }
	minionInfo[(myHero.team == 100 and "Blue" or "Red").."_Minion_Caster"] =     { aaDelay = 484, projSpeed = 0.68 }
	minionInfo[(myHero.team == 100 and "Blue" or "Red").."_Minion_Wizard"] =     { aaDelay = 484, projSpeed = 0.68 }
	minionInfo[(myHero.team == 100 and "Blue" or "Red").."_Minion_MechCannon"] = { aaDelay = 365, projSpeed = 1.18 }
	minionInfo.obj_AI_Turret =                                         { aaDelay = 150, projSpeed = 1.14 }
   
	for i = 0, objManager.maxObjects do
		local obj = objManager:getObject(i)
		for _, mob in pairs(getJungleMobs()) do
			if obj and obj.valid and obj.name:find(mob) then
				table.insert(jungleMobs, obj)
			end
		end
	end
end
 
function LastHitOnTick()
	if AutoCarry.MainMenu.LastHit or AutoCarry.MainMenu.MixedMode or AutoCarry.MainMenu.LaneClear then
		enemyMinions:update()
		allyMinions:update()
	end
end
 
function LastHitOnProcessSpell(object, spell)
	if not isMelee and isAllyMinionInRange(object) then
        for i,minion in pairs(enemyMinions.objects) do
            if ValidTarget(minion) and minion ~= nil and GetDistance(minion, spell.endPos) < 3 then
                if object ~= nil and (minionInfo[object.charName] or object.type == "obj_AI_turret") then
					incomingDamage[object.name] = getNewAttackDetails(object, minion)
                end
				--if object.type == "obj_AI_Turret" and object.team == myHero.team then
					--if FarmMenu.Predict then
							--handleTurretShot(object, minion)
					--end
				--end
            end
        end
    end
end
 
function LastHitOnCreateObj(obj)
	for _, mob in pairs(getJungleMobs()) do
		if obj.name:find(mob) then
			table.insert(jungleMobs, obj)
		end
	end
end
 
function LastHitOnDeleteObj(obj)
	for i, mob in pairs(getJungleMobs()) do
		if obj and obj.valid and mob and mob.valid and obj.name:find(mob.name) then
			table.remove(jungleMobs, i)
		end
	end
end
 
function getJungleMinion()
	for _, mob in pairs(jungleMobs) do
		if ValidTarget(mob) and GetDistance(mob) <= getTrueRange() then return mob end
	end
	return nil
end
 
function LastHitOnDraw()
	if DisplayMenu.minion and enemyMinions.objects[1] and ValidTarget(enemyMinions.objects[1]) and not isMelee then
		DrawCircle(enemyMinions.objects[1].x, enemyMinions.objects[1].y, enemyMinions.objects[1].z, 100, 0x19A712)
	end
end
 
function getTimeToHit(enemy, speed)
	return (( GetDistance(enemy) / speed ) + GetLatency()/2)
end
 
function isAllyMinionInRange(minion)
	if minion ~= nil and minion.team == myHero.team
		and (minion.type == "obj_AI_Minion" or minion.type == "obj_AI_Turret")
		and GetDistance(minion) <= 2000 then return true
	else return false end
end
 
function getMinionDelay(minion)
	return ( minion.type == "obj_AI_Turret" and minionInfo.obj_AI_Turret.aaDelay or minionInfo[minion.charName].aaDelay )
end
 
function getMinionProjSpeed(minion)
	return ( minion.type == "obj_AI_Turret" and minionInfo.obj_AI_Turret.projSpeed or minionInfo[minion.charName].projSpeed )
end
 
function minionSpellStillViable(attack)
	if attack == nil then return false end
	local sourceMinion = getAllyMinion(attack.sourceName)
	local targetMinion = getEnemyMinion(attack.targetName)
	if sourceMinion == nil or targetMinion == nil then return false end
	if sourceMinion.dead or targetMinion.dead or GetDistance(sourceMinion, attack.origin) > 3 then return false else return true end
end
 
function getAllyMinion(name)
	for i, minion in pairs(allyMinions.objects) do
		if minion ~= nil and minion.valid and minion.name == name then
			return minion
		end
	end
	return nil
end
 
function getEnemyMinion(name)
	for i, minion in pairs(enemyMinions.objects) do
		if minion ~= nil and ValidTarget(minion) and minion.name == name then
			return minion
		end
	end
	return nil
end
 
function isSameMinion(minion1, minion2)
	if minion1.networkID == minion2.networkID then return true
	else return false end
end
 
function getMinionTimeToHit(minion, attack)
	local sourceMinion = getAllyMinion(attack.sourceName)
	return ( attack.speed == 0 and ( attack.delay ) or ( attack.delay + GetDistance(sourceMinion, minion) / attack.speed ) )
end
 
function getNewAttackDetails(source, target)
	return  {
			sourceName = source.name,
			targetName = target.name,
			damage = source:CalcDamage(target),
			started = GetTickCount(),
			origin = { x = source.x, z = source.z },
			delay = getMinionDelay(source),
			speed = getMinionProjSpeed(source),
			sourceType = source.type}
end
	
function getPredictedDamage(counter, minion, attack)
	if not minionSpellStillViable(attack) then
		incomingDamage[counter] = nil
	elseif isSameMinion(minion, getEnemyMinion(attack.targetName)) then
		local myTimeToHit = getTimeToHit(minion, projSpeed)
		minionTimeToHit = getMinionTimeToHit(minion, attack)
		if GetTickCount() >= (attack.started + minionTimeToHit) then
			incomingDamage[counter] = nil
		elseif GetTickCount() + myTimeToHit > attack.started + minionTimeToHit then
			return attack.damage
		end
	end
	return 0
end
 
function getKillableCreep(iteration)
	if isMelee then return meleeLastHit() end
	local minion = enemyMinions.objects[iteration]
	if minion ~= nil then
		local distanceToMinion = GetDistance(minion)
		local predictedDamage = 0
		if distanceToMinion < getTrueRange() then
			if FarmMenu.Predict then
				for l, attack in pairs(incomingDamage) do
					predictedDamage = predictedDamage + getPredictedDamage(l, minion, attack)
				end
			end
			local myDamage = myHero:CalcDamage(minion, myHero.totalDamage) + getBonusLastHitDamage(minion) + LastHitPassiveDamage()
			myDamage = (MasteryMenu.Executioner and myDamage * 1.05 or myDamage)
			myDamage = myDamage - 10
			--if minion.health - predictedDamage <= 0 then
					--return getKillableCreep(iteration + 1)
			if minion.health + 1.2 - predictedDamage < myDamage then
					return minion
			--elseif minion.health + 1.2 - predictedDamage < myDamage + (0.5 * predictedDamage) then
			--		return nil
			end
		end
	end
	return nil
end

function getBonusLastHitDamage(minion)
	if PluginBonusLastHitDamage then 
		return PluginBonusLastHitDamage(minion)
	elseif BonusLastHitDamage then
		return BonusLastHitDamage(minion)
	else
		return 0
	end
end
 
function meleeLastHit()
        for _, minion in pairs(enemyMinions.objects) do
                local aDmg = getDmg("AD", minion, myHero)
                if GetDistance(minion) <= (myHero.range + 75) then
                        if minion.health < aDmg then
                                return minion
                        end            
                end
        end
end
 
function LastHitPassiveDamage(minion)
		if PluginLastHitPassiveDamage then return PluginLastHitPassiveDamage(minion) end
        local bonus = 0
        if GetInventoryHaveItem(3153) then
                if ValidTarget(minion) then
                        bonus = minion.health / 20
                        if bonus >= 60 then
                                bonus = 60
                        end
                end
        end
        bonus = bonus + (MasteryMenu.Butcher * 2)
        bonus = (MasteryMenu.Spellblade and bonus + (myHero.ap * 0.05) or 0)
        return bonus
end
 
function getHighestMinion()
	if GetTarget() ~= nil then
		local currentTarget = GetTarget()
		local validTarget = false
		validTarget = ValidTarget(currentTarget, getTrueRange(), player.enemyTeam)
		if validTarget and (currentTarget.type == "obj_BarracksDampener" or currentTarget.type == "obj_HQ" or currentTarget.type == "obj_AI_Turret") then
			return currentTarget
		end
	end

	local highestHp = {obj = nil, hp = 0}
	for _, tMinion in pairs(enemyMinions.objects) do
		if GetDistance(tMinion) <= getTrueRange() and tMinion.health > highestHp.hp then
				highestHp = {obj = tMinion, hp = tMinion.health}
		end
	end
	return highestHp.obj
end
 
function getPredictedDamageOnMinion(minion)
        local predictedDamage = 0
        if minion ~= nil then
                local distanceToMinion = GetDistance(minion)
                if distanceToMinion < getTrueRange() then
                        for l, attack in pairs(incomingDamage) do
                                if attack.sourceType ~= "obj_AI_Turret" then
                                        predictedDamage = predictedDamage + getPredictedDamage(l, minion, attack)
                                end
                        end
                end
        end
        return predictedDamage
end
 
function handleTurretShot(turret, minion)
        local dmg = turret:CalcDamage(minion)
        local myDmg = myHero:CalcDamage(minion, myHero.totalDamage) + (BonusLastHitDamage and BonusLastHitDamage(minion) or 0) + LastHitPassiveDamage()
        myDmg = (MasteryMenu.Executioner and myDmg * 1.05 or myDmg)
        local predic = getPredictedDamageOnMinion(minion)
        if minion.health > myDmg + dmg + predic and minion.health < (myDmg * 2) + dmg + predic then
                turretMinion = {timeToHit = minionInfo.obj_AI_Turret.aaDelay + GetDistance(turret, minion) / minionInfo.obj_AI_Turret.projSpeed, obj = minion }
        end
end
 
--[[ Abilities ]]--
function SkillsOnLoad()
        Skills = getSpellList()
        if Skills == nil then
                AutoCarry.SkillsCrosshair = TargetSelector(TARGET_LOW_HP_PRIORITY, 0, DAMAGE_PHYSICAL, false)
                return
        end
        local maxRange = 0
        for _, skill in pairs(Skills) do
                if skill.range > maxRange then maxRange = skill.range end
        end
        AutoCarry.SkillsCrosshair = TargetSelector(TARGET_LOW_HP_PRIORITY, maxRange, DAMAGE_PHYSICAL, false)
end
 
function SkillsOnTick()
        if Skills == nil then return end
        local target = AutoCarry.GetAttackTarget()
        if ValidTarget(target) and target.type == myHero.type then
                for _, skill in pairs(Skills) do
                if  (AutoCarry.MainMenu.AutoCarry and SkillsMenu[skill.configName.."AutoCarry"]) or
                        (AutoCarry.MainMenu.MixedMode and SkillsMenu[skill.configName.."MixedMode"]) then
                                if not skill.reset or (skill.reset and GetTickCount() < projAt + 400) then
                                        if skill.skillShot then
                                                AutoCarry.CastSkillshot(skill, target)
                                        elseif skill.reqTarget == false and not skill.atMouse then
                                                CastSelf(skill, target)
                                        elseif skill.reqTarget == false and skill.atMouse then
                                                CastMouse(skill)
                                        else
                                                CastTargettedSpell(skill, target)
                                        end
                                end
                        end
                end
        end
end
 
AutoCarry.GetCollision = function (skill, source, destination)
	if VIP_USER and useVIPCol then
		local col = Collision(skill.range, skill.speed*1000, skill.delay/1000, skill.width)
		return col:GetMinionCollision(source, destination)
	else
		return willHitMinion(destination, skill.width)
	end
end
 
AutoCarry.CastSkillshot = function (skill, target)
	if VIP_USER then
		pred = TargetPredictionVIP(skill.range, skill.speed*1000, skill.delay/1000, skill.width)
	elseif not VIP_USER then
		pred = TargetPrediction(skill.range, skill.speed, skill.delay, skill.width)
	end
	local predPos = pred:GetPrediction(target)
	if predPos and GetDistance(predPos) <= skill.range then
		if VIP_USER and pred:GetHitChance(target) > SkillsMenu.hitChance/100 then
			if not skill.minions or not AutoCarry.GetCollision(skill, myHero, predPos) then
				CastSpell(skill.spellKey, predPos.x, predPos.z)
			end
		elseif not VIP_USER then
			if not skill.minions or not AutoCarry.GetCollision(skill, myHero, predPos) then
				CastSpell(skill.spellKey, predPos.x, predPos.z)
			end
		end
	end
end

AutoCarry.GetPrediction = function(skill, target)
	if VIP_USER then
		pred = TargetPredictionVIP(skill.range, skill.speed*1000, skill.delay/1000, skill.width)
	elseif not VIP_USER then
		pred = TargetPrediction(skill.range, skill.speed, skill.delay, skill.width)
	end
	return pred:GetPrediction(target)
end

AutoCarry.IsValidHitChance = function(skill, target)
	if VIP_USER then
		pred = TargetPredictionVIP(skill.range, skill.speed*1000, skill.delay/1000, skill.width)
		return pred:GetHitChance(target) > SkillsMenu.hitChance/100 and true or false
	elseif not VIP_USER then
		return true
	end
end

AutoCarry.GetNextAttackTime = function()
	return (lastAttack + previousAttackCooldown) - GetLatency()/2
end
 
function CastTargettedSpell(skill, target)
        if GetDistance(target) <= skill.range then
                CastSpell(skill.spellKey, target)
        end
end
 
function CastMouse(skill)
        CastSpell(skill.spellKey, mousePos.x, mousePos.z)
end
 
function CastSelf(skill, target)
        if not skill.forceRange or (skill.forceRange and GetDistance(target) - (skill.forceToHitBox and GetDistance(target, target.minBBox) or 0) <= skill.range) then
                CastSpell(skill.spellKey)
        end
end
 
function getPrediction(speed, delay, target)
        if target == nil then return nil end
        local travelDuration = (delay + GetDistance(myHero, target)/speed)
        travelDuration = (delay + GetDistance(GetPredictionPos(target, travelDuration))/speed)
        travelDuration = (delay + GetDistance(GetPredictionPos(target, travelDuration))/speed)
        travelDuration = (delay + GetDistance(GetPredictionPos(target, travelDuration))/speed)  
        return GetPredictionPos(target, travelDuration)
end
 
function willHitMinion(predic, width)
	for _, minion in pairs(enemyMinions.objects) do
		if minion ~= nil and minion.valid and string.find(minion.name,"Minion_") == 1 and minion.team ~= player.team and minion.dead == false then
			if predic ~= nil then
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
				mx = minion.x
				mz = minion.z
				distanc = (math.abs(mz - m*mx - c))/(math.sqrt(m*m+1))
				if distanc < width and math.sqrt((tx - ex)*(tx - ex) + (tz - ez)*(tz - ez)) > math.sqrt((tx - mx)*(tx - mx) + (tz - mz)*(tz - mz)) then
					return true
				end
			end
		end
	end
	return false
end
 
--[[ Champion Specific ]]--
 
function LoadCustomChampionSupport()
			-- >> Vayne << --
	if myHero.charName == "Vayne" then
			function BonusLastHitDamage()
					if myHero:GetSpellData(_Q).level > 0 and myHero:CanUseSpell(_Q) == SUPRESSED then
				return math.round( ((0.05*myHero:GetSpellData(_Q).level) + 0.25 )*myHero.totalDamage )
			end
					return 0
			end
		   
			-- >> Teemo << --
	elseif myHero.charName == "Teemo" then
			function BonusLastHitDamage()
					if myHero:GetSpellData(_E).level > 0 then
				return math.floor( (myHero:GetSpellData(_E).level * 10) + (myHero.ap * 0.3) )
			end
					return 0
			end    
			-- >> Corki << --
	elseif myHero.charName == "Corki" then
			function BonusLastHitDamage()
					return myHero.totalDamage/10
			end
			 
			-- >> Miss Fortune << --
	elseif myHero.charName == "MissFortune" then
			function BonusLastHitDamage()
					if myHero:GetSpellData(_W).level > 0 then
							return (4+2*myHero:GetSpellData(_W).level) + (myHero.ap/20)
					end
					return 0
			end
		   
			-- >> Varus << --
	elseif myHero.charName == "Varus" then
			function BonusLastHitDamage()
					if myHero:GetSpellData(_W).level > 0 then
							return (6 + (myHero:GetSpellData(_W).level * 4) + (myHero.ap * 0.25))
					end
					return 0
			end
	 
			-- >> Caitlyn << --
	elseif myHero.charName == "Caitlyn" then
			local headShotPart
			function CustomOnCreateObj(obj)
					if GetDistance(obj) < 100 and obj.name:lower():find("caitlyn_headshot_rdy") then
							headShotPart = obj
					end
			end
		   
			function BonusLastHitDamage(minion)
					if headShotPart and headShotPart.valid and minion and ValidTarget(minion) then
							return myHero:CalcDamage(minion, myHero.totalDamage) * 1.5
					end
					return 0
			end
	 
			-- >> Tristana << --
	elseif myHero.charName == "Tristana" then
			function CustomOnTick()
					Skills[2].range = myHero.range
			end
		   
			-- >> KogMaw << --
	elseif myHero.charName == "KogMaw" then
			function CustomOnTick()
					Skills[2].range = getTrueRange() + 110 + (myHero:GetSpellData(_W).level * 20)
					if myHero:GetSpellData(_R).level == 1 then
							Skills[4].range = 1400
					elseif myHero:GetSpellData(_R).level == 2 then
							Skills[4].range = 1700
					elseif myHero:GetSpellData(_R).level == 3 then
							Skills[4].range = 2200
					end
			end
		   
			-- >> Twisted Fate << --
	elseif myHero.charName == "TwistedFate" then
			local tfLastUse = 0
			TFConfig = scriptConfig("Sida's Auto Carry: Twisted Fate Edition", "autocarrytf")
			TFConfig:addParam("selectgold", "Select Gold", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("W"))
			TFConfig:addParam("selectblue", "Select Blue", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("E"))
			TFConfig:addParam("selectred", "Select Red", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("V"))
			TFConfig:addParam("qStunned", "Auto Q Stunned Enemies", SCRIPT_PARAM_ONOFF, true)
		   
			function CustomOnTick()
					PickACard()
					if TFConfig.qStunned then
							for _, enemy in pairs(AutoCarry.EnemyTable) do
									if ValidTarget(enemy) and not enemy.canMove and GetDistance(enemy) < 1350 then
											CastSpell(_Q, enemy.x, enemy.z)
									end
							end
					end
			end
		   
			function PickACard()
					if myHero:CanUseSpell(_W) == READY and GetTickCount()-tfLastUse <= 2300 then
							if myHero:GetSpellData(_W).name == selected then CastSpellEx(_W) end
					end
					if myHero:CanUseSpell(_W) == READY and GetTickCount()-tfLastUse >= 2400 then
							if TFConfig.selectgold then selected = "goldcardlock"
							elseif TFConfig.selectblue then selected = "bluecardlock"
							elseif TFConfig.selectred then selected = "redcardlock"
							else return end
							CastSpellEx(_W)
							tfLastUse = GetTickCount()
					end
			end
	 
			-- >> Draven << --
	elseif myHero.charName == "Draven" then
			local reticles = {}
			local qStacks = 0
			local closestReticle
			local qBuff = 0
			local stopped = false
			local qRad = 150
			disableRangeDraw = true
			local qParticles = {"Draven_Q_mis",
											"Draven_Q_mis_bloodless",
											"Draven_Q_mis_shadow",
											"Draven_Q_mis_shadow_bloodless",
											"Draven_Qcrit_mis",
											"Draven_Qcrit_mis_bloodless",
											"Draven_Qcrit_mis_shadow",
											"Draven_Qcrit_mis_shadow_bloodless" }
										   
			DravenConfig = scriptConfig("Sida's Auto Carry: Draven Edition", "autocarrdraven")
			DravenConfig:addParam("HoldRange", "Stand Zone", SCRIPT_PARAM_SLICE, 130, 0, 450, 0)
			DravenConfig:addParam("CatchRange", "Catch Axe Range", SCRIPT_PARAM_SLICE, 575, 0, 2000, 0)
			DravenConfig:addParam("AutoW", "Keep W Buff Active Against Enemy", SCRIPT_PARAM_ONOFF, true)
			DravenConfig:addParam("AutoCarry", "Use / Catch Axes: Auto Carry Mode", SCRIPT_PARAM_ONOFF, true)
			DravenConfig:addParam("LastHit", "Use / Catch Axes: Last Hit Mode", SCRIPT_PARAM_ONOFF, true)
			DravenConfig:addParam("LaneClear", "Use / Catch Axes: Lane Clear Mode", SCRIPT_PARAM_ONOFF, true)
			DravenConfig:addParam("MixedMode", "Use / Catch Axes: Mixed Mode Mode", SCRIPT_PARAM_ONOFF, true)
			DravenConfig:addParam("Reminder", "Display Reminder Text", SCRIPT_PARAM_ONOFF, true)
		   
			function Move(pos)
					local moveSqr = math.sqrt((pos.x - myHero.x)^2+(pos.z - myHero.z)^2)
					local moveX = myHero.x + 200*((pos.x - myHero.x)/moveSqr)
					local moveZ = myHero.z + 200*((pos.z - myHero.z)/moveSqr)
					myHero:MoveTo(moveX, moveZ)
			end
		   
			function CustomOnProcessSpell(unit, spell)
					if unit.isMe and spell.name == "dravenspinning" then
							qStacks = qStacks + 1
					end
			end
										   
			function CustomOnCreateObj(obj)
					if obj.name == "Draven_Q_buf.troy" then
							qBuff = qBuff + 1
					end
		   
					for _, particle in pairs(qParticles) do
							 if obj ~= nil and obj.valid and obj.name:lower():find(particle:lower()) and GetDistance(obj) < 333 then
									attackedSuccessfully()
							 end
					end
				   
					if obj ~= nil and obj.name ~= nil and obj.x ~= nil and obj.z ~= nil then
				if obj.name == "Draven_Q_reticle_self.troy" then
					table.insert(reticles, {object = obj, created = GetTickCount()})
				elseif obj.name == "draven_spinning_buff_end_sound.troy" then
					qStacks = 0
				end
			end
			end
		   
			function CustomOnDeleteObj(obj)
					if obj.name == "Draven_Q_reticle_self.troy" then
							if GetDistance(obj) > qRad then
									qStacks = qStacks - 1
							end
							for i, reticle in ipairs(reticles) do
									if obj and obj.valid and reticle.object and reticle.object.valid and obj.x == reticle.object.x and obj.z == reticle.object.z then
											table.remove(reticles, i)
									end
							end
					elseif obj.name == "Draven_Q_buf.troy" then
							qBuff = qBuff - 1                      
					end
			end
		   
			function axesActive()
					if (AutoCarry.MainMenu.AutoCarry and DravenConfig.AutoCarry)
					or (AutoCarry.MainMenu.LastHit and DravenConfig.LastHit)
					or (AutoCarry.MainMenu.MixedMode and DravenConfig.MixedMode)
					or (AutoCarry.MainMenu.LaneClear and DravenConfig.LaneClear) then
							return true
					end
					return false
			end
		   
			function CustomAttackEnemy(enemy)
					if enemy.dead or not enemy.valid or disableAttacks then return end
					if axesActive() and GetDistance(mousePos) <= DravenConfig.CatchRange then
							if qStacks < 2 then CastSpell(_Q) end
					end
					myHero:Attack(enemy)
					AutoCarry.shotFired = true
			end
		   
			function CustomOnTick()
					if myHero.dead then return end
					if (AutoCarry.MainMenu.AutoCarry or AutoCarry.MainMenu.MixedMode) and DravenConfig.AutoW and ValidTarget(AutoCarry.Orbwalker.target) and not TargetHaveBuff("dravenfurybuff" , myHero) then
							CastSpell(_W)
					end
				   
					for _, particle in pairs(reticles) do
							if closestReticle and closestReticle.object.valid and particle.object and particle.object.valid then
									if GetDistance(particle.object) > GetDistance(closestReticle.object) then
											closestReticle = particle
									end
							else
									closestReticle = particle
							end
					end    
	 
					if GetDistance(mousePos) <= DravenConfig.HoldRange and axesActive() then
							if not stopped then
									myHero:HoldPosition()
									stopped = true
							end
							disableMovement = true
					else
							stopped = false
					end
				   
					function doMovement()
							disableMovement = true
							disableAttacks = true
							if myHero.canMove then Move({x = closestReticle.object.x, z = closestReticle.object.z}) end
					end
				   
					if axesActive() and closestReticle and closestReticle.object and closestReticle.object.valid then
							if GetDistance(mousePos) <= DravenConfig.CatchRange and ((AutoCarry.MainMenu.AutoCarry and ShouldCatch(closestReticle.object)) or (not AutoCarry.MainMenu.AutoCarry)) then
									if GetDistance(closestReticle.object) > qRad then
											doMovement()
									else
											disableMovement = true
											disableAttacks = false
									end
							else
									disableMovement = false
									disableAttacks = false
							end
					elseif GetDistance(mousePos) <= DravenConfig.HoldRange then
							disableMovement = true
							disableAttacks = false
					else
							disableMovement = false
							disableAttacks = false
					end
			end
				   
			function ShouldCatch(reticle)
					local enemy
					if AutoCarry.Orbwalker.target ~= nil then enemy = AutoCarry.Orbwalker.target
					elseif AutoCarry.SkillsCrosshair.target ~= nil then enemy = AutoCarry.SkillsCrosshair.target
					else return true end
					if not reticle then return false end
					if GetDistance(mousePos, enemy) > GetDistance(enemy) then
							if GetDistance(reticle, enemy) < GetDistance(enemy) then
									return false
							end
							return true
					else
							local closestEnemy
							for _, thisEnemy in pairs(AutoCarry.EnemyTable) do
									if not closestEnemy then closestEnemy = thisEnemy
									elseif GetDistance(thisEnemy) < GetDistance(closestEnemy) then closestEnemy = thisEnemy end
							end
							if closestEnemy then
									local predPos = getPrediction(1.9, 100, closestEnemy)
									if not predPos then return true end
									if GetDistance(reticle, predPos) > getTrueRange() + getHitBoxRadius(closestEnemy) then
											return false
									end
									return true
							else
									return true
							end
					end
			end
		   
			function BonusLastHitDamage(minion)
					if myHero:GetSpellData(_Q).level > 0 and qBuff > 0 then
						return ((myHero.damage + myHero.addDamage) * (0.35 + (0.1 * myHero:GetSpellData(_Q).level)))
					end
					return 0
			end
		   
			function CustomOnDraw()
					DrawCircle(myHero.x, myHero.y, myHero.z, DravenConfig.HoldRange, 0xFFFFFF)
					DrawCircle(myHero.x, myHero.y, myHero.z, DravenConfig.HoldRange-1, 0xFFFFFF)
					DrawCircle(myHero.x, myHero.y, myHero.z, DravenConfig.CatchRange-1, 0x19A712)
				   
					if axesActive() and DravenConfig.Reminder then
							if GetDistance(mousePos) <= DravenConfig.HoldRange then
									DrawText("Holding Position & Catching",16,100, 100, 0xFF00FF00)
							elseif GetDistance(mousePos) <= DravenConfig.CatchRange then
									DrawText("Orbwalking & Catching",16,100, 100, 0xFF00FF00)
							else
									DrawText("Only Orbwalking",16,100, 100, 0xFF00FF00)
							end
					end
			end
	 
	end
end 
--[[ Items ]]--
local items =
	{
		{name = "Blade of the Ruined King", menu = "BRK", id=3153, range = 450, reqTarget = true, slot = nil },
		{name = "Bilgewater Cutlass", menu = "BWC", id=3144, range = 450, reqTarget = true, slot = nil },
		{name = "Deathfire Grasp", menu = "DFG", id=3128, range = 750, reqTarget = true, slot = nil },
		{name = "Hextech Gunblade", menu = "HGB", id=3146, range = 400, reqTarget = true, slot = nil },
		{name = "Ravenous Hydra", menu = "RSH", id=3074, range = 350, reqTarget = false, slot = nil},
		{name = "Sword of the Divine", menu = "STD", id=3131, range = 350, reqTarget = false, slot = nil},
		{name = "Tiamat", menu = "TMT", id=3077, range = 350, reqTarget = false, slot = nil},
		{name = "Entropy", menu = "ETR", id=3184, range = 350, reqTarget = false, slot = nil},
		{name = "Youmuu's Ghostblade", menu = "YGB", id=3142, range = 350, reqTarget = false, slot = nil}
	}
       
function UseItemsOnTick()
	if AutoCarry.Orbwalker.target then
		for _,item in pairs(items) do
			item.slot = GetInventorySlotItem(item.id)
			if item.slot ~= nil then
				if item.reqTarget and GetDistance(AutoCarry.Orbwalker.target) <= item.range and item.menu ~= "BRK" then
					CastSpell(item.slot, AutoCarry.Orbwalker.target)
				elseif item.reqTarget and GetDistance(AutoCarry.Orbwalker.target) <= item.range and item.menu == "BRK" then
					if myHero.health <= myHero.maxHealth*0.65 or GetDistance(AutoCarry.Orbwalker.target) > 400 then
						CastSpell(item.slot, AutoCarry.Orbwalker.target)
					end
				elseif not item.reqTarget then
					CastSpell(item.slot)
				end
			end
		end
	end
end
 
function SetMuramana()
	if AutoCarry.Orbwalker.target ~= nil and ItemMenu.muraMana and not MuramanaIsActive() and (AutoCarry.MainMenu.AutoCarry or AutoCarry.MainMenu.MixedMode) then
		MuramanaOn()
	elseif AutoCarry.Orbwalker.target == nil and ItemMenu.muraMana and MuramanaIsActive() then
		MuramanaOff()
	end
end
 
--[[ Summoner Spells ]]--
 local ignite, barrier, healthBefore, healthBeforeTimer, nextUpdate, nextCheck = nil, nil, 0, 0, 0, 0, 0
 
 function SummonerOnLoad()
         ignite = (player:GetSpellData(SUMMONER_1).name == "SummonerDot" and SUMMONER_1 or (player:GetSpellData(SUMMONER_2).name == "SummonerDot" and SUMMONER_2 or nil))
         barrier = (player:GetSpellData(SUMMONER_1).name == "SummonerBarrier" and SUMMONER_1 or (player:GetSpellData(SUMMONER_2).name == "SummonerBarrier" and SUMMONER_2 or nil))
 end
 
function SummonerOnTick()
        if ignite and SummonerMenu.Ignite and myHero:CanUseSpell(ignite) == READY then
                for _, enemy in pairs(GetEnemyHeroes()) do
                        if ValidTarget(enemy, 600) and enemy.health <= 50 + (20 * player.level) then
                                CastSpell(ignite, enemy)
                        end
                end
        end
        if barrier and SummonerMenu.Barrier and myHero:CanUseSpell(barrier) == READY then
                if GetTickCount() >= nextCheck then
                        local co = ((myHero.health / myHero.maxHealth * 100) - 20)*(0.3-0.1)/(100-20)+0.1
                        local proc = myHero.maxHealth * co
                        if healthBefore - myHero.health > proc and myHero.health < myHero.maxHealth * 0.3 then
                                CastSpell(barrier)
                        end
                        nextCheck = GetTickCount() + 100
                        if GetTickCount() >= nextUpdate then
                                healthBefore = myHero.health
                                healthBeforeTimer = GetTickCount()
                                nextUpdate = GetTickCount() + 1000
                        end
                end
        end
end
 
--[[ Plugins ]]--
if FileExist(LIB_PATH .."SidasAutoCarryPlugin - "..myHero.charName..".lua") then
        hasPlugin = true
end

AutoCarry.GetAttackTarget = function(isCaster)
	if not isCaster and ValidTarget(AutoCarry.Orbwalker.target) then
		return AutoCarry.Orbwalker.target
	else
		AutoCarry.SkillsCrosshair:update()
		return AutoCarry.SkillsCrosshair.target
	end
end

AutoCarry.GetKillableMinion = function()
	return killableMinion
end

AutoCarry.GetMinionTarget = function()
	if killableMinion then
		return killableMinion
	elseif pluginMinion then
		return pluginMinion
	else
		return nil
	end
end

AutoCarry.EnemyMinions = function()
	return enemyMinions
end

AutoCarry.AllyMinions = function()
	return allyMinions
end

AutoCarry.GetJungleMobs = function()
	return jungleMobs
end

AutoCarry.GetLastAttacked = function()
	return lastAttacked
end

function OnApplyParticle(Unit, Particle)
	if PluginOnApplyParticle then PluginOnApplyParticle(Unit, Particle) end
end
 
--[[ Callbacks ]]--
function OnLoad()
		enemyMinions = minionManager(MINION_ENEMY, 2000, player, MINION_SORT_HEALTH_ASC)
        allyMinions = minionManager(MINION_ALLY, 2000, player, MINION_SORT_HEALTH_ASC)
		if getChampTable()[myHero.charName] then
			ChampInfo = getChampTable()[myHero.charName]
		end
        OrbwalkingOnLoad()
        SkillsOnLoad()
        LastHitOnLoad()
        SummonerOnLoad()
        AutoCarry.EnemyTable = GetEnemyHeroes()
        PriorityOnLoad()
        setMenus()
		StreamingMenu.DisableDrawing = false 
        if VIP_USER and PerformanceMenu.VipCol then
			require "Collision" 
			PrintChat(">> Sida's Auto Carry: VIP Collision Enabled")  
			useVIPCol = true 
		end
		if PluginOnLoad then PluginOnLoad() end
		if not AutoCarry.OverrideCustomChampionSupport then LoadCustomChampionSupport() end
		if CustomOnLoad then CustomOnLoad() end
        PrintChat(">> Sida's Auto Carry: Revamped!")
end
 
function OnTick()
        OrbwalkingOnTick()
        LastHitOnTick()
        SkillsOnTick()
        SummonerOnTick()
        setMovement()
        SetMuramana()
		if PluginOnTick then PluginOnTick() end
		AutoCarry.CurrentlyShooting = (GetTickCount() + GetLatency()/2 < lastAttack + previousWindUp + 20 + 30)
		if StreamingMenu.DisableDrawing and not hudDisabled then 
			for i = 0, 10 do
				PrintChat("")
			end
			hudDisabled = true 
			DisableOverlay() 
		end
        if (AutoCarry.MainMenu.AutoCarry and ItemMenu.UseItemsAC) or (AutoCarry.MainMenu.LastHit and ItemMenu.UseItemsLastHit) or (AutoCarry.MainMenu.MixedMode and ItemMenu.UseItemsMixed) then
                 UseItemsOnTick()
        end
       
        if AutoCarry.MainMenu.AutoCarry then
                if AutoCarry.Orbwalker.target ~= nil and EnemyInRange(AutoCarry.Orbwalker.target) then
                        if timeToShoot() and AutoCarry.CanAttack then
                                attackEnemy(AutoCarry.Orbwalker.target)
                        elseif heroCanMove() then
                                moveToCursor()
                        end
                elseif heroCanMove() then
                        moveToCursor()
                end
        end
       
        if AutoCarry.MainMenu.LastHit then
                if not ValidTarget(killableMinion) then killableMinion = getKillableCreep(1) end
                if ValidTarget(killableMinion) and timeToShoot() and AutoCarry.CanAttack then
                        attackEnemy(killableMinion)
                --elseif ValidTarget(turretMinion.obj) and timeToShoot() and AutoCarry.CanAttack and turretMinion.timeToHit > getTimeToHit(turretMinion.obj, projSpeed) then
                  --      attackEnemy(turretMinion.obj)
                elseif heroCanMove() and FarmMenu.moveLastHit then
                        moveToCursor()
                end
        end
       
        if AutoCarry.MainMenu.MixedMode then
                if AutoCarry.Orbwalker.target ~= nil and EnemyInRange(AutoCarry.Orbwalker.target) then
                        if timeToShoot() and AutoCarry.CanAttack then
                                attackEnemy(AutoCarry.Orbwalker.target)
                        elseif heroCanMove() then
                                moveToCursor()
                        end
                else
                        if not ValidTarget(killableMinion) then killableMinion = getKillableCreep(1) end
                        if ValidTarget(killableMinion) and timeToShoot() and AutoCarry.CanAttack then
                                attackEnemy(killableMinion)
                        elseif heroCanMove() and FarmMenu.moveMixed then
                                moveToCursor()
                        end
                end
        end
       
        if AutoCarry.MainMenu.LaneClear then
			if not ValidTarget(killableMinion) then killableMinion = getKillableCreep(1) end
			if ValidTarget(killableMinion) and timeToShoot() and AutoCarry.CanAttack then
					attackEnemy(killableMinion)
			else
				local tMinion = getHighestMinion()
				if tMinion and ValidTarget(tMinion) and timeToShoot() and AutoCarry.CanAttack then
					pluginMinion = tMinion
					attackEnemy(tMinion)
				else
					if PerformanceMenu.JungleFarm then
						local tMinion = getJungleMinion()
						if tMinion and ValidTarget(tMinion) and timeToShoot() and AutoCarry.CanAttack then
							pluginMinion = tMinion
							attackEnemy(tMinion)
						elseif heroCanMove() and FarmMenu.moveClear then
							moveToCursor()
						end	
					elseif heroCanMove() and FarmMenu.moveClear then
							moveToCursor()
					end
				end
			end
        end
       
         if CustomOnTick then CustomOnTick() end
end
 
function OnProcessSpell(unit, spell)
	OrbwalkingOnProcessSpell(unit, spell)
	LastHitOnProcessSpell(unit, spell)
	if CustomOnProcessSpell then CustomOnProcessSpell(unit, spell) end
	if PluginOnProcessSpell then PluginOnProcessSpell(unit, spell) end
end
 
function OnCreateObj(obj)    
	if myHero.dead or ChampInfo == nil then return end
        if PerformanceMenu.JungleFarm then LastHitOnCreateObj(obj) end
        if CustomOnCreateObj then CustomOnCreateObj(obj) end
		if PluginOnCreateObj then PluginOnCreateObj(obj) end
end
 
function OnDeleteObj(obj)
        if PerformanceMenu.JungleFarm then LastHitOnDeleteObj(obj) end
        if CustomOnDeleteObj then CustomOnDeleteObj(obj) end
		if PluginOnDeleteObj then PluginOnDeleteObj(obj) end
end

function OnAnimation(unit, animation)    
	if PluginOnAnimation then PluginOnAnimation(unit, animation) end
end		

--function OnSendPacket(packet)
--	if PluginOnSendPacket then PluginOnSendPacket(packet) end
--end		
 
function OnDraw()
	if not DisplayMenu.disableAllDrawing then
        if DisplayMenu.myRange and not disableRangeDraw then
                DrawCircle(myHero.x, myHero.y, myHero.z, getTrueRange(), 0x19A712)
        end
        DrawCircle(myHero.x, myHero.y, myHero.z, AutoCarry.MainMenu.HoldZone, 0xFFFFFF)
        OrbwalkingOnDraw()
        LastHitOnDraw()
        if CustomOnDraw then CustomOnDraw() end
		if PluginOnDraw then PluginOnDraw() end
	end
end

function OnWndMsg(msg, key)
	if PluginOnWndMsg then PluginOnWndMsg(msg, key) end
end

--[[ Data ]]--
function getChampTable()
    return {
        Ahri         = { projSpeed = 1.6},
        Anivia       = { projSpeed = 1.05},
        Annie        = { projSpeed = 1.0},
        Ashe         = { projSpeed = 2.0},
        Brand        = { projSpeed = 1.975},
        Caitlyn      = { projSpeed = 2.5},
        Cassiopeia   = { projSpeed = 1.22},
        Corki        = { projSpeed = 2.0},
        Draven       = { projSpeed = 1.4},
        Ezreal       = { projSpeed = 2.0},
        FiddleSticks = { projSpeed = 1.75},
        Graves       = { projSpeed = 3.0},
        Heimerdinger = { projSpeed = 1.4},
        Janna        = { projSpeed = 1.2},
        Jayce        = { projSpeed = 2.2},
        Karma        = { projSpeed = 1.2},
        Karthus      = { projSpeed = 1.25},
        Kayle        = { projSpeed = 1.8},
        Kennen       = { projSpeed = 1.35},
        KogMaw       = { projSpeed = 1.8},
        Leblanc      = { projSpeed = 1.7},
        Lucian       = { projSpeed = 2.0},
        Lulu         = { projSpeed = 2.5},
        Lux          = { projSpeed = 1.55},
        Malzahar     = { projSpeed = 1.5},
        MissFortune  = { projSpeed = 2.0},
        Morgana      = { projSpeed = 1.6},
        Nidalee      = { projSpeed = 1.7},
        Orianna      = { projSpeed = 1.4},
        Quinn        = { projSpeed = 1.85},
        Ryze         = { projSpeed = 2.4},
        Sivir        = { projSpeed = 1.4},
        Sona         = { projSpeed = 1.6},
        Soraka       = { projSpeed = 1.0},
        Swain        = { projSpeed = 1.6},
        Syndra       = { projSpeed = 1.2},
        Teemo        = { projSpeed = 1.3},
        Tristana     = { projSpeed = 2.25},
        TwistedFate  = { projSpeed = 1.5},
        Twitch       = { projSpeed = 2.5},
        Urgot        = { projSpeed = 1.3},
        Vayne        = { projSpeed = 2.0},
        Varus        = { projSpeed = 2.0},
        Veigar       = { projSpeed = 1.05},
        Viktor       = { projSpeed = 2.25},
        Vladimir     = { projSpeed = 1.4},
        Xerath       = { projSpeed = 1.2},
        Ziggs        = { projSpeed = 1.5},
        Zilean       = { projSpeed = 1.25},
        Zyra         = { projSpeed = 1.7},
    }
end
 
function getSpellList()
        local spellArray = nil
        if myHero.charName == "Ezreal" then
                spellArray = {
                { spellKey = _Q, range = 1100, speed = 2.0, delay = 250, width = 70, configName = "mysticShot", displayName = "Q (Mystic Shot)", enabled = true, skillShot = true, minions = true, reset = false, reqTarget = true },
                { spellKey = _W, range = 1050, speed = 1.6, delay = 250, width = 90, configName = "essenceFlux", displayName = "W (Essence Flux)", enabled = true, skillShot = true, minions = false, reset = false, reqTarget = true },
                }
        elseif myHero.charName == "KogMaw" then
                spellArray = {
                { spellKey = _Q, range = 625, speed = 1.3, delay = 260, width = 200, configName = "causticSpittle", displayName = "Q (Caustic Spittle)", enabled = true, skillShot = false, minions = false, reset = true, reqTarget = true },
                { spellKey = _W, range = 625, speed = 1.3, delay = 260, width = 200, configName = "bioArcaneBarrage", displayName = "W (Bio-Arcane Barrage)", enabled = true, forceRange = true, forceToHitBox = true, skillShot = false, minions = false, reset = false, reqTarget = false },
                { spellKey = _E, range = 850, speed = 1.3, delay = 260, width = 200, configName = "voidOoze", displayName = "E (Void Ooze)", enabled = true, skillShot = true, minions = false, reset = false, reqTarget = true },
                { spellKey = _R, range = 1700, speed = math.huge, delay = 1000, width = 200, configName = "livingArtillery", displayName = "R (Living Artillery)", enabled = true, skillShot = true, minions = false, reset = false, reqTarget = true },
                }
        elseif myHero.charName == "Sivir" then
                spellArray = {
                { spellKey = _Q, range = 1000, speed = 1.33, delay = 250, width = 120, configName = "boomerangBlade", displayName = "Q (Boomerang Blade)", enabled = true, skillShot = true, minions = false, reset = false, reqTarget = true },
                { spellKey = _W, range = getTrueRange(), speed = 1, delay = 0, width = 200, configName = "Ricochet", displayName = "W (Ricochet)", enabled = true, skillShot = false, minions = false, reset = true, reqTarget = true },
                }
        elseif myHero.charName == "Graves" then
                spellArray = {
                { spellKey = _Q, range = 750, speed = 2, delay = 250, width = 200, configName = "buckShot", displayName = "Q (Buck Shot)", enabled = true, skillShot = true, minions = false, reset = false, reqTarget = true },
                { spellKey = _W, range = 700, speed = 1400, delay = 300, width = 500, configName = "smokeScreen", displayName = "W (Smoke Screen)", enabled = false, skillShot = true, minions = false, reset = false, reqTarget = true },
                { spellKey = _E, range = 580, speed = 1450, delay = 250, width = 200, configName = "quickDraw", displayName = "E (Quick Draw)", enabled = true, skillShot = false, minions = false, reset = true, reqTarget = false, atMouse = true },
                }
        elseif myHero.charName == "Caitlyn" then
                spellArray = {
                { spellKey = _Q, range = 1300, speed = 2.1, delay = 625, width = 100, configName = "piltoverPeacemaker", displayName = "Q (Piltover Peacemaker)", enabled = true, skillShot = true, minions = true, reset = false, reqTarget = true },
                }
        elseif myHero.charName == "Corki" then
                spellArray = {
                { spellKey = _Q, range = 600, speed = 2, delay = 200, width = 500, configName = "phosphorusBomb", displayName = "Q (Phosphorus Bomb)", enabled = true, skillShot = true, minions = false, reset = false, reqTarget = true },
                { spellKey = _R, range = 1225, speed = 2, delay = 200, width = 50, configName = "missileBarrage", displayName = "R (Missile Barrage)", enabled = true, skillShot = true, minions = true, reset = false, reqTarget = true },
                }
        elseif myHero.charName == "Teemo" then
                spellArray = {
                { spellKey = _Q, range = 580, speed = 2, delay = 0, width = 200, configName = "blindingDart", displayName = "Q (Blinding Dart)", enabled = true, skillShot = false, minions = false, reset = false, reqTarget = true },
                }
        elseif myHero.charName == "TwistedFate" then
                spellArray = {
                { spellKey = _Q, range = 1200, speed = 1.45, delay = 250, width = 200, configName = "wildCards", displayName = "Q (Wild Cards)", enabled = true, skillShot = true, minions = false, reset = false, reqTarget = true },
                }
        elseif myHero.charName == "Vayne" then
                spellArray = {
                { spellKey = _Q, range = 580, speed = 1.45, delay = 250, width = 200, configName = "tumble", displayName = "Q (Tumble)", enabled = true, skillShot = false, minions = false, reset = true, reqTarget = false, atMouse = true },
                { spellKey = _R, range = 580, speed = 1.45, delay = 250, width = 200, configName = "finalHour", displayName = "R (Final Hour)", enabled = true, skillShot = false, minions = false, reset = false, reqTarget = false},
                }
        elseif myHero.charName == "MissFortune" then
                spellArray = {
                { spellKey = _Q, range = 650, speed = 1.45, delay = 250, width = 200, configName = "doubleUp", displayName = "Q (Double Up)", enabled = true, skillShot = false, minions = false, reset = true, reqTarget = true},
                { spellKey = _W, range = 580, speed = 1.45, delay = 250, width = 200, configName = "impureShots", displayName = "W (Impure Shots)", enabled = true, skillShot = false, minions = false, reset = false, reqTarget = false},
                { spellKey = _E, range = 800, speed = math.huge, delay = 500, width = 500, configName = "makeItRain", displayName = "E (Make It Rain)", enabled = false, skillShot = true, minions = false, reset = false, reqTarget = true },
                }
        elseif myHero.charName == "Tristana" then
                spellArray = {
                { spellKey = _Q, range = 580, speed = 1.45, delay = 250, width = 200, configName = "rapidFire", displayName = "Q (Rapid Fire)", enabled = true, skillShot = false, minions = false, reset = false, reqTarget = false},
                { spellKey = _E, range = 550, speed = 1.45, delay = 250, width = 200, configName = "explosiveShot", displayName = "E (Explosive Shot)", enabled = true, skillShot = false, minions = false, reset = false, reqTarget = true},
                }
        elseif myHero.charName == "Draven" then
                spellArray = {
                { spellKey = _E, range = 950, speed = 1.37, delay = 300, width = 130, configName = "standAside", displayName = "E (Stand Aside)", enabled = true, skillShot = true, minions = false, reset = false, reqTarget = true},
                }
        --[[    Added Champs    ]]
        elseif myHero.charName == "Kennen" then
                spellArray = {
                { spellKey = _Q, range = 1050, speed = 1.65, delay = 180, width = 80, configName = "thunderingShuriken", displayName = "Q (Thundering Shuriken)", enabled = true, skillShot = true, minions = true, reset = false, reqTarget = true },
                }
        elseif myHero.charName == "Ashe" then
                spellArray = {
                { spellKey = _W, range = 1200, speed = 2.0, delay = 120, width = 85, configName = "Volley", displayName = "W (Volley)", enabled = true, skillShot = true, minions = true, reset = false, reqTarget = true },
                }
        elseif myHero.charName == "Syndra" then
                spellArray = {
                { spellKey = _Q, range = 800, speed = math.huge, delay = 400, width = 100, configName = "darkSphere", displayName = "Q (Dark Sphere)", enabled = true, skillShot = true, minions = false, reset = false, reqTarget = true },
                }
        elseif myHero.charName == "Jayce" then
                spellArray = {
                { spellKey = _Q, range = 1600, speed = 2.0, delay = 350, width = 90, configName = "shockBlast", displayName = "Q (Shock Blast)", enabled = true, skillShot = true, minions = true, reset = false, reqTarget = true },
                }
        elseif myHero.charName == "Nidalee" then
                spellArray = {
                { spellKey = _Q, range = 1500, speed = 1.3, delay = 125, width = 80, configName = "javelinToss", displayName = "Q (Javelin Toss)", enabled = true, skillShot = true, minions = true, reset = false, reqTarget = true },
                }
        --[[elseif myHero.charName == "Varus" then
                spellArray = {
                { spellKey = _E, range = 925, speed = 1.75, delay = 240, width = 235, configName = "hailofArrows", displayName = "E (Hail of Arrows)", enabled = true, skillShot = true, minions = false, reset = false, reqTarget = true },
                }]]
        elseif myHero.charName == "Quinn" then
                spellArray = {
                { spellKey = _Q, range = 1050, speed = 1.55, delay = 220, width = 90, configName = "blindingAssault", displayName = "Q (Blinding Assault)", enabled = true, skillShot = true, minions = true, reset = false, reqTarget = true },
                --{ spellKey = _E, range = 725, speed = 1.45, delay = 250, width = nil, configName = "vault", displayName = "E (Vault)", enabled = true, skillShot = false, minions = false, reset = true, reqTarget = true},
                }
        elseif myHero.charName == "LeeSin" then
                spellArray = {
                { spellKey = _Q, range = 975, speed = 1.5, delay = 250, width = 70, configName = "sonicWave", displayName = "Q (Sonic Wave)", enabled = true, skillShot = true, minions = true, reset = false, reqTarget = true },
                }
        elseif myHero.charName == "Gangplank" then
                spellArray = {
                { spellKey = _Q, range = 625, speed = 1.45, delay = 250, width = 200, configName = "parley", displayName = "Q (Parley)", enabled = true, skillShot = false, minions = false, reset = false, reqTarget = true},
                }
        elseif myHero.charName == "Twitch" then
                spellArray = {
                { spellKey = _W, range = 950, speed = 1.4, delay = 250, width = 275, configName = "venomCask", displayName = "W (Venom Cask)", enabled = false, skillShot = true, minions = false, reset = false, reqTarget = true },
                }
		elseif myHero.charName == "Darius" then
			spellArray = {
			{ spellKey = _W, range = 300, speed = 2, delay = 0, width = 200, configName = "cripplingStrike", displayName = "W (Crippling Strike)", enabled = true, skillShot = false, minions = true, reset = true, reqTarget = false },
			}	
		elseif myHero.charName == "Hecarim" then
			spellArray = {
			{ spellKey = _Q, range = 300, speed = 2, delay = 0, width = 200, configName = "rampage", displayName = "Q (Rampage)", enabled = true, skillShot = false, minions = true, reset = true, reqTarget = false },
			}			
		elseif myHero.charName == "Warwick" then
			spellArray = {
			{ spellKey = _Q, range = 300, speed = 2, delay = 0, width = 200, configName = "hungeringStrike", displayName = "Q (Hungering Strike)", enabled = true, skillShot = false, minions = true, reset = true, reqTarget = true },
			}	
		elseif myHero.charName == "MonkeyKing" then
			spellArray = {
			{ spellKey = _Q, range = 300, speed = 2, delay = 0, width = 200, configName = "crushingBlow", displayName = "Q (Crushing Blow)", enabled = true, skillShot = false, minions = true, reset = true, reqTarget = false },
			}		
		elseif myHero.charName == "Poppy" then
			spellArray = {
			{ spellKey = _Q, range = 300, speed = 2, delay = 0, width = 200, configName = "devastatingBlow", displayName = "Q (Devastating Blow)", enabled = true, skillShot = false, minions = true, reset = true, reqTarget = false },
			}	
		elseif myHero.charName == "Talon" then
			spellArray = {
			{ spellKey = _Q, range = 300, speed = 2, delay = 0, width = 200, configName = "noxianDiplomacy", displayName = "Q (Noxian Diplomacy)", enabled = true, skillShot = false, minions = true, reset = true, reqTarget = false },
			}			
		elseif myHero.charName == "Nautilus" then
			spellArray = {
			{ spellKey = _W, range = 300, speed = 2, delay = 0, width = 200, configName = "titansWrath", displayName = "W (Titans Wrath)", enabled = true, skillShot = false, minions = true, reset = true, reqTarget = false },
			}		
		elseif myHero.charName == "Gangplank" then
			spellArray = {
			{ spellKey = _Q, range = 300, speed = 2, delay = 0, width = 200, configName = "parlay", displayName = "Q (Parlay)", enabled = true, skillShot = false, minions = true, reset = true, reqTarget = true },
			}		
		elseif myHero.charName == "Vi" then
			spellArray = {
			{ spellKey = _E, range = 300, speed = 2, delay = 0, width = 200, configName = "excessiveForce", displayName = "E (Excessive Force)", enabled = true, skillShot = false, minions = true, reset = true, reqTarget = false },
			}			
		elseif myHero.charName == "Rengar" then
			spellArray = {
			{ spellKey = _Q, range = 300, speed = 2, delay = 0, width = 200, configName = "savagery", displayName = "Q (Savagery)", enabled = true, skillShot = false, minions = true, reset = true, reqTarget = false },
			}			
		elseif myHero.charName == "Trundle" then
			spellArray = {
			{ spellKey = _Q, range = 300, speed = 2, delay = 0, width = 200, configName = "chomp", displayName = "Q (Chomp)", enabled = true, skillShot = false, minions = true, reset = true, reqTarget = false },
			}					
		elseif myHero.charName == "Leona" then
			spellArray = {
			{ spellKey = _Q, range = 300, speed = 2, delay = 0, width = 200, configName = "shieldOfDaybreak", displayName = "Q (Shield Of Daybreak)", enabled = true, skillShot = false, minions = true, reset = true, reqTarget = false },
			}			
		elseif myHero.charName == "Fiora" then
			spellArray = {
			{ spellKey = _E, range = 300, speed = 2, delay = 0, width = 200, configName = "burstOfSpeed", displayName = "E (Burst Of Speed)", enabled = true, skillShot = false, minions = true, reset = true, reqTarget = false },
			}		
		elseif myHero.charName == "Blitzcrank" then
			spellArray = {
			{ spellKey = _E, range = 300, speed = 2, delay = 0, width = 200, configName = "powerFist", displayName = "E (Power Fist)", enabled = true, skillShot = false, minions = true, reset = true, reqTarget = false },
			}			
		elseif myHero.charName == "Shyvana" then
			spellArray = {
			{ spellKey = _Q, range = 300, speed = 2, delay = 0, width = 200, configName = "twinBlade", displayName = "Q (Twin Blade)", enabled = true, skillShot = false, minions = true, reset = true, reqTarget = false },
			}			
		elseif myHero.charName == "Renekton" then
			spellArray = {
			{ spellKey = _W, range = 300, speed = 2, delay = 0, width = 200, configName = "ruthless Predator", displayName = "W (Ruthless Predator)", enabled = true, skillShot = false, minions = true, reset = true, reqTarget = false },
			}			
		elseif myHero.charName == "Jax" then
			spellArray = {
			{ spellKey = _W, range = 300, speed = 2, delay = 0, width = 200, configName = "empower", displayName = "W (Empower)", enabled = true, skillShot = false, minions = true, reset = true, reqTarget = false },
			}		
		elseif myHero.charName == "XinZhao" then
			spellArray = {
			{ spellKey = _Q, range = 300, speed = 2, delay = 0, width = 200, configName = "threeTalonStrike", displayName = "Q (Three Talon Strike)", enabled = true, skillShot = false, minions = true, reset = true, reqTarget = false },
			}		
		elseif myHero.charName == "Nunu" then
			spellArray = {
			{ spellKey = _E, range = GetSpellData(_E).range, speed = 1.45, delay = 250, width = 200, configName = "showball", displayName = "E (Snowball)", enabled = true, skillShot = false, minions = false, reset = false, reqTarget = true},
			}
		elseif myHero.charName == "Khazix" then
			spellArray = {
			{ spellKey = _Q, range = GetSpellData(_Q).range, speed = 1.45, delay = 250, width = 200, configName = "tasteTheirFear", displayName = "Q (Taste Their Fear)", enabled = true, skillShot = false, minions = false, reset = true, reqTarget = true},
			}
		elseif myHero.charName == "Shen" then
			spellArray = {
			{ spellKey = _Q, range = GetSpellData(_Q).range, speed = 1.45, delay = 250, width = 200, configName = "vorpalBlade", displayName = "Q (Vorpal Blade)", enabled = true, skillShot = false, minions = false, reset = false, reqTarget = true},
			}
		end
return spellArray
end
 
local priorityTable = {
 
    AP = {
        "Annie", "Ahri", "Akali", "Anivia", "Annie", "Brand", "Cassiopeia", "Diana", "Evelynn", "FiddleSticks", "Fizz", "Gragas", "Heimerdinger", "Karthus",
        "Kassadin", "Katarina", "Kayle", "Kennen", "Leblanc", "Lissandra", "Lux", "Malzahar", "Mordekaiser", "Morgana", "Nidalee", "Orianna",
        "Rumble", "Ryze", "Sion", "Swain", "Syndra", "Teemo", "TwistedFate", "Veigar", "Viktor", "Vladimir", "Xerath", "Ziggs", "Zyra", "MasterYi",
    },
    Support = {
        "Alistar", "Blitzcrank", "Janna", "Karma", "Leona", "Lulu", "Nami", "Nunu", "Sona", "Soraka", "Taric", "Thresh", "Zilean",
    },
 
    Tank = {
        "Amumu", "Chogath", "DrMundo", "Galio", "Hecarim", "Malphite", "Maokai", "Nasus", "Rammus", "Sejuani", "Shen", "Singed", "Skarner", "Volibear",
        "Warwick", "Yorick", "Zac",
    },
 
    AD_Carry = {
        "Ashe", "Caitlyn", "Corki", "Draven", "Ezreal", "Graves", "Jayce", "KogMaw", "MissFortune", "Pantheon", "Quinn", "Shaco", "Sivir",
        "Talon", "Tristana", "Twitch", "Urgot", "Varus", "Vayne", "Zed",
 
    },
 
    Bruiser = {
        "Aatrox", "Darius", "Elise", "Fiora", "Gangplank", "Garen", "Irelia", "JarvanIV", "Jax", "Khazix", "LeeSin", "Nautilus", "Nocturne", "Olaf", "Poppy",
        "Renekton", "Rengar", "Riven", "Shyvana", "Trundle", "Tryndamere", "Udyr", "Vi", "MonkeyKing", "XinZhao",
    },
 
}
 
function SetPriority(table, hero, priority)
        for i=1, #table, 1 do
                if hero.charName:find(table[i]) ~= nil then
                        TS_SetHeroPriority(priority, hero.charName)
                end
        end
end
 
function arrangePrioritys()
        for i, enemy in ipairs(AutoCarry.EnemyTable) do
                SetPriority(priorityTable.AD_Carry, enemy, 1)
                SetPriority(priorityTable.AP,       enemy, 2)
                SetPriority(priorityTable.Support,  enemy, 3)
                SetPriority(priorityTable.Bruiser,  enemy, 4)
                SetPriority(priorityTable.Tank,     enemy, 5)
        end
end
 
function PriorityOnLoad()
        if heroManager.iCount < 10 then
                PrintChat(" >> Too few champions to arrange priority")
        else
                TargetSelector(TARGET_LOW_HP_PRIORITY, 0)
                arrangePrioritys()
        end
end
 
function getJungleMobs()
        return {"Dragon6.1.1", "Worm12.1.1", "GiantWolf8.1.3", "wolf8.1.1", "wolf8.1.2", "AncientGolem7.1.1", "YoungLizard7.1.2", "YoungLizard7.1.3", "Wraith9.1.3", "LesserWraith9.1.1", "LesserWraith9.1.2",
        "LesserWraith9.1.4", "LizardElder10.1.1", "YoungLizard10.1.2", "YoungLizard10.1.3", "Golem11.1.2", "SmallGolem11.1.1", "GiantWolf2.1.3", "wolf2.1.1",
        "wolf2.1.2", "AncientGolem1.1.1", "YoungLizard1.1.2", "YoungLizard1.1.3", "Wraith3.1.3", "LesserWraith3.1.1", "LesserWraith3.1.2", "LesserWraith3.1.4",
        "LizardElder4.1.1", "YoungLizard4.1.2", "YoungLizard4.1.3", "Golem5.1.2", "SmallGolem5.1.1"}
end
 
--[[ Menus ]]--
function setMenus()
	mainMenu()
	skillsMenu()
	itemMenu()
	displayMenu()
	permaMenu()
	masteryMenu()
	farmMenu()
	summonerMenu()
	streamingMenu()
	performanceMenu()
	pluginMenu()
end
 
function itemMenu()
	ItemMenu = scriptConfig("Sida's Auto Carry: Items", "sidasacitems")
	ItemMenu:addParam("sep", "-- Settings --", SCRIPT_PARAM_INFO, "")
	ItemMenu:addParam("UseItemsAC", "Use Items With AutoCarry", SCRIPT_PARAM_ONOFF, true)
	ItemMenu:addParam("UseItemsLastHit", "Use Items With Harass", SCRIPT_PARAM_ONOFF, true)
	ItemMenu:addParam("UseItemsMixed", "Use Items With Mixed Mode", SCRIPT_PARAM_ONOFF, true)
	ItemMenu:addParam("sep2", "-- Items --", SCRIPT_PARAM_INFO, "")
	for _, item in ipairs(items) do
			ItemMenu:addParam(item.menu, "Use "..item.name, SCRIPT_PARAM_ONOFF, true)
	end
	ItemMenu:addParam("muraMana", "Use Muramana", SCRIPT_PARAM_ONOFF, true)
end
 
function mainMenu()
	AutoCarry.MainMenu = scriptConfig("Sida's Auto Carry: Settings", "sidasacmain")
	AutoCarry.MainMenu:addParam("AutoCarry", "Auto Carry", SCRIPT_PARAM_ONKEYDOWN, false, AutoCarryKey)
	AutoCarry.MainMenu:addParam("LastHit", "Last Hit", SCRIPT_PARAM_ONKEYDOWN, false, LastHitKey)
	AutoCarry.MainMenu:addParam("MixedMode", "Mixed Mode", SCRIPT_PARAM_ONKEYDOWN, false, MixedModeKey)
	AutoCarry.MainMenu:addParam("LaneClear", "Lane Clear", SCRIPT_PARAM_ONKEYDOWN, false, LaneClearKey)
	AutoCarry.MainMenu:addParam("Focused", "Prioritise Selected Target", SCRIPT_PARAM_ONOFF, false)
	AutoCarry.MainMenu:addParam("HoldZone", "Stand Still And Shoot Range", SCRIPT_PARAM_SLICE, 0, 0, getTrueRange(), 0)
	AutoCarry.MainMenu:addTS(AutoCarry.Orbwalker)
end
 
function skillsMenu()
	SkillsMenu = scriptConfig("Sida's Auto Carry: Skills", "sidasacskills")
	if Skills then
		SkillsMenu:addParam("sep", "-- Auto Carry Skills --", SCRIPT_PARAM_INFO, "")
		for _, skill in ipairs(Skills) do
			SkillsMenu:addParam(skill.configName.."AutoCarry", "Use "..skill.displayName, SCRIPT_PARAM_ONOFF, true)
		end
		SkillsMenu:addParam("sep2", "-- Mixed Mode Skills --", SCRIPT_PARAM_INFO, "")
		for _, skill in ipairs(Skills) do
			SkillsMenu:addParam(skill.configName.."MixedMode", "Use "..skill.displayName, SCRIPT_PARAM_ONOFF, true)
		end
	else
		SkillsMenu:addParam("sep", myHero.charName.." does not have any supported skills", SCRIPT_PARAM_INFO, "")
	end
	if VIP_USER then
		SkillsMenu:addParam("hitChance", "Ability Hitchance", SCRIPT_PARAM_SLICE, 60, 0, 100, 0)
	end
end
 
function displayMenu()
	DisplayMenu = scriptConfig("Sida's Auto Carry: Display", "sidasacdisplay")
	DisplayMenu:addParam("disableAllDrawing", "Disable All Drawing", SCRIPT_PARAM_ONOFF, false)
	DisplayMenu:addParam("myRange", "Attack Range Circle", SCRIPT_PARAM_ONOFF, true)
	DisplayMenu:addParam("target", "Circle Around Target", SCRIPT_PARAM_ONOFF, true)
	DisplayMenu:addParam("minion", "Circle Next Minion To Last Hit", SCRIPT_PARAM_ONOFF, true)
	DisplayMenu:addParam("sep", "-- Always Display (Requires Reload) --", SCRIPT_PARAM_INFO, "")
	DisplayMenu:addParam("AutoCarry", "Auto Carry Hotkey Status", SCRIPT_PARAM_ONOFF, true)
	DisplayMenu:addParam("LastHit", "Last Hit Hotkey Status", SCRIPT_PARAM_ONOFF, true)
	DisplayMenu:addParam("MixedMode", "Mixed Mode Hotkey Status", SCRIPT_PARAM_ONOFF, true)
	DisplayMenu:addParam("LaneClear", "Lane Clear Hotkey Status", SCRIPT_PARAM_ONOFF, true)
end
 
function permaMenu()
	if DisplayMenu.AutoCarry then AutoCarry.MainMenu:permaShow("AutoCarry") end
	if DisplayMenu.LastHit then AutoCarry.MainMenu:permaShow("LastHit") end
	if DisplayMenu.MixedMode then AutoCarry.MainMenu:permaShow("MixedMode") end
	if DisplayMenu.LaneClear then AutoCarry.MainMenu:permaShow("LaneClear") end
end
 
function masteryMenu()
	MasteryMenu = scriptConfig("Sida's Auto Carry: Masteries", "sidasacmasteries")
	MasteryMenu:addParam("Butcher", "Butcher", SCRIPT_PARAM_SLICE, 0, 0, 2, 0)
	MasteryMenu:addParam("Spellblade", "Spellblade", SCRIPT_PARAM_ONOFF, false)
	MasteryMenu:addParam("Executioner", "Executioner", SCRIPT_PARAM_ONOFF, false)
end
 
function farmMenu()
	FarmMenu = scriptConfig("Sida's Auto Carry: Farming", "sidasacfarming")
	FarmMenu:addParam("Predict", "Predict Minion Damage", SCRIPT_PARAM_ONOFF, true)
	FarmMenu:addParam("moveLastHit", "Move To Mouse Last Hit Farming", SCRIPT_PARAM_ONOFF, true)
	FarmMenu:addParam("moveMixed", "Move To Mouse Mixed Mode Farming", SCRIPT_PARAM_ONOFF, true)
	FarmMenu:addParam("moveClear", "Move To Mouse Lane Clear Farming", SCRIPT_PARAM_ONOFF, true)
end
 
function summonerMenu()
	SummonerMenu = scriptConfig("Sida's Auto Carry: Summoner Spells", "sidasacsummoner")
	SummonerMenu:addParam("Ignite", "Ignite Killable Enemies", SCRIPT_PARAM_ONOFF, true)
	SummonerMenu:addParam("Barrier", "Auto Barrier Upon High Damage", SCRIPT_PARAM_ONOFF, true)
end

function streamingMenu()
	StreamingMenu = scriptConfig("Sida's Auto Carry: Streaming", "sidasacstreaming")
	StreamingMenu:addParam("ShowClick", "Show Click Marker", SCRIPT_PARAM_ONOFF, true)
	StreamingMenu:addParam("MinRand", "Minimum Time Between Clicks", SCRIPT_PARAM_SLICE, 150, 0, 1000, 0)
	StreamingMenu:addParam("MaxRand", "Maximum Time Between Clicks", SCRIPT_PARAM_SLICE, 650, 0, 1000, 0)
	StreamingMenu:addParam("Colour", "0 = Green, 1 = Red", SCRIPT_PARAM_SLICE, 0, 0, 1, 0)
	StreamingMenu:addParam("DisableDrawing", "Streaming Mode", SCRIPT_PARAM_ONOFF, true)
end

function performanceMenu()
	PerformanceMenu = scriptConfig("Sida's Auto Carry: Performance", "sidasacperformance")
	PerformanceMenu:addParam("sep", "-- Can Cause FPS Lag! --", SCRIPT_PARAM_INFO, "")
	PerformanceMenu:addParam("VipCol", "Use VIP Collision (Requires Reload!)", SCRIPT_PARAM_ONOFF, false)
	PerformanceMenu:addParam("JungleFarm", "Enable Jungle Clearing", SCRIPT_PARAM_ONOFF, false)
end
 
function pluginMenu()
	if hasPlugin then
		AutoCarry.PluginMenu = scriptConfig("Sida's Auto Carry: "..myHero.charName.." Plugin", "sidasacplugin"..myHero.charName)
		require("SidasAutoCarryPlugin - "..myHero.charName)
		PrintChat(">> Sida's Auto Carry: Loaded "..myHero.charName.." plugin!")
	end
end