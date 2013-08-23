--[[ Sida's Auto Carry Plugin: Twitch ]]--

AutoCarry.PluginMenu:addParam("UseE", "Auto Expunge", SCRIPT_PARAM_ONOFF, true)                               
AutoCarry.PluginMenu:addParam("At6", "Expunge at 6 stacks", SCRIPT_PARAM_ONOFF, true)                               
AutoCarry.PluginMenu:addParam("KillSteal", "Expunge for kills", SCRIPT_PARAM_ONOFF, true)                                           
AutoCarry.PluginMenu:addParam("Draw", "Draw Poison Circles", SCRIPT_PARAM_ONOFF, true)                                           

function PluginOnLoad()
	for _, enemy in pairs(AutoCarry.EnemyTable) do
		enemy.PoisonStacks = 0
		enemy.LastPoison = 0
	end
end

function PluginOnTick()
	for _, enemy in pairs(AutoCarry.EnemyTable) do
		if enemy.PoisonStacks > 0 and GetTickCount() > enemy.LastPoison + 6500 then
			enemy.PoisonStacks = 0
		elseif enemy.PoisonStacks > 0 then
			if ValidTarget(enemy, 1200) and AutoCarry.PluginMenu.At6 and enemy.PoisonStacks == 6 then
				CastSpell(_E)
			elseif ValidTarget(enemy, 1200) and AutoCarry.PluginMenu.KillSteal then
				if enemy.health < GetDamage(enemy) then
					CastSpell(_E)
				end
			end
		end
	end
end

function PluginOnCreateObj(obj)
	if obj and obj.valid and obj.name:lower():find("twitch_poison_counter") then
		for _, enemy in pairs(AutoCarry.EnemyTable) do
			if GetDistance(enemy, obj) <= 80 then
				enemy.PoisonStacks = GetStacks(obj.name)
				enemy.LastPoison = GetTickCount()
			end
		end
	end
end

function PluginOnDraw()
	if AutoCarry.PluginMenu.Draw then
		for _, enemy in pairs(AutoCarry.EnemyTable) do
			if ValidTarget(enemy, 1200) then
				if enemy.PoisonStacks > 5 then DrawCircle(enemy.x, enemy.y, enemy.z, 180, 0xFFFFFF) end
				if enemy.PoisonStacks > 4 then DrawCircle(enemy.x, enemy.y, enemy.z, 160, 0xFFFFFF) end
				if enemy.PoisonStacks > 3 then DrawCircle(enemy.x, enemy.y, enemy.z, 140, 0xFFFFFF) end
				if enemy.PoisonStacks > 2 then DrawCircle(enemy.x, enemy.y, enemy.z, 120, 0xFFFFFF) end
				if enemy.PoisonStacks > 1 then DrawCircle(enemy.x, enemy.y, enemy.z, 100, 0xFFFFFF) end
			end
		end
	end
end

function GetDamage(enemy)
    local baseDamage = GetSpellData(_E).level > 0 and (GetSpellData(_E).level * 15) + 5 or 0
    local stackDamage = enemy.PoisonStacks > 0 and (enemy.PoisonStacks * 5) + 10 + (myHero.ap * (0.2 * enemy.PoisonStacks)) + (myHero.addDamage * (0.25 * enemy.PoisonStacks)) or 0
    local trueDamage = (baseDamage+stackDamage)*(100/(100+enemy.armor))
    return trueDamage
end

function GetStacks(str)
	if str:lower():find("twitch_poison_counter_01.troy") then return 1
	elseif str:lower():find("twitch_poison_counter_02.troy") then return 2
	elseif str:lower():find("twitch_poison_counter_03.troy") then return 3
	elseif str:lower():find("twitch_poison_counter_04.troy") then return 4
	elseif str:lower():find("twitch_poison_counter_05.troy") then return 5
	elseif str:lower():find("twitch_poison_counter_06.troy") then return 6
	end
end