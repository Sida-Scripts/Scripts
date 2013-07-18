--[[ Sida's Auto Carry Plugin - Riven, by Sida ]]--

--[[
	Combo: Ult (if enabled) > W > E. Will Q between attacks.
	Harass: W > E. Will Q between attacks.
	Killsteal: Killsteal with R.
	Ult Random: If ult is about to run out and hasn't been fired, it'll find the best target and fire at them.

	Always redownload auto carry when using a new plugin, chances are chances were made that the plugin requires.

	Save this script in BoL/Scripts/Common with the name "SidasAutoCarryPlugin - Riven.lua"
]]
VIP_USER = false
local lastQ = 0
local qCount = 0
local rCast = 0
local target
local nextQ = 0
local bAllowQ = true

function PluginOnLoad()
	AutoCarry.PluginMenu:addParam("UseQ", "Use Q at mousepos", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("Q"))
	AutoCarry.PluginMenu:addParam("Combo", "Use Combo With Auto Carry", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("Harass", "Harass With Mixed Mode", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("Killsteal", "Killsteal With Ult", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("Ult", "Use Ult In Combo", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("UltAt", "Enemy Hp % To Use Ult", SCRIPT_PARAM_SLICE, 60, 0, 100, 0)
end

function PluginOnTick()
	AutoCarry.SkillsCrosshair.range = myHero.range + GetDistance(myHero.minBBox) + (getQRadius()*2)
	target = AutoCarry.GetAttackTarget()
	if myHero:CanUseSpell(_Q) ~= READY and GetTickCount() > lastQ + 1000 then qCount = 0 end
	if AutoCarry.PluginMenu.Killsteal then Killsteal() end
	if AutoCarry.PluginMenu.Harass and AutoCarry.MainMenu.MixedMode then Harass() end
	if AutoCarry.PluginMenu.Combo and AutoCarry.MainMenu.AutoCarry then Combo() end
	if AutoCarry.PluginMenu.UseQ then UseQ() end
end

function Harass()
	if ValidTarget(target) then
		if AutoCarry.PluginMenu.Ult then 
			if myHero:CanUseSpell(_W) == READY and GetDistance(target) < 250 then
				CastSpell(_W)
			end
		end
		CastSpell(_E, target.x, target.z)
	end
end

function Combo()
	if ValidTarget(target) then
		if AutoCarry.PluginMenu.Ult then
			if AutoCarry.Orbwalker.target and GetTickCount() > rCast + 16000 then 
				if (target.health / target.maxHealth)*100 < AutoCarry.PluginMenu.UltAt then
					CastSpell(_R) 
				end
			end
			if GetTickCount() > rCast + 14000 and GetTickCount() < rCast + 20000 and myHero:CanUseSpell(_R) == READY then
				UltRandom()
			end
		end
		CastSpell(_E, target.x, target.z)
		if myHero:CanUseSpell(_W) == READY and GetDistance(target) < 250 then
			CastSpell(_W)
		end
		if qCount > 0 and target and not AutoCarry.Orbwalker.target then
			bAllowQ = true
			CastSpell(_Q, target.x, target.z)
		end
	end
end

function UseQ()
	if myHero:CanUseSpell(_Q) == READY then
		bAllowQ = true
		CastSpell(_Q, mousePos.x, mousePos.z)
	elseif VIP_USER then
		bAllowQ = false
	end
end

function UltRandom()
	local lowEnemy = nil
	for _, enemy in pairs(AutoCarry.EnemyTable) do
		if lowEnemy == nil and GetDistance(enemy) <= 900 then
			lowEnemy = enemy
		elseif lowEnemy and lowEnemy.health > enemy.health and GetDistance(enemy) <= 900 then
			lowEnemy = enemy
		end
	end
	if lowEnemy then
		CastSpell(_R, lowEnemy.x, lowEnemy.z)
	end
end

function Killsteal()
	if myHero:CanUseSpell(_R) == READY then
		for _, enemy in pairs(AutoCarry.EnemyTable) do
			if ValidTarget(enemy) and GetDistance(enemy) < 870 and enemy.health < getDmg("R", enemy, myHero) then
				if GetTickCount() < rCast + 16000 and TargetHaveBuff("RivenFengShuiEngine", myHero) then
					CastSpell(_R, enemy.x, enemy.z)
				else
					CastSpell(_R)
				end
			end
		end
	end
end

function getQRadius()
	if TargetHaveBuff("RivenFengShuiEngine", myHero) then
		if qCount == 0 or qCount == 1 or qCount == 3 then 
			return 112.5
		elseif qCount == 2 then
			return 150
		end
	else
		if qCount == 0 or qCount == 1 or qCount == 3 then 
			return 162.5
		elseif qCount == 2 then
			return 200
		end
	end
end

function PluginOnProcessSpell(unit, spell)
	if unit.isMe and spell.name == "RivenTriCleave" then
		lastQ = GetTickCount()
	elseif unit.isMe and spell.name == "RivenFengShuiEngine" then
		rCast = GetTickCount()
	end
end

function OnAttacked()
	if target and GetTickCount() > nextQ then 
		if (AutoCarry.PluginMenu.Harass and AutoCarry.MainMenu.MixedMode) or (AutoCarry.PluginMenu.Combo and AutoCarry.MainMenu.AutoCarry) then
			bAllowQ = true
			CastSpell(_Q, target.x, target.z)
			nextQ = AutoCarry.GetNextAttackTime()
		end
	end
end

 function PluginOnAnimation(unit,animation)    
	if unit.isMe and animation:find("Spell1a") then 
		qCount = 1
	elseif unit.isMe and animation:find("Spell1b") then 
		qCount = 2
	elseif unit.isMe and animation:find("Spell1c") then 
		qCount = 3
	end
end

function PluginOnSendPacket(packet)
	local packet2 = Packet(packet)
	if packet2:get('name') == 'S_CAST' then
		if packet2:get('spellId') == _Q then
			if not bAllowQ then
				packet2:block()
			else
				bAllowQ = false
			end
		end
	end
end