-- ###################################################################################################### --
-- #                                    Kassadin - Feel The Pain By Sida                                # --
-- ###################################################################################################### --

if myHero.charName ~= "Kassadin" then return end

-- ########### Configuration ############

-- Note, all configuration options can be changed in-game but won't be saved. Change them here if you want them to be saved.

local useUlt = "Yes" 				-- Do you want to use your ulti in your combo? Yes/No
local autoFarmKey = string.byte("J")			-- Toggle to enable/disable auto farm with Q. Default J.
local killSteal	= "Yes"				-- Do you want to killsteal when possible? Yes/No
local saveEscapeMana = "No"			-- Do you want to always make sure you have enough mana to Riftwalk away? Yes/No
local ignoreManaForSteal = "Yes"	-- If you chose to keep enough mana to escape, do you want to ignore that if you can steal a kill? Yes/No
local drawCircles = "Yes"			-- Do you want to see range circles around Kassadin? Yes/No
local willDrawText = "Yes"			-- Do you want to see  text over the enemies to tell you if you can kill them? Yes/No
local maxRiftwalkStacks = 4			-- Your combo will stop using Riftwalk if your stacks reach this number
local killStealStackIgnore = "Yes" 	-- Do you want to ignore the Riftwalk stack limit when it would get you a kill?
local ignoreUseUltToSteal = "Yes"	-- If you are not using ult in your combo, do you want it to activate when killstealing?
local ultOutOfRange = "Yes"			-- Use ult to close the cap to enemies in your combo to use other abilities, even if the ult won't do damage (Gap Closer)?
local willUseIgnite = "Yes"			-- Do you want to include ignite damage in combos and use it automatically?
local showEnemyHealthAt = 500		-- If an enemy only needs to lose this much or less health for you to kill with your combo, the amount they must lose is displayed on them.	

-- ########### End Configuration ############

local ts
local farm = false
local ultStacks = 0
local lastUlt = 0
local Q, W, E, R = "Q", "W", "E", "R"
local combo = {R, Q, E, W}
local availableMana
local enemyHP = 0
local getCloser = false
local isKillStealUlt = false
local gapCloser = false
local myDamage = 0
local igniteRange = 600
local delay = 0
local nextTick = 0
local waitDelay = 400
local lastFarmCheck = 0
local farmCheckTick = 100
local qRange = 650
local wRange = 150
local eRange = 400
local rRange = 950
local range = rRange
local gotIgnite = nil
local shouldUseIgnite = false
local landInIgniteRange = false
local SheenSlot, TrinitySlot, LichBaneSlot = nil, nil, nil

function OnLoad()
	KCConfig = scriptConfig("Sida's Kassadin - Feel The Pain", "kassadin")
	KCConfig:addParam("scriptActive", "Combo", SCRIPT_PARAM_ONKEYDOWN, false, 32)
	KCConfig:addParam("harass", "Harass", SCRIPT_PARAM_ONKEYDOWN, false, 81)
	KCConfig:addParam("QFarm", "Farm with Q", SCRIPT_PARAM_ONKEYDOWN, false, 65)
	KCConfig:addParam("useUlt", "Use ult in combo", SCRIPT_PARAM_ONOFF, stringToBool(useUlt))
	KCConfig:addParam("useUltNoRange", "Gap Closer", SCRIPT_PARAM_ONOFF, stringToBool(ultOutOfRange))
	KCConfig:addParam("ultRangeOverride", "Always use Gap Closer to killsteal", SCRIPT_PARAM_ONOFF, stringToBool(ultOutOfRange))
	KCConfig:addParam("killSteal", "Kill Steal!", SCRIPT_PARAM_ONOFF, stringToBool(killSteal))
	KCConfig:addParam("saveMana", "Guarantee Escape", SCRIPT_PARAM_ONOFF,stringToBool(saveEscapeMana))
	KCConfig:addParam("manaOverride", "Ignore guarantee escape mana when killstealing", SCRIPT_PARAM_ONOFF, stringToBool(ignoreManaforSteal))	
	KCConfig:addParam("ignoreStackCap", "Ignore 4-stacks ulti cap to killsteal", SCRIPT_PARAM_ONOFF, stringToBool(killStealStackIgnore))	
	KCConfig:addParam("useUltOverride", "Ignore Use Ult toggle when killstealing", SCRIPT_PARAM_ONOFF, stringToBool(ignoreUseUltToSteal))	
	KCConfig:addParam("useIgnite", "Use Ignite In Combos", SCRIPT_PARAM_ONOFF, stringToBool(willUseIgnite))
	KCConfig:addParam("drawcircles", "Draw Circles", SCRIPT_PARAM_ONOFF, stringToBool(drawCircles))
	KCConfig:addParam("drawtext", "Draw Text", SCRIPT_PARAM_ONOFF, stringToBool(willDrawText))
	KCConfig:permaShow("scriptActive")
	KCConfig:permaShow("harass")
	KCConfig:permaShow("QFarm")
	ts = TargetSelector(TARGET_LOW_HP,range,DAMAGE_MAGIC)
	ts.name = "Kassadin"
	KCConfig:addTS(ts)
	gotIgnite = hasIgnite()
	enemyMinions = minionManager(MINION_ENEMY, 650, player, MINION_SORT_HEALTH_ASC)	
end

function OnCreateObj(obj)
        if obj ~= nil and string.find(obj.name, "Riftwalk_Flashback") then
			if GetDistance(myHero, obj) < 50 then
				lastUlt = GetTickCount()
				ultStacks = ultStacks + 1
			end
        end
end

function OnTick()
	ts:update()		
	updateUltStacks()
	shouldUseIgnite = false
	SheenSlot, TrinitySlot, LichBaneSlot = GetInventorySlotItem(3057), GetInventorySlotItem(3078), GetInventorySlotItem(3100)
	availableMana = calculateAvailableMana()
	updateRange()
	if ts.target ~= nil then myDamage = getDamage(ts.target) end
		killSteal()
		
	if KCConfig.harass then
		castQ()
	end
	if KCConfig.scriptActive and ts.target ~= nil then
		 useCombo()
	end
	
	--[[	Last Hit	]]--
	enemyMinions:update()

	if KCConfig.QFarm then  
		for index, minion in pairs(enemyMinions.objects) do
		local qDamage =getDmg ("Q",minion,myHero)
			if CanUseSpell (_Q) then
				if qDamage >= minion.health then
						CastSpell (_Q, minion)
				end
				
			end
		end
	end	
	
	
end

function updateUltStacks()
	if ultStacks ~= 0 and GetTickCount() > lastUlt + 8200 then
		ultStacks = 0
	end
end

function updateRange()
	if KCConfig.useUltNoRange then range = rRange + qRange
	else range = rRange end
	ts = TargetSelector(TARGET_LOW_HP,range,DAMAGE_MAGIC)
	ts:update()
end

function calculateAvailableMana()
	if KCConfig.saveMana then
		return myHero.mana - getRMana()
	else
		return myHero.mana
	end
end

function useCombo()
	if ts.target ~= nil then
		useDFG()
		for i, spell in ipairs(combo) do
			if spell == Q then castQ() end
			if spell == W then castW() end
			if spell == E then castE() end
			if spell == R and (KCConfig.useUlt or isKillStealUlt) and (maxRiftwalkStacks > ultStacks or isKillStealUlt) then castR() end
			if GetDistance(ts.target) <= wRange then myHero:Attack(ts.target) end
		end
		if shouldUseIgnite then
			castIgnite()
		end
	end
end

function castQ()
	if (myHero:CanUseSpell(_Q) == READY) then 
		if ts.target~= nil then
			CastSpell(_Q, ts.target)
		end
	end
end

function castW()
	if ts.target ~= nil and getRange(ts.target) < wRange then
		if (myHero:CanUseSpell(_W) == READY) then
			CastSpell(_W)
		end
	end
end

function castE()
	if ts.target ~= nil and getRange(ts.target) < eRange then
		if (myHero:CanUseSpell(_E) == READY) then
			CastSpell(_E, ts.target)
		end
	end
end

function castR()
	if KCConfig.useUlt or isKillStealUlt then
		if isKillStealUlt and isGapCloser then range = rRange + qRange elseif isKillStalUlt then range = rRange end
		if ts.target ~= nil and getRange(ts.target) <= range then
			if (myHero:CanUseSpell(_R) == READY) then
				CastSpell(_R, ts.target)
			end
		end
	end
end

function castIgnite()
	if ts.target ~= nil and KCConfig.useIgnite and gotIgnite ~= nil and getRange(ts.target) < igniteRange and ts.target.health < getIgniteDamage(ts.target) then
		CastSpell(gotIgnite, ts.target)
	end
end

function getIgniteDamage(enemy)
	if canUseIgnite() then return getDmg("IGNITE",enemy,myHero)
	else return 0 end
end

function canUseIgnite()
	return (gotIgnite ~= nil and myHero:CanUseSpell(gotIgnite) == READY)
end

function hasIgnite()
	if myHero:GetSpellData(SUMMONER_1).name:find("SummonerDot") then return SUMMONER_1
	elseif myHero:GetSpellData(SUMMONER_2).name:find("SummonerDot") then return SUMMONER_2 end
end

function getQMana()
	return myHero:GetSpellData(_Q).mana
end

function getWMana()
	return myHero:GetSpellData(_W).mana
end

function getEMana()
	return myHero:GetSpellData(_E).mana
end

function getRMana()
	local additionalMana = ultStacks * 100
	return myHero:GetSpellData(_R).mana + additionalMana
end

function getDFGSlot()
	return GetInventorySlotItem(3128)
end

function getLichBaneSlot()
	return GetInventorySlotItem(3100)
end

function getSheenSlot()
	return GetInventorySlotItem(3057)
end

function canUseDFG()
	if (getDFGSlot() ~= nil and myHero:CanUseSpell(getDFGSlot()) == READY) then
		return true
	end
	return false
end

function useDFG()
	if ts.target ~= nill and canUseDFG() then
		CastSpell(getDFGSlot(), ts.target)
	end
end


function killSteal()
	local doKill = false
	if KCConfig.killSteal then
		if KCConfig.manaOverride then availableMana = myHero.mana end
		if ts.target ~= nil then 
			if ts.target.health < myDamage then -- Target can be killed
				shouldUseIgnite = false -- Ignite is not needed
				doKill = true
			elseif ts.target.health < myDamage + getIgniteDamage(ts.target) and landInIgniteRange then
				shouldUseIgnite = true -- Ignite damage is needed
				doKill = true
			end
			
			if doKill then
				if KCConfig.useUltOverride or KCConfig.useUlt then isKillStealUlt = true end -- We can use our ult
				if KCConfig.useUltNoRange or KCConfig.ultRangeOverride then isKillStealUlt = true end -- We can use our ult
				useCombo()
			end
		end
	end
	
end

function getMaxDamage(enemy)
	local qDamage = getDmg("Q",enemy,myHero)
	local wDamage = getDmg("W",enemy,myHero)
	local eDamage = getDmg("E",enemy,myHero)
	local rDamage = getDmg("R",enemy,myHero) + (ultStacks*70)
	local SheenDamage = (SheenSlot and getDmg("SHEEN",enemy,myHero) or 0)
	local LichBaneDamage = (LichBaneSlot and getDmg("LICHBANE",enemy,myHero) or 0)
	local iDamage = getIgniteDamage(enemy)
	if not willLandInIgniteRange(enemy) then iDamage = 0 end
	return qDamage + eDamage + rDamage + wDamage + LichBaneDamage + SheenDamage + iDamage
end

function getRange(enemy)
	return myHero:GetDistance(enemy)
end

function getDamage(enemy)
	
	local qDamage = getDmg("Q",enemy,myHero)
	local wDamage = getDmg("W",enemy,myHero)
	local eDamage = getDmg("E",enemy,myHero)
	local rDamage = getDmg("R",enemy,myHero) + (ultStacks*70)
	local igniteDamage = getIgniteDamage(enemy)
	local dfgDamage = (getDFGSlot() and getDmg("DFG",enemy,myHero) or 0)
	local Sheendamage = (SheenSlot and getDmg("SHEEN",enemy,myHero) or 0)
	local LichBanedamage = (LichBaneSlot and getDmg("LICHBANE",enemy,myHero) or 0)
	local currentDamage = 0
	local qReady = (myHero:CanUseSpell(_Q) == READY)
	local wReady = (myHero:CanUseSpell(_W) == READY)
	local eReady = (myHero:CanUseSpell(_E) == READY)
	local rReady = (myHero:CanUseSpell(_R) == READY)
	
	if rReady then getCloser = false end
	isKillStealUlt = false
	isGapCloser = false
	landInIgniteRange = false
   
    --  R to close gap then E +Q
    if  rReady and qReady and eReady and (getRMana() + getQMana() + getEMana()) <= availableMana and getRange(enemy) < rRange + eRange and getRange(enemy) > rRange then
		isGapCloser = true
		currentDamage = qDamage + eDamage
		combo = {R,E,Q}
		
	--  R to close gap then E
    elseif  rReady and eReady and (getRMana() + getEMana()) <= availableMana and getRange(enemy) < rRange + eRange and getRange(enemy) > rRange then
		isGapCloser = true
		currentDamage = eDamage
		combo = {R,E}
		
	--  R to close gap then Q
    elseif  rReady and qReady and (getRMana() + getQMana()) <= availableMana and getRange(enemy) > rRange then
		isGapCloser = true
		currentDamage = qDamage
		combo = {R,Q}
		
    -- Full Combo
	elseif qReady and eReady and rReady and (getQMana() + getWMana() + getEMana() + getRMana()) <= availableMana and getRange(enemy) <= rRange then
		currentDamage = qDamage + eDamage + rDamage + wDamage + Sheendamage + Lichbanedamage
		combo = {R, Q, E, W}
		
	-- Ult + E
	elseif  rReady and eReady and (getRMana() + getEMana()) <= availableMana and getRange(enemy) <= rRange then
		currentDamage = rDamage + eDamage
		combo = {R, E}
		
	-- Ult + Q
	elseif  rReady and qReady and (getRMana() + getQMana()) <= availableMana and getRange(enemy) <= rRange then
		currentDamage = rDamage + qDamage
		combo = {R, Q}
		
	-- Q + E
	elseif  qReady and eReady and (getQMana() + getEMana()) <= availableMana and getRange(enemy) < eRange then
		currentDamage = qDamage + eDamage
		combo = {Q,E}
	
	--  E
	elseif  eReady and getEMana() <= availableMana then
		if getRange(enemy) < eRange then
			currentDamage = eDamage
			combo = {E}
		else
			getCloser = true
		end
	
	--  Q
	elseif  qReady and getQMana() <= availableMana and getRange(enemy) <= qRange then
		currentDamage = qDamage
		combo = {Q}
	
	--  W
	elseif  wReady and getWMana() <= availableMana and getRange(enemy) <= wRange then
		currentDamage = wDamage + Sheendamage + Lichbanedamage
		combo = {W}	
	
	--  R
	elseif  rReady and getRMana() <= availableMana and getRange(enemy) <= rRange then
		currentDamage = rDamage
		combo = {R}
	else
		currentDamage = 0
		combo = {}
		
	end
	
	-- Can we use DFG?
	if canUseDFG() then currentDamage = currentDamage + dfgDamage end
	
	-- Will the selected combo leave us in range to use Ignite and it's enabled/ready? Then add to combo
	if gotIgnite ~= nil and KCConfig.useIgnite and canUseIgnite() and willLandInIgniteRange(enemy) then landInIgniteRange = true end
	
	return currentDamage
end

function willLandInIgniteRange(enemy)
	if combo[R] and getRange(enemy) <= rRange + igniteRange then
		return true
	elseif getRange(enemy) <= igniteRange then
		return true
	else
		return false
	end
end

function OnDraw()
	if KCConfig.drawcircles and not myHero.dead then
		DrawCircle(myHero.x, myHero.y, myHero.z, range, 0x19A712)
		if ts.target ~= nil then
			for j=0, 10 do
				DrawCircle(ts.target.x, ts.target.y, ts.target.z, 40 + j*1.5, 0x00FF00)
			end
		end
	end
	doDrawText()
end

function getDrawText(enemy)
	local killText = KCConfig.killSteal and "KILLSTEAL!" or "DESTROY!"
	if  enemy.team ~= myHero.team and ValidTarget(enemy) and getRange(enemy) < 3000 then
		local igniteDamage = getIgniteDamage(enemy)
		local currentDamage = getDamage(enemy)		
		if enemy.health < currentDamage then return killText
		elseif enemy.health < currentDamage + igniteDamage and willLandInIgniteRange(enemy) then return killText
		elseif willLandInIgniteRange(enemy) and enemy.health - (currentDamage + igniteDamage) < showEnemyHealthAt then return tostring(math.floor((enemy.health - (currentDamage + igniteDamage))+0.5))
		elseif enemy.health - currentDamage < showEnemyHealthAt then return tostring(math.floor((enemy.health - currentDamage)+0.5))
		elseif enemy.health < getMaxDamage(enemy) then return "Wait for cooldowns!"
		else return nil end
	else return nil end
end

function doDrawText()
	if KCConfig.drawtext and not myHero.dead then
		for i=1, heroManager.iCount do
			local drawText = getDrawText(heroManager:GetHero(i))
			if drawText ~= nil then
				PrintFloatText(heroManager:GetHero(i),0,drawText)
			end
		end
	end
end

function stringToBool(key)
	if key == "Yes" or key == "yes" then return true
	elseif key == "No" or key == "no" then return false
	else return true
	end
end

function OnWndMsg(msg,key)
	if key == ULTK and msg == KEY_DOWN then
		timeulti = GetTickCount()
		timeulti2 = GetTickCount()
	end
	--SC__OnWndMsg(msg,key)
end

function OnSendChat(msg)
	TargetSelector__OnSendChat(msg)
	ts:OnSendChat(msg, "pri")
end

function getDamage(enemy)
	
	local qDamage = getDmg("Q",enemy,myHero)
	local wDamage = getDmg("W",enemy,myHero)
	local eDamage = getDmg("E",enemy,myHero)
	local rDamage = getDmg("R",enemy,myHero) + (ultStacks*70)
	local igniteDamage = getIgniteDamage(enemy)
	local dfgDamage = (getDFGSlot() and getDmg("DFG",enemy,myHero) or 0)
	local SheenDamage = (SheenSlot and getDmg("SHEEN",enemy,myHero) or 0)
	local LichBaneDamage = (LichBaneSlot and getDmg("LICHBANE",enemy,myHero) or 0)
	local currentDamage = 0
	local qReady = (myHero:CanUseSpell(_Q) == READY)
	local wReady = (myHero:CanUseSpell(_W) == READY)
	local eReady = (myHero:CanUseSpell(_E) == READY)
	local rReady = (myHero:CanUseSpell(_R) == READY)
	
	if rReady then getCloser = false end
	isKillStealUlt = false
	isGapCloser = false
	landInIgniteRange = false
   
    --  R to close gap then E +Q
    if  rReady and qReady and eReady and (getRMana() + getQMana() + getEMana()) <= availableMana and getRange(enemy) < rRange + eRange and getRange(enemy) > rRange then
		isGapCloser = true
		currentDamage = qDamage + eDamage
		combo = {R,E,Q}
		
	--  R to close gap then E
    elseif  rReady and eReady and (getRMana() + getEMana()) <= availableMana and getRange(enemy) < rRange + eRange and getRange(enemy) > rRange then
		isGapCloser = true
		currentDamage = eDamage
		combo = {R,E}
		
	--  R to close gap then Q
    elseif  rReady and qReady and (getRMana() + getQMana()) <= availableMana and getRange(enemy) > rRange then
		isGapCloser = true
		currentDamage = qDamage
		combo = {R,Q}
		
    -- Full Combo
	elseif qReady and eReady and rReady and (getQMana() + getEMana() + getWMana() + getRMana()) <= availableMana and getRange(enemy) <= rRange then
		currentDamage = qDamage + eDamage + rDamage + wDamage + LichBaneDamage + SheenDamage
		combo = {R, Q, E}
		
	-- Ult + E
	elseif  rReady and eReady and (getRMana() + getEMana()) <= availableMana and getRange(enemy) <= rRange then
		currentDamage = rDamage + eDamage
		combo = {R, E}
		
	-- Ult + Q
	elseif  rReady and qReady and (getRMana() + getQMana()) <= availableMana and getRange(enemy) <= rRange then
		currentDamage = rDamage + qDamage
		combo = {R, Q}
		
	-- Q + E
	elseif  qReady and eReady and (getQMana() + getEMana()) <= availableMana and getRange(enemy) < eRange then
		currentDamage = qDamage + eDamage
		combo = {Q,E}
	
	--  E
	elseif  eReady and getEMana() <= availableMana then
		if getRange(enemy) < eRange then
			currentDamage = eDamage
			combo = {E}
		else
			getCloser = true
		end
	
	--  Q
	elseif  qReady and getQMana() <= availableMana and getRange(enemy) <= qRange then
		currentDamage = qDamage
		combo = {Q}
	
	--  W
	elseif  wReady and getWMana() <= availableMana and getRange(enemy) <= wRange then
		currentDamage = wDamage + LichBaneDamage + SheenDamage
		combo = {W}	
	
	--  R
	elseif  rReady and getRMana() <= availableMana and getRange(enemy) <= rRange then
		currentDamage = rDamage
		combo = {R}
	else
		currentDamage = 0
		combo = {}
		
	end
	
	-- Can we use DFG?
	if canUseDFG() then currentDamage = currentDamage + dfgDamage end
	
	-- Will the selected combo leave us in range to use Ignite and it's enabled/ready? Then add to combo
	if gotIgnite ~= nil and KCConfig.useIgnite and canUseIgnite() and willLandInIgniteRange(enemy) then landInIgniteRange = true end
	
	return currentDamage
end

function willLandInIgniteRange(enemy)
	if combo[R] and getRange(enemy) <= rRange + igniteRange then
		return true
	elseif getRange(enemy) <= igniteRange then
		return true
	else
		return false
	end
end

function OnDraw()
	if KCConfig.drawcircles and not myHero.dead then
		DrawCircle(myHero.x, myHero.y, myHero.z, range, 0x19A712)
		if ts.target ~= nil then
			for j=0, 10 do
				DrawCircle(ts.target.x, ts.target.y, ts.target.z, 40 + j*1.5, 0x00FF00)
			end
		end
	end
	doDrawText()
end

function getDrawText(enemy)
	local killText = KCConfig.killSteal and "KILLSTEAL!" or "DESTROY!"
	if  enemy.team ~= myHero.team and ValidTarget(enemy) and getRange(enemy) < 3000 then
		local igniteDamage = getIgniteDamage(enemy)
		local currentDamage = getDamage(enemy)			
		if enemy.health < currentDamage then return killText
		elseif enemy.health < currentDamage + igniteDamage and willLandInIgniteRange(enemy) then return killText
		elseif willLandInIgniteRange(enemy) and enemy.health - (currentDamage + igniteDamage) < showEnemyHealthAt then return tostring(math.floor((enemy.health - (currentDamage + igniteDamage))+0.5))
		elseif enemy.health - currentDamage < showEnemyHealthAt then return tostring(math.floor((enemy.health - currentDamage)+0.5))
		elseif enemy.health < getMaxDamage(enemy) then return "Wait for cooldowns!"
		else return nil end
	else return nil end
end

function doDrawText()
	if KCConfig.drawtext and not myHero.dead then
		for i=1, heroManager.iCount do
			local drawText = getDrawText(heroManager:GetHero(i))
			if drawText ~= nil then
				PrintFloatText(heroManager:GetHero(i),0,drawText)
			end
		end
	end
end

function stringToBool(key)
	if key == "Yes" or key == "yes" then return true
	elseif key == "No" or key == "no" then return false
	else return true
	end
end

function OnWndMsg(msg,key)
	if key == ULTK and msg == KEY_DOWN then
		timeulti = GetTickCount()
		timeulti2 = GetTickCount()
	end
end

function OnSendChat(msg)
	ts:OnSendChat(msg, "pri")
end

PrintChat(" >> Sida's Kassadin Loaded")