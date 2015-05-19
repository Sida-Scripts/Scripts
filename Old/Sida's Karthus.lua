if myHero.charName ~= "Karthus" then return end

--[[ Sida's Karthus v1.0 ]] --

local qPred
local wPred
local enemies = {}
local defile = false
local enemyMinions
local disableMovement = false
local lastQ = 0

function OnLoad()
	if VIP_USER then
		qPred = TargetPredictionVIP(875, 2000, 0.6)
		wPred = TargetPredictionVIP(1000, 2000, 0.4)
	end
	enemies = GetEnemyHeroes()
	KarthConfig = scriptConfig("Sida's Karthus", "sidaskarth")
	KarthConfig:addParam("Combo", "Combo", SCRIPT_PARAM_ONKEYDOWN, false, 32)
	KarthConfig:addParam("Harass", "Harass", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("D"))
	KarthConfig:addParam("Farm", "Farm", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("A"))
	KarthConfig:addParam("Tear", "Stack Tear With Q", SCRIPT_PARAM_ONKEYTOGGLE, false, string.byte("C"))
	KarthConfig:addParam("Spam", "Auto Defile Close Enemies", SCRIPT_PARAM_ONOFF, true)
	KarthConfig:addParam("Movement", "Move To Mouse", SCRIPT_PARAM_ONOFF, true)
	KarthConfig:addParam("sep", "-- Farming --", SCRIPT_PARAM_INFO, "")
	KarthConfig:addParam("FarmQ", "Farm: Last Hit With Q", SCRIPT_PARAM_ONOFF, true)
	KarthConfig:addParam("FarmAA", "Farm: Last Hit With AA", SCRIPT_PARAM_ONOFF, true)
	ts = TargetSelector(TARGET_LESS_CAST_PRIORITY, 1000, DAMAGE_MAGIC)
	ts.name = "Karthus"
	enemyMinions = minionManager(MINION_ENEMY, 850, myHero, MINION_SORT_HEALTH_ASC)
end

function OnTick()
	ts:update()
	enemyMinions:update()
	if KarthConfig.Combo then Combo() end
	if KarthConfig.Harass then Harass() end
	if KarthConfig.Farm then Farm() end
	if KarthConfig.Spam then AutoE() end
	if KarthConfig.Tear then Tear() end
	if KarthConfig.Movement and ((KarthConfig.Farm and not disableMovement) or KarthConfig.Harass or KarthConfig.Combo) then myHero:MoveTo(mousePos.x, mousePos.z) end
end

function OnCreateObj(object)
    if object ~= nil and object.valid and object.name == "Defile_glow.troy" then
        defile = true
    end
end

function OnDeleteObj(object)
    if object ~= nil and object.name == "Defile_glow.troy" then
        defile = false
    end
end

function OnProcessSpell(unit, spell)
	if unit.isMe and spell.name == "LayWaste" then
		lastQ = GetTickCount()
	end
end

function Combo()
	if ValidTarget(ts.target) then
		local predPos = GetWPrediction()
		if predPos then
			CastSpell(_W, predPos.x, predPos.z)
		end
		predPos = GetQPrediction()
		if predPos then
			CastSpell(_Q, predPos.x, predPos.z)
		end
	end
end

function Harass()
	if ValidTarget(ts.target) then
		local predPos = GetQPrediction()
		if predPos then
			CastSpell(_Q, predPos.x, predPos.z)
		end
	end
end

function AutoE()
	for _, enemy in pairs(enemies) do
		if ValidTarget(enemy) and GetDistance(enemy) <= 425 then
			CastSpell(_E)
			return
		end
	end
	if (KarthConfig.Combo or KarthConfig.Harass) and defile then CastSpell(_E) end
end

function Tear()
	if GetTickCount() > lastQ + 2900 and GetDistance(mousePos) <= 875 then
		CastSpell(_Q, mousePos.x, mousePos.z)	
	elseif GetTickCount() > lastQ + 2900 then
		CastSpell(_Q, myHero.x, myHero.z)
	end
end

function Farm()
	local minion = enemyMinions.objects[1]
	if ValidTarget(minion) then
		if KarthConfig.FarmAA and minion.health < myHero:CalcDamage(minion, myHero.totalDamage) then 
			disableMovement = true
			myHero:Attack(minion)
		elseif KarthConfig.FarmQ and getDmg("Q", minion, myHero) / 2 > minion.health then
			CastSpell(_Q, minion.x, minion.z)
			disableMovement = false
		else
			disableMovement = false
		end
	end
end

function GetQPrediction()
	if not VIP_USER then
		local travelDuration = (600 + GetDistance(myHero, ts.target)/2)
		travelDuration = (600 + GetDistance(GetPredictionPos(ts.target, travelDuration))/2)
		travelDuration = (600 + GetDistance(GetPredictionPos(ts.target, travelDuration))/2)
		travelDuration = (600 + GetDistance(GetPredictionPos(ts.target, travelDuration))/2) 	
		return GetPredictionPos(ts.target, travelDuration)
	else
		return qPred:GetPrediction(ts.target)
	end
end

function GetWPrediction()
	if not VIP_USER then
		return GetPredictionPos(ts.target, 300)
	else
		return wPred:GetPrediction(ts.target)
	end
end

function OnDraw()
	DrawCircle(myHero.x, myHero.y, myHero.z, 875, 0xFFFFFF)
end