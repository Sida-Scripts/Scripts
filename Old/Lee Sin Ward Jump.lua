local castAt, lastW, LastWard = 0,0,0
local ward

function OnWndMsg(msg, key)
	if key == string.byte("D") and msg == KEY_DOWN and GetTickCount() > LastWard + 3000 then
		local slot = GetWardSlot()
		if slot and myHero:GetSpellData(_W).name ~= "blindmonkwtwo" then
			if GetDistance(mousePos) <= 600 then
				CastSpell(slot, mousePos.x, mousePos.z)
			else
				local pos = GetFurthest()
				CastSpell(slot, pos.x, pos.z)
			end
			castAt = GetTickCount()
		end
	end
end

function GetWardSlot()
	if myHero:CanUseSpell(_W) ~= READY then return end
	local wards = { 2044, 2043, 2049, 2045, 3154 }
	for _, ward in ipairs(wards) do
		if GetInventorySlotItem(ward) and myHero:CanUseSpell(GetInventorySlotItem(ward)) == READY then
			return GetInventorySlotItem(ward)
		end
	end
	return nil
end

function OnCreateObj(obj)
	if obj.name:lower():find("ward") and GetTickCount() < castAt + 1000 and GetTickCount() > lastW + 1000 then		
		LastWard = GetTickCount()
		lastW = GetTickCount()
		ward = obj
	end
end

function OnTick()
	if ward and GetTickCount() < castAt + 1000 and myHero:GetSpellData(_W).name ~= "blindmonkwtwo" then
		CastSpell(_W, ward)
	end
end

function OnProcessSpell(unit, spell)
	if unit.isMe and spell.name:find("BlindMonkWOne") then
		ward = nil
	end
end

function GetFurthest()
	MyPos = Vector(myHero.x, myHero.y, myHero.z)
	MousePos = Vector(mousePos.x, mousePos.y, mousePos.z)
	return MyPos - (MyPos - MousePos):normalized() * 600
end