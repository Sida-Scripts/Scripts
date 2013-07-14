if myHero.charName ~= "Riven" then return end

--[[ Sida's Riven v1.0 ]] --

local lastQ = 0
local enemies = {}
local disableMovement = false
local lastAttack = 0
local qCount = 0
local rCast = 0
local enemyMinions
local tick, delay = 0, 400

function OnLoad()
	RivenConfig = scriptConfig("Sida's Riven", "sidasriven")
	RivenConfig:addParam("Combo", "Combo", SCRIPT_PARAM_ONKEYDOWN, false, 219)
	RivenConfig:addParam("Harass", "Harass", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("D"))
	RivenConfig:addParam("Farm", "Farm", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("A"))
	RivenConfig:addParam("Killsteal", "Killsteal With Ult", SCRIPT_PARAM_ONOFF, true)
	RivenConfig:addParam("Ult", "Use Ult In Combo", SCRIPT_PARAM_ONOFF, true)
	RivenConfig:addParam("Movement", "Move To Mouse", SCRIPT_PARAM_ONOFF, true)
	ts = TargetSelector(TARGET_LOW_HP_PRIORITY, 500, DAMAGE_PHYSICAL, true)
	ts.name = "Riven"
	RivenConfig:addTS(ts)
	enemies = GetEnemyHeroes()
	DoPriority()
	enemyMinions = minionManager(MINION_ENEMY, 850, myHero, MINION_SORT_HEALTH_ASC)
end

function OnTick()
	disableMovement = false
	ts:update()
	enemyMinions:update()
	if myHero:CanUseSpell(_Q) ~= READY and GetTickCount() > lastQ + 1000 then qCount = 0 end
	if RivenConfig.Killsteal then Killsteal() end
	if RivenConfig.Harass then Harass() end
	if RivenConfig.Combo then Combo() end
	if RivenConfig.Farm then Farm() end
	if RivenConfig.Movement and ((RivenConfig.Combo or RivenConfig.Harass) and not disableMovement) then myHero:MoveTo(mousePos.x, mousePos.z) end
end

function Harass()
	if ValidTarget(ts.target) then
		if RivenConfig.Ult then 
			if myHero:CanUseSpell(_W) == READY and GetDistance(ts.target) < 250 then
				CastSpell(_W)
			end
		end
		CastSpell(_E, ts.target.x, ts.target.z)
		qWeave()
	end
end

function Combo()
	if ValidTarget(ts.target) then
		if RivenConfig.Ult then
			if GetTickCount() > rCast + 16000 then CastSpell(_R) end
			if GetTickCount() > rCast + 14000 and myHero:CanUseSpell(_R) == READY then
				UltRandom()
			end
		end
		CastSpell(_E, ts.target.x, ts.target.z)
		if myHero:CanUseSpell(_W) == READY and GetDistance(ts.target) < 250 then
			CastSpell(_W)
		end
		qWeave()
	end
end

function qWeave()
	if (myHero:CanUseSpell(_Q) == READY and GetTickCount() > lastQ + 3500) then
		CastSpell(_Q, ts.target.x, ts.target.z)
	elseif myHero:CanUseSpell(_Q) == READY and GetTickCount() > lastQ + 1000 and GetTickCount() < lastAttack + 1000 and GetDistance(ts.target) <= getQRadius() + 260 then
		CastSpell(_Q, ts.target.x, ts.target.z)
	else
		myHero:Attack(ts.target)
		disableMovement = true
	end
end

function UltRandom()
	local lowEnemy = nil
	for _, enemy in pairs(enemies) do
		if lowEnemy == nil and GetDistance(enemy) <= 900 then
			lowEnemy = enemy
		elseif lowEnemy and lowEnemy.health > enemy.health and GetDistance(enemy) <= nil then
			lowEnemy = enemy
		end
		if lowEnemy then
			CastSpell(_R, lowEnemy.x, lowEnemy.z)
		end
	end
end

function Killsteal()
	if myHero:CanUseSpell(_R) == READY then
		for _, enemy in pairs(enemies) do
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

function Farm()
	for _, minion in pairs(enemyMinions.objects) do
		local aDmg = getDmg("AD", minion, myHero)
		if GetDistance(minion) <= (myHero.range + 75) and GetTickCount() > tick + delay and minion.health < aDmg then
			myHero:Attack(minion)
			tick = GetTickCount()	
		end
	end
	if RivenConfig.Movement and GetTickCount() > tick + delay then
		myHero:MoveTo(mousePos.x, mousePos.z)
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

function OnProcessSpell(unit, spell)
	if unit.isMe and spell.name == "RivenTriCleave" then
		lastQ = GetTickCount()
	elseif unit.isMe and spell.name == "RivenFengShuiEngine" then
		rCast = GetTickCount()
	end
end

function OnDraw()
	DrawCircle(myHero.x, myHero.y, myHero.z, 500, 0xFFFFFF)
	if ts.target then
		DrawCircle(ts.target.x, ts.target.y, ts.target.z, 150, 0xFF00FF00)
		DrawCircle(ts.target.x, ts.target.y, ts.target.z, 151, 0xFF00FF00)
		DrawCircle(ts.target.x, ts.target.y, ts.target.z, 152, 0xFF00FF00)
		DrawCircle(ts.target.x, ts.target.y, ts.target.z, 153, 0xFF00FF00)
	end
end

 function OnAnimation(unit,animation)    
    if unit.isMe and animation:find("Attack") then 
		lastAttack = GetTickCount()
	elseif unit.isMe and animation:find("Spell1a") then 
		qCount = 1
	elseif unit.isMe and animation:find("Spell1b") then 
		qCount = 2
	elseif unit.isMe and animation:find("Spell1c") then 
		qCount = 3
	end
end

function getHitBoxRadius(target)
    return GetDistance(target.minBBox, target.maxBBox)/2
end

function SetPriority(table, hero, priority)
    for i=1, #table, 1 do
        if hero.charName:find(table[i]) ~= nil then
            TS_SetHeroPriority(priority, hero.charName)
        end
    end
end

function DoPriority()
	local priorityTable = {
    AP = {
        "Ahri", "Akali", "Anivia", "Annie", "Brand", "Cassiopeia", "Diana", "Evelynn", "FiddleSticks", "Fizz", "Gragas", "Heimerdinger", "Karthus",
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
        "Darius", "Elise", "Fiora", "Gangplank", "Garen", "Irelia", "JarvanIV", "Jax", "Khazix", "LeeSin", "Nautilus", "Nocturne", "Olaf", "Poppy",
        "Renekton", "Rengar", "Riven", "Shyvana", "Trundle", "Tryndamere", "Udyr", "Vi", "MonkeyKing", "XinZhao",
    },
	}

    for _, enemy in ipairs(enemies) do
        SetPriority(priorityTable.AD_Carry, enemy, 1)
        SetPriority(priorityTable.AP,       enemy, 2)
        SetPriority(priorityTable.Support,  enemy, 3)
        SetPriority(priorityTable.Bruiser,  enemy, 4)
        SetPriority(priorityTable.Tank,     enemy, 5)
    end
end