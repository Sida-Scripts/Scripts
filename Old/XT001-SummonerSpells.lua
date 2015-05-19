-- ###################################################################################################### --
-- #                                                                                                    # --
-- #                                           XT001-Summoner Spells                                    # --
-- #                                                by Sida                                             # --
-- #                         Credit for original scripts 100% to the original authors!!                 # --
-- #                                                                                                    # --
-- ###################################################################################################### --

--[--------- Contains ---------]

-- Auto Ignite - Created by SurfaceS
-- Auto Heal - Created by SurfaceS
-- Auto Exhaust - Created by SurfaceS
-- Auto Barrier - Created by SurfaceS

-- ############################################# BARRIER ################################################

--[[ 		Globals		]]
local barrierCastDelay = 0
local barrierActive = true
local barrierHaveDisplay = true		-- don't display chat
local minValue = 0.15		-- Minimum health ratio for using Barrier
local barrierSlot

--[[ 		Code		]]
local function barrierReady()
	if barrierSlot ~= nil and barrierCastDelay < GetTickCount() and player:CanUseSpell(barrierSlot) == READY then return true end
	return false
end

function BarrierOnLoad()
	--[[            Conditional            ]]
	if string.find(player:GetSpellData(SUMMONER_1).name..player:GetSpellData(SUMMONER_2).name, "SummonerBarrier") ~= nil then
		if player:GetSpellData(SUMMONER_1).name == "SummonerBarrier" then
			barrierSlot = SUMMONER_1
		elseif player:GetSpellData(SUMMONER_2).name == "SummonerBarrier" then
			barrierSlot = SUMMONER_2
		end
		function BarrierOnTick()
			local barrierTick = GetTickCount()
			if barrierActive and barrierReady() and player.health / player.maxHealth < minValue then
				CastSpell(barrierSlot)
				barrierCastDelay = barrierTick + 300
			end
		end
	end
end

-- ############################################# BARRIER ################################################

-- ############################################# HEAL ################################################

--[[ 		Globals		]]
local healCastDelay = 0
local healActive = true
local minValue = 0.15		-- Minimum health ratio for using Barrier
local slot

--[[ 		Code		]]
local function healReady()
	if slot ~= nil and healCastDelay < GetTickCount() and player:CanUseSpell(slot) == READY then return true end
	return false
end

function HealOnLoad()
	--[[            Conditional            ]]
	if string.find(player:GetSpellData(SUMMONER_1).name..player:GetSpellData(SUMMONER_2).name, "SummonerHeal") ~= nil then
		if player:GetSpellData(SUMMONER_1).name == "SummonerHeal" then
			slot = SUMMONER_1
		elseif player:GetSpellData(SUMMONER_2).name == "SummonerHeal" then
			slot = SUMMONER_2
		end
		function HealOnTick()
			local healTick = GetTickCount()
			if healActive and healReady() and player.health / player.maxHealth < minValue then
				CastSpell(slot)
				healCastDelay = healTick + 300
			end
		end
	end
end

-- ############################################# HEAL ################################################

-- ############################################# EXHAUST ################################################

--[[ 		Globals		]]
local autoSummonerExhaust = {
	exhaustCastDelay = 0,
	exhaustActive = false,
	exhaustActiveTick = 0,
	exhaustRange = 550,
	haveDisplay = false,		-- don't display chat
	activeKey = 84,			-- Press key to use autoSummonerExhaust mode (tTt by default)
}
--[[ 		Code		]]
function ExhaustOnLoad()
	--[[            Conditional            ]]
	if string.find(player:GetSpellData(SUMMONER_1).name..player:GetSpellData(SUMMONER_2).name, "SummonerExhaust") ~= nil then
		if player:GetSpellData(SUMMONER_1).name == "SummonerExhaust" then
			autoSummonerExhaust.slot = SUMMONER_1
		elseif player:GetSpellData(SUMMONER_2).name == "SummonerExhaust" then
			autoSummonerExhaust.slot = SUMMONER_2
		end
		function autoSummonerExhaust.ready()
			return autoSummonerExhaust.slot ~= nil and autoSummonerExhaust.exhaustCastDelay < GetTickCount() and player:CanUseSpell(autoSummonerExhaust.slot) == READY
		end
		function ExhaustOnWndMsg(msg,wParam)
				if msg == KEY_DOWN and wParam == autoSummonerExhaust.activeKey and autoSummonerExhaust.ready() then
					if autoSummonerExhaust.exhaustActive == false and autoSummonerExhaust.haveDisplay == false then PrintChat(" >> Auto exhaust forced") end
					autoSummonerExhaust.exhaustActive = true
					autoSummonerExhaust.exhaustActiveTick = GetTickCount() + 1000
				end
			end
		function ExhaustOnTick()
			local exhaustTick = GetTickCount()
			if autoSummonerExhaust.exhaustActive then
				if autoSummonerExhaust.ready() then
					local exhsuatMaxDPShero = nil
					local maxDPS = 0
					for i = 1, heroManager.iCount, 1 do
						local exhaustHero = heroManager:getHero(i)
						if ValidTarget(exhaustHero,autoSummonerExhaust.exhaustRange + 100) then
							local exhaustDps = exhaustHero.totalDamage * exhaustHero.attackSpeed
							if exhsuatMaxDPShero == nil or maxDPS < exhaustDps then maxDPS, exhsuatMaxDPShero = exhaustDps, exhaustHero end
						end
					end
					if exhsuatMaxDPShero ~= nil then
						autoSummonerExhaust.exhaustActive = false
						autoSummonerExhaust.exhaustCastDelay = exhaustTick + 500
						CastSpell(autoSummonerExhaust.slot, exhsuatMaxDPShero)
					end
				end
				if autoSummonerExhaust.exhaustActiveTick < exhaustTick then autoSummonerExhaust.exhaustActive = false end
			end
		end
	else
		autoSummonerExhaust = nil
	end
end


-- ############################################# EXHAUST ################################################

-- ############################################# IGNITE ################################################

--[[ 		Globals		]]

	local autoSummonerDot = {
		igniteRange = 600,
		igniteBaseDamage = 50,
		damagePerLevel = 20,
		castDelay = 0,
		haveDisplay = false,
		activeKey = 249,			-- Press key to use autoSummonerDot mode (space by default)
		toggleKey = 108,		-- Press key to toggle autoSummonerDot mode (F3/F4 by default -> slot)
		forceIgniteKey = 84,	-- Press key to force ignite (tTt by default)
		active = true,
		toggled = true,
		forced = true,
		forcedTick = 0,
	}
--[[ 		Code		]]
	function IgniteOnLoad()
		--[[            Conditional            ]]
		if player == nil then player = GetMyHero() end
		if string.find(player:GetSpellData(SUMMONER_1).name..player:GetSpellData(SUMMONER_2).name, "SummonerDot") ~= nil then
			if player:GetSpellData(SUMMONER_1).name == "SummonerDot" then
				autoSummonerDot.slot = SUMMONER_1
			elseif player:GetSpellData(SUMMONER_2).name == "SummonerDot" then
				autoSummonerDot.slot = SUMMONER_2
				autoSummonerDot.toggleKey = autoSummonerDot.toggleKey + 1
			end
			function autoSummonerDot.ready()
				if autoSummonerDot.slot ~= nil and autoSummonerDot.castDelay < GetTickCount() and player:CanUseSpell(autoSummonerDot.slot) == READY then return true end
				return false
			end
			function autoSummonerDot.autoIgniteIfKill()
				if autoSummonerDot.ready() then
					local damage = autoSummonerDot.igniteBaseDamage + autoSummonerDot.damagePerLevel * player.level
					for i = 1, heroManager.iCount, 1 do
						local hero = heroManager:getHero(i)
						if hero ~= nil and hero.team ~= player.team and not hero.dead and hero.visible and player:GetDistance(hero) < autoSummonerDot.igniteRange and hero.health <= damage then
							return autoSummonerDot.igniteTarget( hero )
						end
					end
				end
				return nil
			end
			function autoSummonerDot.autoIgniteLowestHealth()
				if autoSummonerDot.ready() then
					local minLifeHero = nil
					for i = 1, heroManager.iCount, 1 do
						local hero = heroManager:getHero(i)
						if hero ~= nil and hero.team ~= player.team and not hero.dead and hero.visible and player:GetDistance(hero) <= autoSummonerDot.igniteRange then
							if minLifeHero == nil or hero.health < minLifeHero.health then
								minLifeHero = hero
							end
						end
					end
					if minLifeHero ~= nil then
						return autoSummonerDot.igniteTarget( minLifeHero )
					end
				end
				return nil
			end
			function autoSummonerDot.igniteTarget(target)
				if autoSummonerDot.ready() then
					CastSpell(autoSummonerDot.slot, target)
					autoSummonerDot.castDelay = GetTickCount() + 500
					return target
				end
				return nil
			end
			function IgniteOnTick()
				local tick = GetTickCount()
				if autoSummonerDot.toggled == false then autoSummonerDot.active = IsKeyDown(autoSummonerDot.activeKey) end
				if autoSummonerDot.forced then
					if autoSummonerDot.forcedTick > tick then
						if autoSummonerDot.autoIgniteLowestHealth() ~= nil then autoSummonerDot.forced = false end
					else
						autoSummonerDot.forced = false
					end
				elseif autoSummonerDot.active then
					autoSummonerDot.autoIgniteIfKill()
				end
			end
		else
			autoSummonerDot = nil
		end
	end

-- ############################################# IGNITE ################################################

-- XT001 --
local hasIgnite, hasHeal, hasExhaust, hasBarrier, enabled = false, false, false, false, true

function OnLoad()
	
	if string.find(player:GetSpellData(SUMMONER_1).name..player:GetSpellData(SUMMONER_2).name, "SummonerExhaust") ~= nil then hasExhaust = true end
	if string.find(player:GetSpellData(SUMMONER_1).name..player:GetSpellData(SUMMONER_2).name, "SummonerDot") ~= nil then hasIgnite = true end
	if string.find(player:GetSpellData(SUMMONER_1).name..player:GetSpellData(SUMMONER_2).name, "SummonerHeal") ~= nil then hasHeal = true end
	if string.find(player:GetSpellData(SUMMONER_1).name..player:GetSpellData(SUMMONER_2).name, "SummonerBarrier") ~= nil then hasBarrier = true end

	if hasHeal or hasIgnite or hasExhaust or hasBarrier then KCConfig = scriptConfig("XT001-Summoner Spells", "xt001summonerspells") else enabled = false end
	if hasIgnite then KCConfig:addParam("Ignite", "Enable Auto Ignite", SCRIPT_PARAM_ONOFF, true) end
	if hasHeal then KCConfig:addParam("Heal", "Enable Auto Heal", SCRIPT_PARAM_ONOFF, true) end
	if hasExhaust then KCConfig:addParam("Exhaust", "Enable Auto Exhaust", SCRIPT_PARAM_ONOFF, true) end
	if hasBarrier then KCConfig:addParam("Barrier", "Enable Auto Barrier", SCRIPT_PARAM_ONOFF, true) end
	
	
	if hasIgnite then IgniteOnLoad() end
	if hasHeal then HealOnLoad() end
	if hasExhaust then ExhaustOnLoad() end
	if hasBarrier then BarrierOnLoad() end
end

function OnTick()
	if enabled then
		if KCConfig.Ignite and hasIgnite then
			IgniteOnTick()
		end
		if KCConfig.Heal and hasHeal then
			HealOnTick()
		end
		if KCConfig.Exhaust and hasExhaust then
			ExhaustOnTick()
		end
		if KCConfig.Barrier and hasBarrier then
			BarrierOnTick()
		end
	end
end

function OnDraw()
end

function OnWndMsg(msg,key)
	if enabled then
		if hasExhaust and KCConfig.Exhaust then ExhaustOnWndMsg(msg, key) end
	end
end
