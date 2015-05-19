local wardNames = {"TrinketTotemLvl1", "TrinketTotemLvl2", "TrinketTotemLvl3", "TrinketTotemLvl3B", "sightward", "VisionWard"}
castAt = 0
local champs = {LeeSin = {_W, "BlindMonkWOne"}, Katarina = {_E}, Jax = {_Q}}
if not champs[myHero.charName] then return end

menu = scriptConfig("Ward Jumper", "wardjumper")
menu:addParam("key", "Hotkey", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("T"))

function OnLoad()
	print("Sida's Ward Jumper Loaded")
	myChamp = champs[myHero.charName]
end

function OnTick()
	if menu.key and myHero:CanUseSpell(myChamp[1]) == READY and (not myChamp[2] or myHero:GetSpellData(myChamp[1]).name == myChamp[2]) then
		local slot = GetWardSlot()
		if slot and os.clock() > castAt + 1 then
			local pos = GetDistance(mousePos) <= 600 and mousePos or GetFurthest()
			CastSpell(slot, pos.x, pos.z)
			castAt = os.clock()
		end
		if myWard then CastSpell(myChamp[1], myWard) myWard = nil end
	end
end

function OnCreateObj(obj)
	if obj.name:lower():find("ward") and obj.team == myHero.team and os.clock() < castAt + 0.5 then	myWard = obj end
end

function GetWardSlot()
	for _, wardName in ipairs(wardNames) do
		for slot = ITEM_1, ITEM_7 do
			if wardName == myHero:GetSpellData(slot).name and myHero:CanUseSpell(slot) == READY then return slot end
		end
	end
end

function GetFurthest()
	MyPos = Vector(myHero.x, myHero.y, myHero.z)
	return MyPos - (MyPos - Vector(mousePos.x, mousePos.y, mousePos.z)):normalized() * 600
end