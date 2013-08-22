--[[ Sida's Auto Carry Plugin: Kog'Maw ]]--

local spellR = {spellKey = _R, range = 1700, speed = 10, delay = 1000, width = 200, minions = false }

AutoCarry.PluginMenu:addParam("UseR", "Use Ult", SCRIPT_PARAM_ONOFF, true)                
AutoCarry.PluginMenu:addParam("Max6", "Max Stacks At 6", SCRIPT_PARAM_SLICE, 2, 0, 6, 0)                 
AutoCarry.PluginMenu:addParam("Max12", "Max Stacks At 12", SCRIPT_PARAM_SLICE, 3, 0, 6, 0)                
AutoCarry.PluginMenu:addParam("Max18", "Max Stacks At 18", SCRIPT_PARAM_SLICE, 4, 0, 6, 0)                
AutoCarry.PluginMenu:addParam("MinMana", "Minimum Mana % After Cast", SCRIPT_PARAM_SLICE, 40, 0, 100, 0)     
AutoCarry.PluginMenu:addParam("KillSteal", "Override For Killsteal", SCRIPT_PARAM_ONOFF, true)            

local stacks, timer = 0, 0

function PluginOnTick()
	AutoCarry.SkillsCrosshair.range = GetRRange()
	if GetTickCount() > timer + 6500 then stacks = 0 end
	KillSteal()
	
	if ValidTarget(AutoCarry.GetAttackTarget(), GetRRange()) and (AutoCarry.MainMenu.AutoCarry or AutoCarry.MainMenu.MixedMode) then
		if (myHero.level > 5 and myHero.level < 12 and stacks < AutoCarry.PluginMenu.Max6)
		or (myHero.level > 11 and myHero.level < 18 and stacks < AutoCarry.PluginMenu.Max12)
		or (myHero.level > 17 and stacks < AutoCarry.PluginMenu.Max18) then
			if myHero.mana - GetMana() > (myHero.maxMana / 100) * AutoCarry.PluginMenu.MinMana then
				AutoCarry.CastSkillshot(spellR, AutoCarry.GetAttackTarget())
			end
		end
	end
end

function PluginOnProcessSpell(unit, spell)
	if unit.isMe and spell.name:lower():find("kogmawlivingartillery") then
		stacks = stacks + 1
		timer = GetTickCount()
	end
end

function GetMana()
	local mana = 40 + (40 * stacks)
	return mana < 401 and mana or 400
end

function GetRRange()
	if myHero:GetSpellData(_R).level == 1 then
		return 1400
	elseif myHero:GetSpellData(_R).level == 2 then
		return 1700
	elseif myHero:GetSpellData(_R).level == 3 then
		return 2200
	end
end

function KillSteal()
	local RRange = GetRRange()
	for _, enemy in pairs(AutoCarry.EnemyTable) do
		if ValidTarget(enemy, RRange) then
			if enemy.health < getDmg("R", enemy, myHero) then
				AutoCarry.CastSkillshot(spellR, enemy)
			end
		end
	end
end