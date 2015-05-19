if myHero.charName ~= "Cassiopeia" then return end

-- [[ Sida's Cass v1.0 ]] --
local qPred
local wPred
local ts
local enemies = {}
local enemyMinions
local disableMovement = false
local lastQ = 0

function OnLoad()
	if VIP_USER then
		qPred = TargetPredictionVIP(850, 2000, 0.6)
		wPred = TargetPredictionVIP(850, 2000, 0.3)
	end
	CassConfig = scriptConfig("Sida's Cass", "sidascass")
	CassConfig:addParam("Combo", "Combo", SCRIPT_PARAM_ONKEYDOWN, false, 219)
	CassConfig:addParam("Harass", "Harass", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("D"))
	CassConfig:addParam("Farm", "Farm", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("A"))
	CassConfig:addParam("Tear", "Stack Tear With Q", SCRIPT_PARAM_ONKEYTOGGLE, false, string.byte("C"))
	CassConfig:addParam("Spam", "Auto E Poisoned Targets", SCRIPT_PARAM_ONOFF, true)
	CassConfig:addParam("KillSteal", "Killsteal with E", SCRIPT_PARAM_ONOFF, true)
	CassConfig:addParam("Movement", "Move To Mouse", SCRIPT_PARAM_ONOFF, true)
	CassConfig:addParam("sep", "-- Farming --", SCRIPT_PARAM_INFO, "")
	CassConfig:addParam("FarmQ", "Farm: Q on most minions", SCRIPT_PARAM_ONOFF, true)
	CassConfig:addParam("FarmW", "Farm: W if > 6 minions", SCRIPT_PARAM_ONOFF, true)
	CassConfig:addParam("FarmE", "Farm: E for last hit on poisoned minion", SCRIPT_PARAM_ONOFF, true)
	CassConfig:addParam("FarmAA", "Farm: AA for last hits", SCRIPT_PARAM_ONOFF, true)
	ts = TargetSelector(TARGET_LESS_CAST_PRIORITY, 850, DAMAGE_MAGIC)
	ts.name = "Cass"
	CassConfig:addTS(ts)
	enemies = GetEnemyHeroes()
	DoPriority()
	enemyMinions = minionManager(MINION_ENEMY, 850, myHero, MINION_SORT_HEALTH_ASC)
end

function OnTick()
	ts:update()
	enemyMinions:update()
	if CassConfig.Combo then Combo() end
	if CassConfig.Harass then Harass() end
	if CassConfig.KillSteal or CassConfig.Spam then AutoE() end
	if CassConfig.Farm then Farm() end
	if CassConfig.Tear then Tear() end
	if CassConfig.Movement and (CassConfig.Combo or CassConfig.Harass or (CassConfig.Farm and not disableMovement)) then myHero:MoveTo(mousePos.x, mousePos.z) end
end


function OnDraw()
	DrawCircle(myHero.x, myHero.y, myHero.z, 850, 0xFFFFFF)
end

function Harass()
	if ValidTarget(ts.target, 850) then
		local predPos = GetQPrediction()
		if predPos then
			CastSpell(_Q, predPos.x, predPos.z)
		end
	end
end

function Combo()
	if ValidTarget(ts.target, 850) then
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

function Tear()
	if GetDistance(mousePos) <= 850 then
		CastSpell(_Q, mousePos.x, mousePos.z)	
	else
		CastSpell(_Q, myHero.x, myHero.z)
	end
end

function Farm()
	if CassConfig.FarmQ then FarmQ() end
	if CassConfig.FarmW then FarmW() end
	if CassConfig.FarmE then FarmE() end
	if CassConfig.FarmAA then FarmAA() end
end

function FarmQ()
	local pos = GetMEC(75, 850, nil, false)
	if pos then
		CastSpell(_Q, pos.center.x, pos.center.z)
	elseif enemyMinions.objects[1] ~= nil and enemyMinions.objects[1] and enemyMinions.objects[1].health > myHero:CalcDamage(enemyMinions.objects[1], myHero.totalDamage) then
		CastSpell(_Q, enemyMinions.objects[1].x, enemyMinions.objects[1].z)
	end
end

function FarmW()
	if enemyMinions.iCount > 6 then
		pos = GetMEC(200, 850, nil, true)
		if pos then
			CastSpell(_W, pos.center.x, pos.center.z)
		end
	end
end

function FarmE()
	if not disableMovement and enemyMinions.objects[1] and enemyMinions.objects[1].health <= getDmg("E", enemyMinions.objects[1], myHero) and TargetPoisoned(enemyMinions.objects[1])  then
		CastSpell(_E, enemyMinions.objects[1])
	end
end

function FarmAA()
	if enemyMinions.objects[1] and enemyMinions.objects[1].health < myHero:CalcDamage(enemyMinions.objects[1], myHero.totalDamage) then 
		disableMovement = true
		myHero:Attack(enemyMinions.objects[1])
	else
		disableMovement = false
	end
end

function TargetPoisoned(target)
	if not target then return end
	for i = 1, target.buffCount do
		local tBuff = target:getBuff(i)
		if BuffIsValid(tBuff) and tBuff.name:lower():find("poison") then
			return true
		end
    end
    return false
end

function AutoE()
	if ValidTarget(ts.target, 700) then
		if (CassConfig.Spam and TargetPoisoned(ts.target)) or (CassConfig.KillSteal and getDmg("E", ts.target, myHero) > ts.target.health) then
			CastSpell(_E, ts.target)
		end
	else
		for _, enemy in pairs(enemies) do
			if ValidTarget(enemy, 700) then
				if (CassConfig.Spam and TargetPoisoned(enemy)) or (CassConfig.KillSteal and getDmg("E", enemy, myHero) > enemy.health) then
					CastSpell(_E, enemy)
				end
			end
		end
	end
end

function GetQPrediction()
	if not VIP_USER then
		return GetPredictionPos(ts.target, 600)
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

class'MEC'
function MEC:__init(points)
    self.circle = Circle()
    self.points = {}
    if points then
        self:SetPoints(points)
    end
end

function MEC:SetPoints(points)
    self.points = {}
    for _, p in ipairs(points) do
        table.insert(self.points, Vector(p))
    end
end

function MEC:HalfHull(left, right, pointTable, factor)
    local input = pointTable
    table.insert(input, right)
    local half = {}
    table.insert(half, left)
    for _, p in ipairs(input) do
        table.insert(half, p)
        while #half >= 3 do
            local dir = factor * VectorDirection(half[(#half + 1) - 3], half[(#half + 1) - 1], half[(#half + 1) - 2])
            if dir <= 0 then
                table.remove(half, #half - 1)
            else
                break
            end
        end
    end
    return half
end

function MEC:ConvexHull()
    local left, right = self.points[1], self.points[#self.points]
    local upper, lower, ret = {}, {}, {}
    for i = 2, #self.points - 1 do
        if VectorType(self.points[i]) == false then PrintChat("self.points[i]") end
        table.insert((VectorDirection(left, right, self.points[i]) < 0 and upper or lower), self.points[i])
    end
    local upperHull = self:HalfHull(left, right, upper, -1)
    local lowerHull = self:HalfHull(left, right, lower, 1)
    local unique = {}
    for _, p in ipairs(upperHull) do
        unique["x" .. p.x .. "z" .. p.z] = p
    end
    for _, p in ipairs(lowerHull) do
        unique["x" .. p.x .. "z" .. p.z] = p
    end
    for _, p in pairs(unique) do
        table.insert(ret, p)
    end
    return ret
end

function MEC:Compute()
    if #self.points == 0 then return nil end
    if #self.points == 1 then
        self.circle.center = self.points[1]
        self.circle.radius = 0
        self.circle.radiusPoint = self.points[1]
    elseif #self.points == 2 then
        local a = self.points
        self.circle.center = a[1]:center(a[2])
        self.circle.radius = a[1]:dist(self.circle.center)
        self.circle.radiusPoint = a[1]
    else
        local a = self:ConvexHull()
        local point_a = a[1]
        local point_b
        local point_c = a[2]
        if not point_c then
            self.circle.center = point_a
            self.circle.radius = 0
            self.circle.radiusPoint = point_a
            return self.circle
        end
        while true do
            point_b = nil
            local best_theta = 180.0
            for _, point in ipairs(self.points) do
                if (not point == point_a) and (not point == point_c) then
                    local theta_abc = point:angleBetween(point_a, point_c)
                    if theta_abc < best_theta then
                        point_b = point
                        best_theta = theta_abc
                    end
                end
            end
            if best_theta >= 90.0 or (not point_b) then
                self.circle.center = point_a:center(point_c)
                self.circle.radius = point_a:dist(self.circle.center)
                self.circle.radiusPoint = point_a
                return self.circle
            end
            local ang_bca = point_c:angleBetween(point_b, point_a)
            local ang_cab = point_a:angleBetween(point_c, point_b)
            if ang_bca > 90.0 then
                point_c = point_b
            elseif ang_cab <= 90.0 then
                break
            else
                point_a = point_b
            end
        end
        local ch1 = (point_b - point_a) * 0.5
        local ch2 = (point_c - point_a) * 0.5
        local n1 = ch1:perpendicular2()
        local n2 = ch2:perpendicular2()
        ch1 = point_a + ch1
        ch2 = point_a + ch2
        self.circle.center = VectorIntersection(ch1, n1, ch2, n2)
        self.circle.radius = self.circle.center:dist(point_a)
        self.circle.radiusPoint = point_a
    end
    return self.circle
end

function GetMEC(radius, range, target, isW)
    assert(type(radius) == "number" and type(range) == "number" and (target == nil or target.team ~= nil), "GetMEC: wrong argument types (expected <number>, <number>, <object> or nil)")
    local points = {}
    for _, object in pairs(enemyMinions.objects) do
        if (target == nil and ValidTarget(object, (range + radius))) or (target and ValidTarget(object, (range + radius), (target.team ~= player.team)) and (ValidTargetNear(object, radius * 2, target) or object.networkID == target.networkID)) then
            table.insert(points, Vector(object))
        end
    end
    return _CalcSpellPosForGroup(radius, range, points, isW)
end

function _CalcSpellPosForGroup(radius, range, points, isW)
    if #points == 0 then
        return nil
	elseif #points < 6 and isW then
		return nil
    elseif #points == 1 then
        return Circle(Vector(points[1]))
    end
    local mec = MEC()
    local combos = {}
    for j = #points, 2, -1 do
        local spellPos
        combos[j] = {}
        _CalcCombos(j, points, combos[j])
        for _, v in ipairs(combos[j]) do
            mec:SetPoints(v)
            local c = mec:Compute()
            if c ~= nil and c.radius <= radius and c.center:dist(player) <= range and (spellPos == nil or c.radius < spellPos.radius) then
                spellPos = Circle(c.center, c.radius)
            end
        end
        if spellPos ~= nil then return spellPos end
    end
end

function _CalcCombos(comboSize, targetsTable, comboTableToFill, comboString, index_number)
    local comboString = comboString or ""
    local index_number = index_number or 1
    if string.len(comboString) == comboSize then
        local b = {}
        for i = 1, string.len(comboString), 1 do
            local ai = tonumber(string.sub(comboString, i, i))
            table.insert(b, targetsTable[ai])
        end
        return table.insert(comboTableToFill, b)
    end
    for i = index_number, #targetsTable, 1 do
        _CalcCombos(comboSize, targetsTable, comboTableToFill, comboString .. i, i + 1)
    end
end

class'Circle'
function Circle:__init(center, radius)
    assert((VectorType(center) or center == nil) and (type(radius) == "number" or radius == nil), "Circle: wrong argument types (expected <Vector> or nil, <number> or nil)")
    self.center = Vector(center) or Vector()
    self.radius = radius or 0
end

function Circle:Contains(v)
    assert(VectorType(v), "Contains: wrong argument types (expected <Vector>)")
    return math.close(self.center:dist(v), self.radius)
end

function Circle:__tostring()
    return "{center: " .. tostring(self.center) .. ", radius: " .. tostring(self.radius) .. "}"
end
