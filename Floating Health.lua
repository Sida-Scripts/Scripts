-- ####### Floating Health by Sida ####### --

local enemyTable = {}

function OnTick()
	if enemyTable ~= nil then
		if #enemyTable <= 0 then
			updateTable()	
		else
			doDraw(getFirst())
		end
	end
end

function getFirst()
	local enemy
	for i, champ in ipairs(enemyTable) do
		enemy = champ
		break
	end
	return enemy
end

function updateTable()
	for i=1, heroManager.iCount do
		local hero = heroManager:GetHero(i)
		if  hero.team ~= myHero.team and not enemyTable[hero] then
			table.insert(enemyTable,hero)
		end
	end
end

function doDraw(enemy)
	local health = tostring(math.floor((enemy.health)+0.5))
	PrintFloatText(enemy,0,health)
	table.remove(enemyTable,1)
end

PrintChat(">> Floating Health Loaded")