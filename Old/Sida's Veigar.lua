-- ###################################################################################################### --
-- #                                                                                                    # --
-- #                                  Sida's Veigar - I Will Swallow Your Soul                          # --
-- #                                                                                                    # --
-- ###################################################################################################### --

if myHero.charName ~= "Veigar" then return end

-- [Config]
local comboKey = 32					-- Main combo hotkey (E > W > Items > Q > R). Default spacebar.
local harassKey = string.byte("C")			-- Hotkey to harass (E > W > Q) Default C.
local MEC = string.byte("X")				-- Hotkey to close most enemies possible in cage. Default X.
local autoFarmKey = string.byte("J")			-- Toggle to enable/disable auto farm with Q. Default J.
local movement = true					-- Do you want to enable moving to mouse cursor when hotkeys are held?
local safetyNetRange = 350				-- The range of your Safety Net. Default 350.

-- [Globals]
local ts
local delay = 0
local eRadius = 375
local eRange = 600
local eDelay = 0.25
local qRange = 650
local lastFarmCheck = 0
local farmCheckTick = 100

function OnTick()
	ts:update()
	checkSafetyNet()
	damageCalc()
	if VeigarConfig.autoFarm then autoFarm() end
	if VeigarConfig.fullCombo and ts.target ~= nil then
		castE()
		if CanUseSpell(_E) == COOLDOWN or CanUseSpell(_E) == NOTLEARNED then
			castW(ts.target)
			useItems(ts.target)
			castQ()
			castR()
		end
	end
	if VeigarConfig.harass and ts.target ~= nil then
		castE()
		if CanUseSpell(_E) == COOLDOWN or CanUseSpell(_E) == NOTLEARNED then
			castW(ts.target)
			castQ()
		end
	end
	if VeigarConfig.trapMost then
		castEMec()
	end
	if VeigarConfig.movement and (VeigarConfig.fullCombo or VeigarConfig.harass) then
		myHero:MoveTo(mousePos.x, mousePos.z)
	end
end

function OnLoad()
	createMenu()
end

function createMenu()
	VeigarConfig = scriptConfig("Sida's Veigar - I Will Swallow Your Soul", "sidasveigar")
	VeigarConfig:addParam("fullCombo", "Full Combo", SCRIPT_PARAM_ONKEYDOWN, false, comboKey)
	VeigarConfig:addParam("harass", "Harass", SCRIPT_PARAM_ONKEYDOWN, false, harassKey)
	VeigarConfig:addParam("trapMost", "Trap Most Enemies", SCRIPT_PARAM_ONKEYDOWN, false, MEC)
	VeigarConfig:addParam("autoFarm", "Auto farm with Q", SCRIPT_PARAM_ONKEYTOGGLE, false, autoFarmKey)
	VeigarConfig:addParam("safetyNet", "Enable Safety Net", SCRIPT_PARAM_ONOFF, true)
	VeigarConfig:addParam("wNet", "W On Safety Net Targets", SCRIPT_PARAM_ONOFF, true)
	VeigarConfig:addParam("movement", "Move To Mouse", SCRIPT_PARAM_ONOFF, movement)
	VeigarConfig:addParam("saveMana", "Save Mana For Combo When Farming	", SCRIPT_PARAM_ONOFF, false)
	VeigarConfig:addParam("doDraw", "Draw circles and text", SCRIPT_PARAM_ONOFF, true)
	VeigarConfig:permaShow("fullCombo")
	VeigarConfig:permaShow("harass")
	VeigarConfig:permaShow("safetyNet")
	VeigarConfig:permaShow("autoFarm")
	ts = TargetSelector(TARGET_LOW_HP,qRange+300,DAMAGE_MAGIC)
	ts.name = "Veigar"
	VeigarConfig:addTS(ts)
end

function castQ()
	if ts.target ~= nil then
		CastSpell(_Q, ts.target)
	end
end

function castW(target)
	if target ~= nil and not target.canMove then
		CastSpell(_W, target)
	end
end

function castE()
	if ts.target ~= nil then
		local stunLoc = getELoc(ts.target)
		if GetDistance(stunLoc) < eRange then
			CastSpell(_E, stunLoc.x, stunLoc.z)
		end
	end
end

function castR()
	if ts.target ~= nil then
		CastSpell(_R, ts.target)
	end
end

function castEMec()
	bestLoc = GetMEC(400, 600, ts.target)
	if bestLoc then
		CastSpell(_E, bestLoc.center.x, bestLoc.center.z)
	end
end

function getELoc(target)
		 myLoc = Vector(myHero.x, myHero.y, myHero.z)
		 targetLoc = getPredictedPos(target)
		 targetLoc = Vector(targetLoc.x, targetLoc.y, targetLoc.z)
		 stunLoc = targetLoc + (targetLoc - myLoc):normalized() * eRadius
		 if GetDistance(stunLoc) < eRange then return stunLoc end
		 stunLoc = targetLoc - (targetLoc - myLoc):normalized() * eRadius
		 return stunLoc
end

function getPredictedPos(target)
	local travel = nil
	if ts.target ~= nil then
		travel = (delay + GetDistance(myHero, target))
		travel = (delay + GetDistance(GetPredictionPos(target, travel)))
		travel = (delay + GetDistance(GetPredictionPos(target, travel)))
		travel = (delay + GetDistance(GetPredictionPos(target, travel)))
		ts:SetPrediction(travelDuration) 	
		return GetPredictionPos(target, travel)
	end
	return nil
end

function checkSafetyNet()
	if VeigarConfig.safetyNet then
	local closestEnemy = findClosestEnemy()
		if closestEnemy ~= nil and CanUseSpell(_E) == READY and not myHero.dead and GetDistance(closestEnemy) < safetyNetRange then
			local stunLoc = getELoc(closestEnemy)
			CastSpell(_E, stunLoc.x, stunLoc.z)
			if VeigarConfig.wNet and not closestEnemy.canMove and CanUseSpell(_E) == COOLDOWN then
				CastSpell(_W, closestEnemy.x, closestEnemy.z)
			end
		end
	end
end

function findClosestEnemy()
	local closestEnemy = nil
	local currentEnemy = nil
	for i=1, heroManager.iCount do
		currentEnemy = heroManager:GetHero(i)
		if currentEnemy.team ~= myHero.team and not currentEnemy.dead and currentEnemy.visible then
			if closestEnemy == nil then
				closestEnemy = currentEnemy
			elseif GetDistance(currentEnemy) < GetDistance(closestEnemy) then
				closestEnemy = currentEnemy
			end
		end
	end
	return closestEnemy
end

function useItems(target)
	local DFG = GetInventorySlotItem(3128)
	if DFG ~= nil and myHero:CanUseSpell(DFG) == READY then CastSpell(DFG, target) end
end

function autoFarm()
	local usedQ = false
	if VeigarConfig.autoFarm and GetTickCount() > lastFarmCheck + farmCheckTick then
		if CanUseSpell(_Q) then
			if VeigarConfig.saveMana then
				local comboMana = GetSpellData(_Q).mana + GetSpellData(_W).mana + GetSpellData(_E).mana + GetSpellData(_R).mana
				if comboMana + GetSpellData(_Q).mana > myHero.mana then return end
			end
			for k = 1, objManager.maxObjects do
				if not usedQ then
					local minion = objManager:GetObject(k)
					if minion ~= nil and minion.name:find("Minion_") and minion.team ~= myHero.team and minion.dead == false and GetDistance(minion) < qRange then
						local qDamage = getDmg("Q",minion,myHero)
						if qDamage >= minion.health then
							CastSpell(_Q, minion)
							usedQ = true
						end
					end
				end
			end
		end
		lastFarmCheck = GetTickCount()
	end
end

function damageCalc()
	if VeigarConfig.doDraw then
		if ts.target ~= nil then
			local qDamage = getDmg("Q",ts.target,myHero)
			local wDamage = getDmg("W",ts.target,myHero)
			local rDamage = getDmg("R",ts.target,myHero)
			local dfgDamage = (GetInventorySlotItem(3128) and getDmg("DFG",ts.target,myHero) or 0)
			local totalDamage = 0		
			local remainingHealth = 0
			if CanUseSpell(_Q) == READY then totalDamage = totalDamage + qDamage end
			if CanUseSpell(_W) == READY and (CanUseSpell(_E) == READY or not ts.target.canMove) then totalDamage = totalDamage + wDamage end
			if CanUseSpell(_R) == READY then totalDamage = totalDamage + rDamage end
			totalDamage = totalDamage + dfgDamage
			
			if ts.target.health <= totalDamage then
				PrintFloatText(ts.target,0, "Finish him!!!")
			else
				PrintFloatText(ts.target,0, tostring(math.floor((ts.target.health - totalDamage)+0.5)))
			end
		end
	end
end

function OnDraw()
	if VeigarConfig.doDraw then
		if ts.target ~= nil then
			DrawCircle(ts.target.x, ts.target.y, ts.target.z, 100, 0xFFFF00)
		end
		DrawCircle(myHero.x, myHero.y, myHero.z, safetyNetRange, 0xFFFF00) 
		DrawCircle(myHero.x, myHero.y, myHero.z, 650, 0xFFFF00) 
	end
end