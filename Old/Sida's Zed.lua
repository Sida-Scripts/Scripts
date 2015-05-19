if myHero.charName ~= "Zed" then return end

--[[ Sida's Zed v1.1 ]] --

local wClone = nil
local rClone = nil
local ts
local RREADY, WREADY, EREADY, QREADY
local delay, qspeed = 235, 1.742
local prediction
local lastW = 0

function OnLoad()
	ZedConfig = scriptConfig("Sida's Zed", "sidaszed")
	ZedConfig:addParam("Combo", "Combo", SCRIPT_PARAM_ONKEYDOWN, false, 32)
    ZedConfig:addParam("Harass", "Harass", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("X"))
	ZedConfig:addParam("AutoE", "Auto E", SCRIPT_PARAM_ONOFF, true)
	ZedConfig:addParam("Movement", "Move To Mouse In Combo", SCRIPT_PARAM_ONOFF, true)
	ZedConfig:addParam("Range", "Draw Range Circles", SCRIPT_PARAM_ONOFF, true)
	ZedConfig:addParam("TargetCircle", "Draw Target Circle", SCRIPT_PARAM_ONOFF, true)
	ts = TargetSelector(TARGET_LOW_HP_PRIORITY, 1190, DAMAGE_PHYSICAL, true)
	ts.name = "Zed"
	ZedConfig:addTS(ts)
end

function OnTick()
	ts:update()
	SetCooldowns()
	if ValidTarget(ts.target) then
		if ZedConfig.AutoE then autoE() end
		prediction = qPred()
		if ZedConfig.Combo then Combo() end
		if ZedConfig.Harass then Harass() end
	end
	
	if ts.target == nil and ZedConfig.Combo and ZedConfig.Movement then
		myHero:MoveTo(mousePos.x, mousePos.z)
	end
end

function OnDraw()
	if ZedConfig.Range then
		DrawCircle(myHero.x, myHero.y, myHero.z, 290, 0xFF00FF00)
		DrawCircle(myHero.x, myHero.y, myHero.z, 550, 0xFFFFFF)
	end
	if ts.target ~= nil and ZedConfig.TargetCircle then
		DrawCircle(ts.target.x, ts.target.y, ts.target.z, 150, 0xFF00FF00)
		DrawCircle(ts.target.x, ts.target.y, ts.target.z, 151, 0xFF00FF00)
		DrawCircle(ts.target.x, ts.target.y, ts.target.z, 152, 0xFF00FF00)
		DrawCircle(ts.target.x, ts.target.y, ts.target.z, 153, 0xFF00FF00)
		GetEnergyDraw()
	end
end

function OnProcessSpell(unit, spell)
	if unit.isMe and spell.name == "ZedShadowDash" then
		lastW = GetTickCount()
	end
end

function Combo()	
	if RREADY then CastSpell(_R, ts.target) end
	if not RREADY or rClone ~= nil then
		if WREADY and ((GetDistance(ts.target) < 700 and HasEnergy()) or (GetDistance(ts.target) > 125 and not RREADY)) then 
			CastSpell(_W, ts.target.x, ts.target.z) 
		end
		if not WREADY or wClone ~= nil then
			if QREADY then 
				if prediction ~= nil and GetDistance(prediction) < 900 then
					CastSpell(_Q, prediction.x, prediction.z)
				end
			end
		end
	end
	UseItems()
	
	if not QREADY and not EREADY then
		local wDist = 0
		local rDist = 0
		if wClone and wClone.valid then wDist = GetDistance(ts.target, wClone) end
		if rClone and rClone.valid then rDist = GetDistance(ts.target, rClone) end	
		if GetDistance(ts.target) > 125 then
			if wDist < rDist and wDist ~= 0 and GetDistance(ts.target) > wDist then
				CastSpell(_W)
			elseif rDist < wDist and rDist ~= 0 and GetDistance(ts.target) > rDist then
				CastSpell(_R)
			end
		end
	end
	
	myHero:Attack(ts.target)
end

function Harass() 
	if prediction ~= nil and (QREADY and WREADY and GetDistance(prediction) < 700) or (QREADY and wClone ~= nil and wClone.valid and GetDistance(prediction, wClone) < 900) then
		if myHero:GetSpellData(_W).name ~= "zedw2" and GetTickCount() > lastW + 1000 and HasEnergy() then 
			CastSpell(_W, ts.target.x, ts.target.z) 
		else
			CastSpell(_Q, prediction.x, prediction.z)
		end
	elseif QREADY and not WREADY and prediction and GetDistance(prediction) < 900 then
		CastSpell(_Q, prediction.x, prediction.z)
	end
end

function autoE() 
	local box = 280
	if GetDistance(ts.target) < box or (wClone ~= nil and wClone.valid and GetDistance(ts.target, wClone) < box) or (rClone ~= nil and rClone.valid and GetDistance(ts.target, rClone) < box) then
		CastSpell(_E)
	else
		for i = 1, heroManager.iCount do
			local enemy = heroManager:getHero(i)
			if ValidTarget(enemy) and GetDistance(enemy) < box or (wClone ~= nil and wClone.valid and GetDistance(enemy, wClone) < box) or (rClone ~= nil and rClone.valid and GetDistance(enemy, rClone) < box) then
				CastSpell(_E)
			end
		end
	end
end

function OnCreateObj(obj)
	if obj.valid and obj.name:find("Zed_Clone_idle.troy") then
		if wClone == nil then
			wClone = obj
		elseif rClone == nil then
			rClone = obj
		end
	end
end

function OnDeleteObj(obj)
	if obj.valid and wClone and obj == wClone then
		wClone = nil
	elseif obj.valid and rClone and obj == rClone then
		rClone = nil
	end
end

function SetCooldowns()
	QREADY = (myHero:CanUseSpell(_Q) == READY)
	WREADY = (myHero:CanUseSpell(_W) == READY)
	EREADY = (myHero:CanUseSpell(_E) == READY)
	RREADY = (myHero:CanUseSpell(_R) == READY)
end

function HasEnergy()
	local qMana = {75, 70, 65, 60, 55}
	local eMana = 50
	
	local qEnergy = qMana[myHero:GetSpellData(_Q).level]
	
	local myEnergy = myHero.mana
	
	if myEnergy < eMana + 50 then
		return false
	else
		return true
	end
end

function GetEnergyDraw()
	local qMana = {75, 70, 65, 60, 55}
	local wMana = {40, 35, 30, 25, 20}
	
	local qEnergy = (myHero:GetSpellData(_W).level > 0 and qMana[myHero:GetSpellData(_Q).level] or 0)
	local wEnergy = (myHero:GetSpellData(_W).level > 0 and wMana[myHero:GetSpellData(_W).level] or 0)
	local eEnergy = 50
	
	if myHero.mana < qEnergy + wEnergy + eEnergy then
		PrintFloatText(ts.target, 0, "Not Enough Energy!")
	else
		PrintFloatText(ts.target, 0, "Enough Energy!")
	end
end

function qPred()
	local travelDuration = (delay + GetDistance(myHero, ts.target)/qspeed)
	travelDuration = (delay + GetDistance(GetPredictionPos(ts.target, travelDuration))/qspeed)
	travelDuration = (delay + GetDistance(GetPredictionPos(ts.target, travelDuration))/qspeed)
	travelDuration = (delay + GetDistance(GetPredictionPos(ts.target, travelDuration))/qspeed) 	
	if ts.target ~= nil then
		return GetPredictionPos(ts.target, travelDuration)
	end
end

function UseItems()
	if GetInventorySlotItem(3153) ~= nil and GetDistance(ts.target) > 300 then 
		CastSpell(GetInventorySlotItem(3153), ts.target) 
	end 	
	if GetInventorySlotItem(3144) ~= nil and GetDistance(ts.target) > 300 then 
		CastSpell(GetInventorySlotItem(3144), ts.target) 
	end 
end
