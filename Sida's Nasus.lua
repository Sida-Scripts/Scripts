--[[ Sida's Nasus ]]--

if myHero.charName ~= "Nasus" then return end

local ts = TargetSelector(TARGET_LOW_HP, 725, DAMAGE_PHYSICAL, false)
local delay = 400
local tick = 0
Config = scriptConfig("Sida's Nasus", "sidasnasus")
Config:addParam("Combo", "Combo", SCRIPT_PARAM_ONKEYDOWN, false, 32)
Config:addParam("Harass", "Harass", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("X"))
Config:addParam("Farm", "Farm", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("C"))
Config:addParam("Movement", "Move To Mouse", SCRIPT_PARAM_ONOFF, true)
Config:addParam("Draw", "Draw Wither + Target Circles", SCRIPT_PARAM_ONOFF, true)
Config:addTS(ts)
enemyMinions = minionManager(MINION_ENEMY, 600, player, MINION_SORT_HEALTH_ASC)
PrintChat("Sida's Nasus Loaded")

function OnTick()
	ts:update()
	enemyMinions:update()
	if ts.target then
		if Config.Combo then combo() end
		if Config.Harass then harass() end
	end
	if Config.Farm then farm() end
	if ts.target == nil and Config.Movement and (Config.Combo or Config.Harass) then myHero:MoveTo(mousePos.x, mousePos.z) end
end

function combo()
	UseItems(ts.target)
	if CanCast(_W) and GetDistance(ts.target) <= 700 then CastSpell(_W, ts.target) end
	if CanCast(_E) and GetDistance(ts.target) <= 650 then 
		local ePred = getPred(10, 500, ts.target)
		if ePred ~= nil then
			CastSpell(_E, ePred.x, ePred.z) 
		end
	end
	if CanCast(_Q) and (GetDistance(ts.target) - getHitBoxRadius(myHero) - getHitBoxRadius(target)) < 50 then CastSpell(_Q) end
	myHero:Attack(ts.target)
end

function harass()
	if CanCast(_Q) and (GetDistance(ts.target) - getHitBoxRadius(myHero) - getHitBoxRadius(ts.target)) < 50 then CastSpell(_Q) end
	myHero:Attack(ts.target)
end

function farm()
	for _, minion in pairs(enemyMinions.objects) do
		local qDmg = getDmg("Q", minion, myHero)
		local aDmg = getDmg("AD", minion, myHero)
		if GetDistance(minion) <= (myHero.range + 75) and GetTickCount() > tick + delay then
			if CanCast(_Q) and minion.health < qDmg then
				CastSpell(_Q, minion)
				myHero:Attack(minion)
				tick = GetTickCount()
			elseif minion.health < aDmg then
				myHero:Attack(minion)
				tick = GetTickCount()
			end		
		end
	end
	if Config.Movement and GetTickCount() > tick + delay then
		myHero:MoveTo(mousePos.x, mousePos.z)
	end
end

function CanCast(Spell)
    return (player:CanUseSpell(Spell) == READY)
end

function OnDraw()
    if Config.Draw and not myHero.dead then
        DrawCircle(myHero.x,myHero.y,myHero.z,700,0xFFFF0000)
		if ts.target then
			DrawCircle(ts.target.x, ts.target.y, ts.target.z, 150, 0xFF00FF00)
			DrawCircle(ts.target.x, ts.target.y, ts.target.z, 151, 0xFF00FF00)
			DrawCircle(ts.target.x, ts.target.y, ts.target.z, 152, 0xFF00FF00)
			DrawCircle(ts.target.x, ts.target.y, ts.target.z, 153, 0xFF00FF00)
		end
    end
end

local items =
	{
		BRK = {id=3153, range = 500, reqTarget = true, slot = nil },
		BWC = {id=3144, range = 400, reqTarget = true, slot = nil },
		DFG = {id=3128, range = 750, reqTarget = true, slot = nil },
		HGB = {id=3146, range = 400, reqTarget = true, slot = nil },
		RSH = {id=3074, range = 350, reqTarget = false, slot = nil},
		STD = {id=3131, range = 350, reqTarget = false, slot = nil},
		TMT = {id=3077, range = 350, reqTarget = false, slot = nil},
		YGB = {id=3142, range = 350, reqTarget = false, slot = nil}
	}
	
function UseItems(target)
	if target == nil then return end
	for _,item in pairs(items) do
		item.slot = GetInventorySlotItem(item.id)
		if item.slot ~= nil then
			if item.reqTarget and GetDistance(target) < item.range then
				CastSpell(item.slot, target)
			elseif not item.reqTarget then
				if (GetDistance(target) - getHitBoxRadius(myHero) - getHitBoxRadius(target)) < 50 then
					CastSpell(item.slot)
				end
			end
		end
	end
end

function getHitBoxRadius(target)
    return GetDistance(ts.target.minBBox, ts.target.maxBBox)/2
end

function getPred(speed, delay, target)
	if target == nil then return nil end
	local travelDuration = (delay + GetDistance(myHero, target)/speed)
	travelDuration = (delay + GetDistance(GetPredictionPos(target, travelDuration))/speed)
	travelDuration = (delay + GetDistance(GetPredictionPos(target, travelDuration))/speed)
	travelDuration = (delay + GetDistance(GetPredictionPos(target, travelDuration))/speed) 	
	return GetPredictionPos(target, travelDuration)
end