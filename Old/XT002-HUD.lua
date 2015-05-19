-- ###################################################################################################### --
-- #                                                                                                    # --
-- #                                               XT002-HUD                                            # --
-- #                                                by Sida                                             # --
-- #                         Credit for original scripts 100% to the original authors!!                 # --
-- #                                                                                                    # --
-- ###################################################################################################### --

--[--------- Contains ---------]

-- Stun Alert : Created by ikita/eXtragoZ
-- Low Awareness : Created by Ryan, Ported by Manciuszz
-- Simple Minion Marker : Created by Kilua
-- Enemy Tower Range : Created by SurfaceS
-- Hidden Objects : Created by SurfaceS
-- Jungle Display : Created by SurfaceS
-- Champion Ranges : Created by heist, ported by Mistal
-- Ward Prediction : Created by eXtragoZ

-- ############################################# LOW AWARENESS ##############################################

local alertActive = true
local championTable = {}
local playerTimer = {}
local playerDrawer = {}
local player = GetMyHero()
--showErrorsInChat = false
--showErrorTraceInChat = false

nextTick = 0 function LowAwarenessOnTick()   if nextTick > GetTickCount() then return end   nextTick = GetTickCount() + 250 --(100 is the delay) 	
    local tick = GetTickCount()
    if alertActive == true then
        for i = 1, heroManager.iCount, 1 do
        local object = heroManager:getHero(i)
            if object.team ~= player.team and object.dead == false then
                if object.visible == true and player:GetDistance(object) < 2500 then
                    if playerTimer[i] == nil then
                        PrintChat(string.format("<font color='#FF0000'> >> ALERT: %s</font>", object.charName))
                        PingSignal(PING_FALLBACK,object.x,object.y,object.z,2)
                        PingSignal(PING_FALLBACK,object.x,object.y,object.z,2)
                        PingSignal(PING_FALLBACK,object.x,object.y,object.z,2)
                        table.insert(championTable, object )
                        playerDrawer[i] = tick
                    end
                    playerTimer[ i ] = tick
                    if (tick - playerDrawer[i]) > 5000 then
                        for ii, tableObject in ipairs(championTable) do
                            if tableObject.charName == object.charName then
                                table.remove(championTable, ii)
                            end
                        end
                    end
                else
                    if playerTimer[i] ~= nil and (tick - playerTimer[i]) > 10000 then
                        playerTimer[i] = nil
                        for ii, tableObject in ipairs(championTable) do
                            if tableObject.charName == object.charName then
                                table.remove(championTable, ii)
                            end
                        end
                    end
                end
            end
        end
    end
end



function LowAwarenessOnDraw()
    for i,tableObject in ipairs(championTable) do
       if tableObject.visible and tableObject.dead == false and tableObject.team ~= player.team then
			for t = 0, 1 do	
				DrawCircle(tableObject.x, tableObject.y, tableObject.z, 1250 + t*0.25, 0xFFFF0000)
			end
       end
    end
end

-- ############################################# LOW AWARENESS ##############################################

-- ############################################# STUN ALERT ################################################

--[[
Stun Alert v1.4 by eXtragoZ

	Checks the number of CC off-cooldown that could disrupt channels: silences, knockbacks, stuns, and suppression
	
	Features:
		- Sphere marker for champions with CC
		- The sphere is thicker depending on how much CC has the enemy
		- Script will print the number of champions that currently has a CC and the number of CC
		- You can move it with shift + mouse
	
	Types of CC:
		- Hard CC (disrupt the channelling)
			- Airborne
				- Knockback
				- Knockup
				- Pull/Fling
			- Forced Action
				- Charm
				- Fear
				- Flee
				- Taunt
			- Polymorph
			- Silence
			- Stun
			- Suppression
		- Soft CC
			- Blind
			- Entangle
			- Slow
			- Snare
			- Wall
]]
local basicthickness = 10
local radius = 60
local tablex = 550
local tabley = 645
local UIHK = 16 --shift
local moveui = false
--[[		Code		]]
PrintChat(" >> Stun alert v1.4 loaded!")
function StunAlertOnDraw()
	local stunChamps = 0
	local amountCC = 0
	for i=1, heroManager.iCount do
		local target = heroManager:GetHero(i)
		if target.team ~= myHero.team and not target.dead then
			local targetCC = GetTargetCC("HardCC",target)
			if targetCC > 0 then
				stunChamps = stunChamps+1
				amountCC = amountCC+targetCC
				if target.visible then
					thickness = basicthickness*targetCC
					for j=1, thickness do
						local ycircle = (j*(radius/thickness*2)-radius)
						local r = math.sqrt(radius^2-ycircle^2)
						ycircle = ycircle/1.3
						DrawCircle(target.x, target.y+250+ycircle, target.z, r, 0x00FF00)
					end
				end
			end
		end
	end
	if moveui then tablex,tabley = GetCursorPos().x-40,GetCursorPos().y-15 end
	DrawText("Hard CC: "..amountCC, 20, tablex, tabley, 0xFFFFFF00)
	DrawText("CC champions: "..stunChamps, 20, tablex, tabley+15, 0xFFFFFF00)
end
function GetTargetCC(typeCC,target)
	local HardCC, Airborne, Charm, Fear, Taunt, Polymorph, Silence, Stun, Suppression = 0, 0, 0, 0, 0, 0, 0, 0, 0
	local SoftCC, Blind, Entangle, Slow, Snare, Wall = 0, 0, 0, 0, 0, 0
	local targetName = target.charName
	local annieStun = nil
	local QREADY = (target:CanUseSpell(_Q) == 3)
	local WREADY = (target:CanUseSpell(_W) == 3)
	local EREADY = (target:CanUseSpell(_E) == 3)
	local RREADY = (target:CanUseSpell(_R) == 3)
	if targetName == "Ahri" then
		if EREADY then
			HardCC = HardCC+1
			Charm = Charm+1
		end
	elseif targetName == "Akali" then
		if WREADY then
			SoftCC = SoftCC+1
			Slow = Slow+1
		end
	elseif targetName == "Alistar" then
		if QREADY then
			HardCC = HardCC+1
			Airborne = Airborne+1
		end
		if WREADY then
			HardCC = HardCC+1
			Airborne = Airborne+1
		end
	elseif targetName == "Amumu" then
		if QREADY then
			HardCC = HardCC+1
			Stun = Stun+1
		end
		if RREADY then
			SoftCC = SoftCC+1
			Entangle = Entangle+1
		end
	elseif targetName == "Anivia" then
		if QREADY then
			HardCC = HardCC+1
			Stun = Stun+1
			SoftCC = SoftCC+1
			Slow = Slow+1
		end
		if WREADY then
			SoftCC = SoftCC+1
			Wall = Wall+1
		end
		if RREADY then
			SoftCC = SoftCC+1
			Slow = Slow+1
		end
	elseif targetName == "Annie" then
		if annieStun ~= nil and annieStun.valid and target:GetDistance(annieStun) <= 100 then
			HardCC = HardCC+1
			Stun = Stun+1
		end
	elseif targetName == "Ashe" then
		if QREADY then
			SoftCC = SoftCC+1
			Slow = Slow+1
		end
		if RREADY then
			HardCC = HardCC+1
			Stun = Stun+1
			SoftCC = SoftCC+1
			Slow = Slow+1
		end
	elseif targetName == "Blitzcrank" then
		if QREADY then
			HardCC = HardCC+1
			Airborne = Airborne+1
		end
		if EREADY then
			HardCC = HardCC+1
			Airborne = Airborne+1
		end
		if RREADY then
			HardCC = HardCC+1
			Silence = Silence+1
		end
	elseif targetName == "Brand" then
		if QREADY then
			HardCC = HardCC+1
			Stun = Stun+1
		end
	elseif targetName == "Caitlyn" then
		if WREADY then
			SoftCC = SoftCC+1
			Snare = Snare+1
		end
		if EREADY then
			SoftCC = SoftCC+1
			Slow = Slow+1
		end
	elseif targetName == "Cassiopeia" then
		if WREADY then
			SoftCC = SoftCC+1
			Slow = Slow+1
		end
		if RREADY then
			HardCC = HardCC+1
			Stun = Stun+1
			SoftCC = SoftCC+1
			Slow = Slow+1
		end
	elseif targetName == "Chogath" then
		if QREADY then
			HardCC = HardCC+1
			Airborne = Airborne+1
			SoftCC = SoftCC+1
			Slow = Slow+1
		end
		if WREADY then
			HardCC = HardCC+1
			Silence = Silence+1
		end
	elseif targetName == "Darius" then
		if WREADY then
			SoftCC = SoftCC+1
			Slow = Slow+1			
		end
		if EREADY then
			HardCC = HardCC+1
			Airborne = Airborne+1
		end
	elseif targetName == "Diana" then
		if EREADY then
			HardCC = HardCC+1
			Airborne = Airborne+1
			SoftCC = SoftCC+1
			Slow = Slow+1
		end
	elseif targetName == "DrMundo" then
		if QREADY then
			SoftCC = SoftCC+1
			Slow = Slow+1
		end
	elseif targetName == "Draven" then
		if EREADY then
			HardCC = HardCC+1
			Airborne = Airborne+1
			SoftCC = SoftCC+1
			Slow = Slow+1
		end
	elseif targetName == "Elise" then
		if EREADY and target:GetSpellData(_E).name == "EliseHumanE" then
			HardCC = HardCC+1
			Stun = Stun+1
		end
	elseif targetName == "Evelynn" then
		if RREADY then
			SoftCC = SoftCC+1
			Slow = Slow+1			
		end
	elseif targetName == "FiddleSticks" then
		if QREADY then
			HardCC = HardCC+1
			Fear = Fear+1
		end
		if EREADY then
			HardCC = HardCC+1
			Silence = Silence+1
		end
	elseif targetName == "Fizz" then
		if EREADY then
			SoftCC = SoftCC+1
			Slow = Slow+1	
		end
		if RREADY then
			HardCC = HardCC+1
			Airborne = Airborne+1
			SoftCC = SoftCC+1
			Slow = Slow+1
		end
	elseif targetName == "Galio" then
		if QREADY then
			SoftCC = SoftCC+1
			Slow = Slow+1			
		end
		if RREADY then
			HardCC = HardCC+1
			Taunt = Taunt+1			
		end
	elseif targetName == "Gangplank" then
		SoftCC = SoftCC+1
		Slow = Slow+1	
		if RREADY then
			SoftCC = SoftCC+1
			Slow = Slow+1	
		end
	elseif targetName == "Garen" then
		if QREADY then
			HardCC = HardCC+1
			Silence = Silence+1			
		end
	elseif targetName == "Gragas" then
		if EREADY then
			SoftCC = SoftCC+1
			Slow = Slow+1			
		end
		if RREADY then
			HardCC = HardCC+1
			Airborne = Airborne+1		
		end
	elseif targetName == "Graves" then
		if WREADY then
			SoftCC = SoftCC+1
			Slow = Slow+1			
		end
	elseif targetName == "Hecarim" then
		if EREADY then
			HardCC = HardCC+1
			Airborne = Airborne+1	
		end
		if RREADY then
			HardCC = HardCC+1
			Fear = Fear+1
		end
	elseif targetName == "Heimerdinger" then
		if EREADY then
			HardCC = HardCC+1
			Stun = Stun+1
			SoftCC = SoftCC+1
			Blind = Blind+1
		end
		if RREADY then
			SoftCC = SoftCC+1
			Slow = Slow+1
		end
	elseif targetName == "Irelia" then
		if EREADY then
			if (target.health/target.maxHealth) <= (myHero.health/myHero.maxHealth) then
				HardCC = HardCC+1
				Stun = Stun+1
			else
				SoftCC = SoftCC+1
				Slow = Slow+1
			end			
		end
	elseif targetName == "Janna" then
		if QREADY then
			HardCC = HardCC+1
			Airborne = Airborne+1
		end
		if WREADY then
			SoftCC = SoftCC+1
			Slow = Slow+1
		end
		if RREADY then
			HardCC = HardCC+1
			Airborne = Airborne+1
		end
	elseif targetName == "JarvanIV" then
		if QREADY and EREADY then
			HardCC = HardCC+1
			Airborne = Airborne+1
		end
		if WREADY then
			SoftCC = SoftCC+1
			Slow = Slow+1
		end
		if RREADY then
			SoftCC = SoftCC+1
			Wall = Wall+1
		end
	elseif targetName == "Jax" then
		if EREADY then
			HardCC = HardCC+1
			Stun = Stun+1
		end
	elseif targetName == "Jayce" then
		if QREADY and target:GetSpellData(_Q).name == "JayceToTheSkies" then
			SoftCC = SoftCC+1
			Slow = Slow+1			
		end
		if EREADY and target:GetSpellData(_E).name == "JayceThunderingBlow" then
			HardCC = HardCC+1
			Airborne = Airborne+1
		end
	elseif targetName == "Karma" then
		if WREADY then
			SoftCC = SoftCC+1
			Slow = Slow+1
		end
	elseif targetName == "Karthus" then
		if WREADY then
			SoftCC = SoftCC+1
			Slow = Slow+1
		end
	elseif targetName == "Kassadin" then
		if QREADY then
			HardCC = HardCC+1
			Silence = Silence+1
		end
		if EREADY then
			SoftCC = SoftCC+1
			Slow = Slow+1
		end
	elseif targetName == "Kayle" then
		if QREADY then
			SoftCC = SoftCC+1
			Slow = Slow+1
		end
	elseif targetName == "Kennen" then
		if QREADY and WREADY and EREADY then
			HardCC = HardCC+1
			Stun = Stun+1
		end
		if RREADY then
			HardCC = HardCC+1
			Stun = Stun+1
		end
	elseif targetName == "Khazix" then
		SoftCC = SoftCC+1
		Slow = Slow+1
	elseif targetName == "KogMaw" then
		if EREADY then
			SoftCC = SoftCC+1
			Slow = Slow+1
		end
	elseif targetName == "LeBlanc" then
		if QREADY and (WREADY or EREADY or RREADY) then
			HardCC = HardCC+1
			Silence = Silence+1
		end
		if EREADY then
			SoftCC = SoftCC+1
			Slow = Slow+1
			Snare = Snare+1
		end
		if RREADY and target:GetSpellData(_R).name == "LeblancChaosOrbM" and (WREADY or EREADY or QREADY) then
			HardCC = HardCC+1
			Silence = Silence+1
		end
		if RREADY and target:GetSpellData(_R).name == "LeblancSoulShackleM" then
			SoftCC = SoftCC+1
			Slow = Slow+1
			Snare = Snare+1
		end
	elseif targetName == "LeeSin" then
		if EREADY then
			SoftCC = SoftCC+1
			Slow = Slow+1
		end
		if RREADY then
			HardCC = HardCC+1
			Airborne = Airborne+1
		end
	elseif targetName == "Leona" then
		if QREADY then
			HardCC = HardCC+1
			Stun = Stun+1
		end
		if EREADY then
			SoftCC = SoftCC+1
			Snare = Snare+1
		end
		if RREADY then
			HardCC = HardCC+1
			Stun = Stun+1
			SoftCC = SoftCC+1
			Slow = Slow+1
		end
	elseif targetName == "Lulu" then
		if QREADY then
			SoftCC = SoftCC+1
			Slow = Slow+1
		end
		if WREADY then
			HardCC = HardCC+1
			Polymorph = Polymorph+1
		end
		if RREADY then
			HardCC = HardCC+1
			Airborne = Airborne+1
			SoftCC = SoftCC+1
			Slow = Slow+1
		end
	elseif targetName == "Lux" then
		if QREADY then
			SoftCC = SoftCC+1
			Snare = Snare+1
		end
		if EREADY then
			SoftCC = SoftCC+1
			Slow = Slow+1
		end
	elseif targetName == "Malphite" then
		if QREADY then
			SoftCC = SoftCC+1
			Slow = Slow+1
		end
		if RREADY then
			HardCC = HardCC+1
			Airborne = Airborne+1
		end
	elseif targetName == "Malzahar" then
		if QREADY then
			HardCC = HardCC+1
			Silence = Silence+1			
		end
		if RREADY then
			HardCC = HardCC+1
			Suppression = Suppression+1
		end
	elseif targetName == "Maokai" then
		if QREADY then
			HardCC = HardCC+1
			Airborne = Airborne+1
			SoftCC = SoftCC+1
			Slow = Slow+1
		end
		if WREADY then
			SoftCC = SoftCC+1
			Snare = Snare+1
		end
	elseif targetName == "MissFortune" then
		if EREADY then
			SoftCC = SoftCC+1
			Slow = Slow+1
		end
	elseif targetName == "Morgana" then
		if QREADY then
			SoftCC = SoftCC+1
			Snare = Snare+1
		end
		if RREADY then
			HardCC = HardCC+1
			Stun = Stun+1
			SoftCC = SoftCC+1
			Slow = Slow+1
		end
	elseif targetName == "Nami" then
		if QREADY then
			HardCC = HardCC+1
			Stun = Stun+1
		end
		if EREADY then
			SoftCC = SoftCC+1
			Slow = Slow+1
		end
		if RREADY then
			HardCC = HardCC+1
			Airborne = Airborne+1
			SoftCC = SoftCC+1
			Slow = Slow+1
		end
	elseif targetName == "Nasus" then
		if WREADY then
			SoftCC = SoftCC+1
			Slow = Slow+1
		end
	elseif targetName == "Nautilus" then
		HardCC = HardCC+1
		Stun = Stun+1
		if QREADY then
			HardCC = HardCC+1
			Airborne = Airborne+1
		end
		if EREADY then
			SoftCC = SoftCC+1
			Slow = Slow+1
		end
		if RREADY then
			HardCC = HardCC+1
			Airborne = Airborne+1
		end	
	elseif targetName == "Nocturne" then
		if EREADY then
			HardCC = HardCC+1
			Fear = Fear+1
		end
	elseif targetName == "Nunu" then
		if EREADY then
			SoftCC = SoftCC+1
			Slow = Slow+1
		end
		if RREADY then
			SoftCC = SoftCC+1
			Slow = Slow+1
		end
	elseif targetName == "Olaf" then
		if QREADY then
			SoftCC = SoftCC+1
			Slow = Slow+1
		end
	elseif targetName == "Orianna" then
		if WREADY then
			SoftCC = SoftCC+1
			Slow = Slow+1
		end
		if RREADY then
			HardCC = HardCC+1
			Airborne = Airborne+1
		end
	elseif targetName == "Pantheon" then
		if WREADY then
			HardCC = HardCC+1
			Stun = Stun+1
		end
		if RREADY then
			SoftCC = SoftCC+1
			Slow = Slow+1
		end
	elseif targetName == "Poppy" then
		if EREADY then
			HardCC = HardCC+1
			Airborne = Airborne+1
			Stun = Stun+1
		end
	elseif targetName == "Rammus" then
		if QREADY then
			HardCC = HardCC+1
			Airborne = Airborne+1
			SoftCC = SoftCC+1
			Slow = Slow+1
		end
		if EREADY then
			HardCC = HardCC+1
			Taunt = Taunt+1	
		end
	elseif targetName == "Renekton" then
		if WREADY then
			HardCC = HardCC+1
			Stun = Stun+1
		end
	elseif targetName == "Rengar" then -----------------------------------
		if EREADY then
			SoftCC = SoftCC+1
			Slow = Slow+1
		end
	elseif targetName == "Riven" then
		if QREADY then
			HardCC = HardCC+1
			Airborne = Airborne+1
		end
		if WREADY then
			HardCC = HardCC+1
			Stun = Stun+1
		end
	elseif targetName == "Rumble" then
		if EREADY then
			SoftCC = SoftCC+1
			Slow = Slow+1
		end
		if RREADY then
			SoftCC = SoftCC+1
			Slow = Slow+1
		end
	elseif targetName == "Ryze" then
		if WREADY then
			SoftCC = SoftCC+1
			Snare = Snare+1
		end
	elseif targetName == "Sejuani" then
		SoftCC = SoftCC+1
		Slow = Slow+1
		if QREADY then
			SoftCC = SoftCC+1
			Slow = Slow+1
		end
		if EREADY then
			SoftCC = SoftCC+1
			Slow = Slow+1
		end
		if RREADY then
			HardCC = HardCC+1
			Stun = Stun+1
		end
	elseif targetName == "Shaco" then
		if WREADY then
			HardCC = HardCC+1
			Fear = Fear+1
		end
		if EREADY then
			SoftCC = SoftCC+1
			Slow = Slow+1
		end
	elseif targetName == "Shen" then
		if EREADY then
			HardCC = HardCC+1
			Taunt = Taunt+1
		end
	elseif targetName == "Shyvana" then
		if RREADY then
			HardCC = HardCC+1
			Airborne = Airborne+1
		end
	elseif targetName == "Singed" then
		if WREADY then
			SoftCC = SoftCC+1
			Slow = Slow+1
		end
		if EREADY then
			HardCC = HardCC+1
			Airborne = Airborne+1
		end
	elseif targetName == "Sion" then
		if QREADY then
			HardCC = HardCC+1
			Stun = Stun+1
		end
	elseif targetName == "Skarner" then
		if QREADY then
			SoftCC = SoftCC+1
			Slow = Slow+1
		end
		if RREADY then
			HardCC = HardCC+1
			Suppression = Suppression+1
		end
	elseif targetName == "Sona" then-------------
		if RREADY then
			HardCC = HardCC+1
			Stun = Stun+1
		end
	elseif targetName == "Soraka" then
		if EREADY then
			HardCC = HardCC+1
			Silence = Silence+1
		end
	elseif targetName == "Swain" then
		if QREADY then
			SoftCC = SoftCC+1
			Slow = Slow+1
		end
		if WREADY then
			SoftCC = SoftCC+1
			Snare = Snare+1
		end
	elseif targetName == "Syndra" then
		if WREADY then
			SoftCC = SoftCC+1
			Slow = Slow+1
		end
		if EREADY then
			HardCC = HardCC+1
			Airborne = Airborne+1
		end
	elseif targetName == "Talon" then
		if WREADY then
			SoftCC = SoftCC+1
			Slow = Slow+1
		end
		if EREADY then
			HardCC = HardCC+1
			Silence = Silence+1
		end
	elseif targetName == "Taric" then
		if EREADY then
			HardCC = HardCC+1
			Stun = Stun+1
		end
	elseif targetName == "Teemo" then
		if QREADY then
			SoftCC = SoftCC+1
			Blind = Blind+1
		end
		if RREADY then
			SoftCC = SoftCC+1
			Slow = Slow+1
		end
	elseif targetName == "Tristana" then
		if WREADY then
			SoftCC = SoftCC+1
			Slow = Slow+1
		end
		if RREADY then
			HardCC = HardCC+1
			Airborne = Airborne+1
		end
	elseif targetName == "Trundle" then
		if EREADY then
			SoftCC = SoftCC+1
			Slow = Slow+1
			Wall = Wall+1
		end
	elseif targetName == "Tryndamere" then
		if WREADY then
			SoftCC = SoftCC+1
			Slow = Slow+1			
		end
	elseif targetName == "TwistedFate" then
		if target:GetSpellData(_W).name == "goldcardlock" then
			HardCC = HardCC+1
			Stun = Stun+1
		end
		if target:GetSpellData(_W).name == "redcardlock" then
			SoftCC = SoftCC+1
			Slow = Slow+1
		end
	elseif targetName == "Twitch" then
		if WREADY then
			SoftCC = SoftCC+1
			Slow = Slow+1
		end
	elseif targetName == "Udyr" then---------
		if EREADY then
			HardCC = HardCC+1
			Stun = Stun+1
		end
	elseif targetName == "Urgot" then
		if WREADY then
			SoftCC = SoftCC+1
			Slow = Slow+1
		end
		if RREADY then
			HardCC = HardCC+1
			Suppression = Suppression+1
		end
	elseif targetName == "Varus" then
		if EREADY then
			SoftCC = SoftCC+1
			Slow = Slow+1
		end
		if RREADY then
			SoftCC = SoftCC+1
			Snare = Snare+1
		end
	elseif targetName == "Vayne" then
		if EREADY then
			HardCC = HardCC+1
			Airborne = Airborne+1
			Stun = Stun+1
		end
	elseif targetName == "Veigar" then
		if EREADY then
			HardCC = HardCC+1
			Stun = Stun+1
		end
	elseif targetName == "Vi" then
		if QREADY then
			HardCC = HardCC+1
			Airborne = Airborne+1
		end
		if RREADY then
			HardCC = HardCC+1
			Airborne = Airborne+1
		end
	elseif targetName == "Viktor" then
		if WREADY then
			HardCC = HardCC+1
			Stun = Stun+1
			SoftCC = SoftCC+1
			Slow = Slow+1
		end
		if RREADY then
			HardCC = HardCC+1
			Silence = Silence+1
		end
	elseif targetName == "Vladimir" then
		if WREADY then
			SoftCC = SoftCC+1
			Slow = Slow+1
		end
	elseif targetName == "Volibear" then
		if QREADY then
			HardCC = HardCC+1
			Airborne = Airborne+1
		end
		if EREADY then
			SoftCC = SoftCC+1
			Slow = Slow+1
		end
	elseif targetName == "Warwick" then
		if RREADY then
			HardCC = HardCC+1
			Suppression = Suppression+1
		end
	elseif targetName == "MonkeyKing" then
		if RREADY then
			HardCC = HardCC+1
			Airborne = Airborne+1
		end
	elseif targetName == "Xerath" then
		if EREADY and (QREADY or RREADY) then
			HardCC = HardCC+1
			Stun = Stun+1
		end
	elseif targetName == "XinZhao" then
		if QREADY then
			HardCC = HardCC+1
			Airborne = Airborne+1
		end
		if EREADY then
			SoftCC = SoftCC+1
			Slow = Slow+1
		end
		if RREADY then
			HardCC = HardCC+1
			Airborne = Airborne+1
		end
	elseif targetName == "Yorick" then
		if WREADY then
			SoftCC = SoftCC+1
			Slow = Slow+1
		end
	elseif targetName == "Zed" then
		if EREADY then
			SoftCC = SoftCC+1
			Slow = Slow+1
		end
	elseif targetName == "Ziggs" then
		if WREADY then
			HardCC = HardCC+1
			Airborne = Airborne+1
		end
		if EREADY then
			SoftCC = SoftCC+1
			Slow = Slow+1
		end
	elseif targetName == "Zilean" then
		if EREADY then
			SoftCC = SoftCC+1
			Slow = Slow+1
		end
	elseif targetName == "Zyra" then
		if WREADY and EREADY then
			SoftCC = SoftCC+1
			Slow = Slow+1
		end
		if EREADY then
			SoftCC = SoftCC+1
			Snare = Snare+1
		end
		if RREADY then
			HardCC = HardCC+1
			Airborne = Airborne+1
		end
	end
	if typeCC == "HardCC" then return HardCC
	elseif typeCC == "Airborne" then return Airborne
	elseif typeCC == "Charm" then return Charm
	elseif typeCC == "Fear" then return Fear
	elseif typeCC == "Taunt" then return Taunt
	elseif typeCC == "Polymorph" then return Polymorph
	elseif typeCC == "Silence" then return Silence
	elseif typeCC == "Stun" then return Stun
	elseif typeCC == "Suppression" then return Suppression
	elseif typeCC == "SoftCC" then return SoftCC
	elseif typeCC == "Blind" then return Blind
	elseif typeCC == "Entangle" then return Entangle
	elseif typeCC == "Slow" then return Slow
	elseif typeCC == "Snare" then return Snare
	elseif typeCC == "Wall" then return Wall
	else return 0 end
end
function StunAlertOnCreateObj(obj)
	if obj.name:find("StunReady.troy") then
		for i = 1, heroManager.iCount do
		local h = heroManager:getHero(i)
			if h.team ~= myHero.team and GetDistance(obj) <= 100 then
				annieStun = obj 
			end
		end
	end
end
function StunAlertOnWndMsg(msg,key)
	if msg == WM_LBUTTONUP or not IsKeyDown(UIHK) then moveui = false end
    if msg == WM_LBUTTONDOWN and IsKeyDown(UIHK) then
		if CursorIsUnder(tablex, tabley, 130, 40) then moveui = true end
	end
end

-- ############################################# STUN ALERT ################################################

-- ############################################# TOWER RANGE ################################################


local towerRange = {
	turrets = {},
	typeText = {"OFF", "ON (enemy close)", "ON (enemy)", "ON (all)", "ON (all close)"},
	--[[         Config         ]]
	turretRange = 950,	 				-- 950
	fountainRange = 1050,	 			-- 1050
	allyTurretColor = 0x80FF00, 		-- Green color
	enemyTurretColor = 0xFF0000, 		-- Red color
	activeType = 1,						-- 0 Off, 1 Close enemy towers, 2 All enemy towers, 3 Show all, 4 Show all close
	tickUpdate = 1000,
	nextUpdate = 0,
}

function towerRange.checkTurretState()
	if towerRange.activeType > 0 then
		for name, turret in pairs(towerRange.turrets) do
			turret.active = false
		end
		for i = 1, objManager.maxObjects do
			local object = objManager:getObject(i)
			if object ~= nil and object.type == "obj_AI_Turret" then
				local name = object.name
				if towerRange.turrets[name] ~= nil then towerRange.turrets[name].active = true end
			end
		end
		for name, turret in pairs(towerRange.turrets) do
			if turret.active == false then towerRange.turrets[name] = nil end
		end
	end
end

function TowerRangeOnDraw()
	if GetGame().isOver then return end
	if towerRange.activeType > 0 then
		for name, turret in pairs(towerRange.turrets) do
			if turret ~= nil then
				if (towerRange.activeType == 1 and turret.team ~= player.team and player.dead == false and GetDistance(turret) < 2000)
				or (towerRange.activeType == 2 and turret.team ~= player.team)
				or (towerRange.activeType == 3)
				or (towerRange.activeType == 4 and player.dead == false and GetDistance(turret) < 2000) then
					DrawCircle(turret.x, turret.y, turret.z, turret.range, turret.color)
				end
			end
		end
	end
end
function TowerRangeOnTick()
end
function TowerRangeOnDeleteObj(object)
	if object ~= nil and object.type == "obj_AI_Turret" then
		for name, turret in pairs(towerRange.turrets) do
			if name == object.name then
				towerRange.turrets[name] = nil
				return
			end
		end
	end
end
function TowerRangeOnLoad()
	gameState = GetGame()
	for i = 1, objManager.maxObjects do
		local object = objManager:getObject(i)
		if object ~= nil and object.type == "obj_AI_Turret" then
			local turretName = object.name
			towerRange.turrets[turretName] = {
				object = object,
				team = object.team,
				color = (object.team == player.team and towerRange.allyTurretColor or towerRange.enemyTurretColor),
				range = towerRange.turretRange,
				x = object.x,
				y = object.y,
				z = object.z,
				active = false,
			}
			if turretName == "Turret_OrderTurretShrine_A" or turretName == "Turret_ChaosTurretShrine_A" then
				towerRange.turrets[turretName].range = towerRange.fountainRange
				for j = 1, objManager.maxObjects do
					local object2 = objManager:getObject(j)
					if object2 ~= nil and object2.type == "obj_SpawnPoint" and GetDistance(object, object2) < 1000 then
						towerRange.turrets[turretName].x = object2.x
						towerRange.turrets[turretName].z = object2.z
					elseif object2 ~= nil and object2.type == "obj_HQ" and object2.team == object.team then
						towerRange.turrets[turretName].y = object2.y
					end
				end
			end
		end
	end
end

-- ############################################# TOWER RANGE ################################################

-- ############################################# MINION MARKER ################################################

function MinionMarkerOnLoad()
	minionTable = {}
	for i = 0, objManager.maxObjects do
		local obj = objManager:GetObject(i)
		if obj ~= nil and obj.type ~= nil and obj.type == "obj_AI_Minion" then 
			table.insert(minionTable, obj) 
		end
	end
end

function MinionMarkerOnDraw() 
	for i,minionObject in ipairs(minionTable) do
		if not ValidTarget(minionObject) then
			table.remove(minionTable, i)
			i = i - 1
		elseif minionObject ~= nil and myHero:GetDistance(minionObject) ~= nil and myHero:GetDistance(minionObject) < 1500 and minionObject.health ~= nil and minionObject.health <= myHero:CalcDamage(minionObject, myHero.addDamage+myHero.damage) and minionObject.visible ~= nil and minionObject.visible == true then
			for g = 0, 6 do
				DrawCircle(minionObject.x, minionObject.y, minionObject.z,80 + g,255255255)
			end
        end
    end
end


function MinionMarkerOnCreateObj(object)
	if object ~= nil and object.type ~= nil and object.type == "obj_AI_Minion" then table.insert(minionTable, object) end
end

-- ############################################# MINION MARKER ################################################

-- ############################################# HIDDENOBJECTS ################################################

local hiddenObjects = {
	--[[      CONFIG      ]]
	showOnMiniMap = true,			-- show objects on minimap
	useSprites = true,				-- show sprite on minimap
	--[[      GLOBAL      ]]
	objectsToAdd = {
		{ name = "ItemMiniWard", objectType = "wards", spellName = "ItemMiniWard", charName = "ItemMiniWard", color = 0x0000FF00, range = 1450, duration = 60000, sprite = "greenPoint"},
		{ name = "ItemGhostWard", objectType = "wards", spellName = "ItemGhostWard", charName = "ItemGhostWard", color = 0x0000FF00, range = 1450, duration = 180000, sprite = "greenPoint"},
		{ name = "VisionWard", objectType = "wards", spellName = "VisionWard", charName = "VisionWard", color = 0x00FF00FF, range = 1450, duration = 180000, sprite = "yellowPoint"},
		{ name = "SightWard", objectType = "wards", spellName = "SightWard", charName = "SightWard", color = 0x0000FF00, range = 1450, duration = 180000, sprite = "greenPoint"},
		{ name = "WriggleLantern", objectType = "wards", spellName = "WriggleLantern", charName = "WriggleLantern", color = 0x0000FF00, range = 1450, duration = 180000, sprite = "greenPoint"},
		{ name = "Jack In The Box", objectType = "boxes", spellName = "JackInTheBox", charName = "ShacoBox", color = 0x00FF0000, range = 300, duration = 60000, sprite = "redPoint"},
		{ name = "Cupcake Trap", objectType = "traps", spellName = "CaitlynYordleTrap", charName = "CaitlynTrap", color = 0x00FF0000, range = 300, duration = 240000, sprite = "cyanPoint"},
		{ name = "Noxious Trap", objectType = "traps", spellName = "Bushwhack", charName = "Nidalee_Spear", color = 0x00FF0000, range = 300, duration = 240000, sprite = "cyanPoint"},
		{ name = "Noxious Trap", objectType = "traps", spellName = "BantamTrap", charName = "TeemoMushroom", color = 0x00FF0000, range = 300, duration = 600000, sprite = "cyanPoint"},
		-- to confirm spell
		{ name = "DoABarrelRoll", objectType = "boxes", spellName = "MaokaiSapling2", charName = "MaokaiSproutling", color = 0x00FF0000, range = 300, duration = 35000, sprite = "redPoint"},
	},
	tmpObjects = {},
	sprites = {
		cyanPoint = { spriteFile = "PingMarkerCyan_8", }, 
		redPoint = { spriteFile = "PingMarkerRed_8", }, 
		greenPoint = { spriteFile = "PingMarkerGreen_8", }, 
		yellowPoint = { spriteFile = "PingMarkerYellow_8", },
		greyPoint = { spriteFile = "PingMarkerGrey_8", },
	},
	objects = {},
}

--[[      CODE      ]]
function hiddenObjects.objectExist(spellName, pos, tick)
	for i,obj in pairs(hiddenObjects.objects) do
		if obj.object == nil and obj.spellName == spellName and GetDistance(obj.pos, pos) < 200 and tick < obj.seenTick then
			return i
		end
	end	
	return nil
end

function hiddenObjects.addObject(objectToAdd, pos, fromSpell, object)
	-- add the object
	local tick = GetTickCount()
	local objId = objectToAdd.spellName..(math.floor(pos.x) + math.floor(pos.z))
	--check if exist
	local objectExist = hiddenObjects.objectExist(objectToAdd.spellName, {x = pos.x, z = pos.z,}, tick - 2000)
	if objectExist ~= nil then
		objId = objectExist
	end
	if hiddenObjects.objects[objId] == nil then
		hiddenObjects.objects[objId] = {
			object = object,
			color = objectToAdd.color,
			range = objectToAdd.range,
			sprite = objectToAdd.sprite,
			spellName = objectToAdd.spellName,
			seenTick = tick,
			endTick = tick + objectToAdd.duration,
			fromSpell = fromSpell,
			visible = (object == nil),
			display = { visible = false, text = ""},
		}
	elseif hiddenObjects.objects[objId].object == nil and object ~= nil then
		hiddenObjects.objects[objId].object = object
		hiddenObjects.objects[objId].fromSpell = false
	end
	hiddenObjects.objects[objId].pos = {x = pos.x, y = pos.y, z = pos.z, }
	if hiddenObjects.showOnMiniMap == true then hiddenObjects.objects[objId].minimap = GetMinimap(pos) end
end

function HiddenObjectsOnCreateObj(object)
	if object ~= nil and object.type == "obj_AI_Minion" then
		for i,objectToAdd in pairs(hiddenObjects.objectsToAdd) do
			if object.name == objectToAdd.name then
				local tick = GetTickCount()
				table.insert(hiddenObjects.tmpObjects, {tick = tick, object = object})
			end
		end
	end
end

function HiddenObjectsOnProcessSpell(object,spell)
	if object ~= nil and object.team == TEAM_ENEMY then
		for i,objectToAdd in pairs(hiddenObjects.objectsToAdd) do
			if spell.name == objectToAdd.spellName then
				ticked = GetTickCount()
				hiddenObjects.addObject(objectToAdd, spell.endPos, true)
			end
		end
	end
end

function HiddenObjectsOnDeleteObj(object)
	if object ~= nil and object.name ~= nil and object.type == "obj_AI_Minion" then
		for i,objectToAdd in pairs(hiddenObjects.objectsToAdd) do
			if object.charName == objectToAdd.charName then
				-- remove the object
				for j,obj in pairs(hiddenObjects.objects) do
					if obj.object.valid and obj.object ~= nil and obj.object.networkID == object.networkID then
						hiddenObjects.objects[j] = nil
						return
					end
				end
			end
		end
	end
end

function HiddenObjectsOnDraw()
	if GetGame().isOver then return end
	local shiftKeyPressed = IsKeyDown(16)
	for i,obj in pairs(hiddenObjects.objects) do
		if obj.visible == true then
			DrawCircle(obj.pos.x, obj.pos.y, obj.pos.z, 100, obj.color)
			DrawCircle(obj.pos.x, obj.pos.y, obj.pos.z, (shiftKeyPressed and obj.range or 200), obj.color)
			--minimap
			if hiddenObjects.showOnMiniMap == true then
				if hiddenObjects.useSprites then
					hiddenObjects.sprites[obj.sprite].sprite:Draw(obj.minimap.x, obj.minimap.y, 0xFF)
				else
					DrawText("o",31,obj.minimap.x-7,obj.minimap.y-13,obj.color)
				end
				if obj.display.visible then
					DrawText(obj.display.text,14,obj.display.x,obj.display.y,obj.display.color)
				end
			end
		end
	end
end

function HiddenObjectsOnTick()
	if GetGame().isOver then return end
	local tick = GetTickCount()
	for i,obj in pairs(hiddenObjects.tmpObjects) do
		if tick > obj.tick + 1000 or obj.object == nil or obj.object.team == player.team then
			hiddenObjects.tmpObjects[i] = nil
		else
			for j,objectToAdd in pairs(hiddenObjects.objectsToAdd) do
				if obj.object ~= nil and obj.object.charName == objectToAdd.charName and obj.object.team == TEAM_ENEMY then
					hiddenObjects.addObject(objectToAdd, obj.object, false, obj.object)
					hiddenObjects.tmpObjects[i] = nil
					break
				end
			end
		end
	end
	for i,obj in pairs(hiddenObjects.objects) do
		if tick > obj.endTick or (obj.object ~= nil) and false then
			hiddenObjects.objects[i] = nil
		else
			if not obj.valid or obj.object == nil or (obj.valid and obj.object ~= nil and obj.object.dead == false) then
				obj.visible = true
			else
				obj.visible = false
			end
			-- cursor pos
			if obj.visible and GetDistanceFromMouse(obj.pos) < 150 then
				local cursor = GetCursorPos()
				obj.display.color = (obj.fromSpell and 0xFFFF0000 or 0xFF00FF00)
				obj.display.text = timerText((obj.endTick-tick)/1000)
				obj.display.x = cursor.x - 50
				obj.display.y = cursor.y - 50
				obj.display.visible = true
			else
				obj.display.visible = false
			end
		end
	end
end

function HiddenObjectsOnLoad()
	gameState = GetGame()
	if hiddenObjects.showOnMiniMap and hiddenObjects.useSprites then
		for i,sprite in pairs(hiddenObjects.sprites) do	hiddenObjects.sprites[i].sprite = GetSprite("hiddenObjects/"..sprite.spriteFile..".dds") end
	end
	for i = 1, objManager.maxObjects do
		local object = objManager:getObject(i)
		if object ~= nil then OnCreateObj(object) end
	end
end


-- ############################################# HIDDEN OBJECTS ################################################

-- ############################################# JUNGLE DISPLAY ################################################

--[[
        Script: Jungle Display v0.1d
		Author: SurfaceS
		
		required libs : 		
		required sprites : 		Jungle Sprites (if jungle.useSprites = true)
		exposed variables : 	-
		
		UPDATES :
		v0.1					initial release
		v0.1b					added twisted treeline + ping and chat functions.
		v0.1c					added ingame time.
		v0.1d					added advice on/off by click + send chat respawn on click
		v0.1e					added use minimap only mode, use "start" and "gameOver" lib now.
		v0.1f					local variables
		v0.2					BoL Studio Version
		
		USAGE :
		The script allow you to move and rotate the display
		
		Icons :
		You have 2 icons on the top left of the jungle display.
		First is for moving, the second is for rotate the display.
		The third icon is advice or not on this monster
		
		Moving :
		Hold the shift key, clic the move icon and drag the jungle display were you want.
		Settings are saved between games
		
		Rotate :
		Hold the shift key, clic the rotate icon. (4 types of rotation)
		Settings are saved between games
		
		Send to all by click : hold the shift key, and click on the timer.
]]


--[[      GLOBAL      ]]
local jungle = {}

-- [[     CONFIG     ]]
jungle.pingOnRespawn = true				-- ping location on respawn
jungle.pingOnRespawnBefore = true		-- ping location before respawn
jungle.textOnRespawn = true				-- print chat text on respawn
jungle.textOnRespawnBefore = true		-- print chat text before respawn
jungle.adviceBefore = 20				-- time in second to advice before monster respawn
jungle.adviceEnemyMonsters = true		-- advice enemy monster, or just our monsters
jungle.useSprites = true				-- nice shown or not
jungle.useMiniMapVersion = true			-- use minimap version (erase all display sprite or text)

--[[      GLOBAL      ]]

jungle.monsters = {
	summonerRift = {
		{	-- baron
			name = "baron",
			spriteFile = "Baron_Square_64",
			respawn = 420,
			advise = true,
			camps = {
				{
					name = "monsterCamp_12",
					creeps = { { { name = "Worm12.1.1" }, }, },
					team = TEAM_NEUTRAL,
				},
			},
		},
		{	-- dragon
			name = "dragon",
			spriteFile = "Dragon_Square_64",
			respawn = 360,
			advise = true,
			camps = {
				{
					name = "monsterCamp_6",
					creeps = { { { name = "Dragon6.1.1" }, }, },
					team = TEAM_NEUTRAL,
				},
			},
		},
		{	-- blue
			name = "blue",
			spriteFile = "AncientGolem_Square_64",
			respawn = 300,
			advise = true,
			camps = {
				{
					name = "monsterCamp_1",
					creeps = { { { name = "AncientGolem1.1.1" }, { name = "YoungLizard1.1.2" }, { name = "YoungLizard1.1.3" }, }, },
					team = TEAM_BLUE,
				},
				{
					name = "monsterCamp_7",
					creeps = { { { name = "AncientGolem7.1.1" }, { name = "YoungLizard7.1.2" }, { name = "YoungLizard7.1.3" }, }, },
					team = TEAM_RED,
				},
			},
		},
		{	-- red
			name = "red",
			spriteFile = "LizardElder_Square_64",
			respawn = 300,
			advise = true,
			camps = {
				{
					name = "monsterCamp_4",
					creeps = { { { name = "LizardElder4.1.1" }, { name = "YoungLizard4.1.2" }, { name = "YoungLizard4.1.3" }, }, },
					team = TEAM_BLUE,
				},
				{
					name = "monsterCamp_10",
					creeps = { { { name = "LizardElder10.1.1" }, { name = "YoungLizard10.1.2" }, { name = "YoungLizard10.1.3" }, }, },
					team = TEAM_RED,
				},
			},
		},
		{	-- wolves
			name = "wolves",
			spriteFile = "Giantwolf_Square_64",
			respawn = 60,
			advise = false,
			camps = {
				{
					name = "monsterCamp_2",
					creeps = { { { name = "GiantWolf2.1.3" }, { name = "wolf2.1.1" }, { name = "wolf2.1.2" }, }, },
					team = TEAM_BLUE,
				},
				{
					name = "monsterCamp_8",
					creeps = { { { name = "GiantWolf8.1.3" }, { name = "wolf8.1.1" }, { name = "wolf8.1.2" }, }, },
					team = TEAM_RED,
				},
			},
		},
		{	-- wraiths
			name = "wraiths",
			spriteFile = "Wraith_Square_64",
			respawn = 50,
			advise = false,
			camps = {
				{
					name = "monsterCamp_3",
					creeps = { { { name = "Wraith3.1.1" }, { name = "LesserWraith3.1.2" }, { name = "LesserWraith3.1.3" }, { name = "LesserWraith3.1.4" }, }, },
					team = TEAM_BLUE,
				},
				{
					name = "monsterCamp_9",
					creeps = { { { name = "Wraith9.1.1" }, { name = "LesserWraith9.1.2" }, { name = "LesserWraith9.1.3" }, { name = "LesserWraith9.1.4" }, }, },
					team = TEAM_RED,
				},
			},
		},
		{	-- Golems
			name = "Golems",
			spriteFile = "AncientGolem_Square_64",
			respawn = 60,
			advise = false,
			camps = {
				{
					name = "monsterCamp_5",
					creeps = { { { name = "Golem5.1.2" }, { name = "SmallGolem5.1.1" }, }, },
					team = TEAM_BLUE,
				},
				{
					name = "monsterCamp_11",
					creeps = { { { name = "Golem11.1.2" }, { name = "SmallGolem11.1.1" }, }, },
					team = TEAM_RED,
				},
			},
		},
	},
	twistedTreeline = {
		{	-- Dragon
			name = "Dragon",
			spriteFile = "Dragon_Square_64",
			respawn = 300,
			advise = true,
			camps = {
				{
					name = "monsterCamp_7",
					creeps = { { { name = "blueDragon7$1" }, }, },
					team = TEAM_NEUTRAL,
				},
			},
		},
		{	-- Lizard
			name = "Lizard",
			spriteFile = "LizardElder_Square_64",
			respawn = 240,
			advise = true,
			camps = {
				{
					name = "monsterCamp_8",
					creeps = { { { name = "TwistedLizardElder8$1" }, }, },
					team = TEAM_NEUTRAL,
				},
			},
		},
		{	-- Ghast Wraith or Radib Wolf
			name = "Buff Camp",
			spriteFile = "Wraith_Square_64",
			respawn = 180,
			advise = true,
			camps = {
				{
					name = "monsterCamp_5",
					creeps = {
						{ { name = "Ghast5$1" }, { name = "TwistedBlueWraith5$2" }, { name = "TwistedBlueWraith5$3" }, },
						{ { name = "RabidWolf5$1" }, { name = "TwistedGiantWolf5$2" }, { name = "TwistedGiantWolf5$3" }, },
					},
					team = TEAM_BLUE,
				},
				{
					name = "monsterCamp_6",
					creeps = {
						{ { name = "Ghast6$1" }, { name = "TwistedBlueWraith6$2" }, { name = "TwistedBlueWraith6$3" }, },
						{ { name = "RabidWolf6$1" }, { name = "TwistedGiantWolf6$2" }, { name = "TwistedGiantWolf6$3" }, },
					},
					team = TEAM_RED,
				},
				
			},
		},
		{	-- Small Golems - Young Lizard, Lizard, Golem
			name = "bottom small camp",
			spriteFile = "Gem_Square_64",
			respawn = 75,
			advise = false,
			camps = {
				{
					name = "monsterCamp_1",
					creeps = {
						{ { name = "Lizard1$1" }, { name = "TwistedGolem1$2" }, { name = "TwistedYoungLizard1$3" }, },
						{ { name = "TwistedBlueWraith1$1" }, { name = "TwistedTinyWraith1$2" }, { name = "TwistedTinyWraith1$3" }, { name = "TwistedTinyWraith1$4" }, },
					},
					team = TEAM_BLUE,
				},
				{
					name = "monsterCamp_2",
					creeps = { 
						{ { name = "Lizard2$1" }, { name = "TwistedGolem2$2" }, { name = "TwistedYoungLizard2$3" }, },
						{ { name = "TwistedBlueWraith2$1" }, { name = "TwistedTinyWraith2$2" }, { name = "TwistedTinyWraith2$3" }, { name = "TwistedTinyWraith2$4" }, },
					 },
					team = TEAM_RED,
				},
			},
		},
		{	-- Small Golems - Young Lizard, Lizard, Golem
			name = "Top small camp",
			spriteFile = "Angel_Square_64",
			respawn = 75,
			advise = false,
			camps = {
				{
					name = "monsterCamp_3",
					creeps = { 
						{ { name = "TwistedGiantWolf3$3" }, { name = "TwistedSmallWolf3$1" }, { name = "TwistedSmallWolf3$2" }, },
						{ { name = "TwistedGolem3$1" }, { name = "TwistedGolem3$2" } },
					},
					team = TEAM_BLUE,
				},
				{
					name = "monsterCamp_4",
					creeps = { 
						{ { name = "TwistedGiantWolf4$3" }, { name = "TwistedSmallWolf4$1" }, { name = "TwistedSmallWolf4$2" }, },
						{ { name = "TwistedGolem4$1" }, { name = "TwistedGolem4$2" } },
					},
					team = TEAM_RED,
				},
			},
		},
	},
}

jungle.shiftKeyPressed = false

function _miniMap__OnLoad()
if _miniMap.init then
  local map = GetGame().map
  if not WINDOW_W or not WINDOW_H then
   WINDOW_H = GetGame().WINDOW_H
   WINDOW_W = GetGame().WINDOW_W
  end
  if WINDOW_H < 500 or WINDOW_W < 500 then return true end
  local percent = math.max(WINDOW_W/1920, WINDOW_H/1080)
  _miniMap.step = {x = 265*percent/map.x, y = -264*percent/map.y}
  _miniMap.x = WINDOW_W-270*percent - _miniMap.step.x * map.min.x
  _miniMap.y = WINDOW_H-8*percent - _miniMap.step.y * map.min.y
  _miniMap.init = nil
end
return _miniMap.init
end

if not jungle.useMiniMapVersion then
	jungle.configFile = "./Common/jungle.cfg"
	jungle.display = {}
	jungle.display.x = 500
	jungle.display.y = 20
	jungle.display.rotation = 0
	jungle.display.move = false
	jungle.display.moveUnder = false
	jungle.display.rotateUnder = false
	jungle.display.size = 64
	
	if file_exists(jungle.configFile) then jungle.display = assert(loadfile(jungle.configFile))() end

	function jungle.writeConfigs()
		local file = io.open(jungle.configFile, "w")
		if file then
			file:write("return { x = "..jungle.display.x..", y = "..jungle.display.y..", rotation = "..jungle.display.rotation..", move = false, moveUnder = false, rotateUnder = false, size = "..jungle.display.size.." }")
			file:close()
		end
	end

	if jungle.useSprites then
		jungle.icon = { 
			arrowPressed = { spriteFile = "ArrowPressed_16", }, 
			arrowReleased = { spriteFile = "ArrowReleased_16", }, 
			arrowSwitch = { spriteFile = "ArrowSwitch_16", }, 
			advise = { spriteFile = "Advise_16", }, 
			adviseRed = { spriteFile = "AdviseRed_16", },
		}
		jungle.teams = {
			team100 = {	spriteFile = "TeamBlue_64",	},
			team200 = {	spriteFile = "TeamRed_64",},
			team300 = {	spriteFile = "TeamNeutral_64", },
		}
	end
end

-- Need to be on a lib
function jungle.timerSecondLeft(tick, respawn, deathTick)
	return math.ceil(math.max(0, respawn - (tick - deathTick) / 1000))
end

function jungle.addCampAndCreep(object)
	if object ~= nil and object.name ~= nil then
		for i,monster in pairs(jungle.monsters[mapName]) do
			for j,camp in pairs(monster.camps) do
				if camp.name == object.name then
					camp.object = object
					return
				end
				if object.type == "obj_AI_Minion" then
					for k,creepPack in ipairs(camp.creeps) do
						for l,creep in ipairs(creepPack) do
							if object.name == creep.name then
								creep.object = object
								return
							end
						end
					end
				end
			end
		end
	end
end

function jungle.removeCreep(object)
	if object ~= nil and object.type == "obj_AI_Minion" and object.name ~= nil then
		for i,monster in pairs(jungle.monsters[mapName]) do
			for j,camp in pairs(monster.camps) do
				for k,creepPack in ipairs(camp.creeps) do
					for l,creep in ipairs(creepPack) do
						if object.name == creep.name then
							creep.object = nil
							return
						end
					end
				end
			end
		end
	end
end

function JungleDisplayOnLoad()
	startTick = GetGame().tick
	mapName = GetGame().map.shortName
	gameState = GetGame()
	if jungle.monsters[mapName] == nil then
		jungle = nil
		function JungleDisplayOnTick()
		end
		function JungleDisplayOnDraw()
		end
		function JungleDisplayOnCreateObj(obj)
		end
		function JungleDisplayOnWndMsg(msg, key)
		end
	else
		if jungle.useSprites and jungle.useMiniMapVersion == false then
			-- load icons drawing sprites
			for i,icon in pairs(jungle.icon) do icon.sprite = GetSprite("jungle/"..icon.spriteFile..".dds") end
			-- load side drawing sprites
			for i,camps in pairs(jungle.teams) do camps.sprite = GetSprite("jungle/"..camps.spriteFile..".dds") end
		end
		-- load monster sprites and init values
		for i,monster in pairs(jungle.monsters[mapName]) do
			if jungle.useSprites and jungle.useMiniMapVersion == false then monster.sprite = GetSprite("Characters/"..monster.spriteFile..".dds") end
			monster.isSeen = false
			for j,camp in pairs(monster.camps) do
				camp.enemyTeam = (camp.team == TEAM_ENEMY)
				camp.status = 0
				camp.drawText = ""
				camp.drawColor = 0xFF00FF00
			end
		end
		for i = 1, objManager.maxObjects do
			local object = objManager:getObject(i)
			if object ~= nil then 
				jungle.addCampAndCreep(object)
			end
		end
		
		if jungle.useMiniMapVersion then
			-- test the minimap working
			if GetMinimapX(0) == -100 then PrintChat("Minimap not working, please reload") end
			--
			function JungleDisplayOnDraw()
				if GetGame().isOver then return end
				for i,monster in pairs(jungle.monsters[mapName]) do
					if monster.isSeen == true then
						for j,camp in pairs(monster.camps) do
							if camp.status == 2 then
								DrawText("X",16,camp.minimap.x - 4, camp.minimap.y - 5, camp.drawColor)
							elseif camp.status == 4 then
								DrawText(camp.drawText,16,camp.minimap.x - 9, camp.minimap.y - 5, camp.drawColor)
							end
						end
					end
				end
			end
		elseif jungle.useSprites then
			function JungleDisplayOnDraw()
				if GetGame().isOver then return end
				local monsterCount = 0
				for i,monster in pairs(jungle.monsters[mapName]) do
					if monster.isSeen == true then
						jungle.monsters[mapName][i].sprite:Draw(jungle.display.x + monster.shift.x,jungle.display.y + monster.shift.y,0xFF)
						if monster.advise then jungle.icon.advise.sprite:Draw(jungle.display.x + monster.shift.x + jungle.display.size - 18,jungle.display.y - 2,0xFF) end
						for j,camp in pairs(monster.camps) do
							if camp.status ~= 0 then
								jungle.teams["team"..camp.team].sprite:Draw(jungle.display.x + camp.shift.x,jungle.display.y + camp.shift.y,0xFF)
								DrawText(camp.drawText,17,jungle.display.x + camp.shift.x + 10,jungle.display.y + camp.shift.y - 3,camp.drawColor)
							end
						end
						monsterCount = monsterCount + 1
					end
				end
				if monsterCount > 0 then
					jungle.icon.arrowPressed.sprite:Draw(jungle.display.x,jungle.display.y,(jungle.shiftKeyPressed and 0xFF or 0xAA))
					jungle.icon.arrowSwitch.sprite:Draw(jungle.display.x+16,jungle.display.y,(jungle.shiftKeyPressed and 0xFF or 0xAA))
				end
			end
		else
			function JungleDisplayOnDraw()
				if GetGame().isOver then return end
				local monsterCount = 0
				for i,monster in pairs(jungle.monsters[mapName]) do
					if monster.isSeen == true then
						DrawText(monster.name..(monster.advise and " *" or ""),17,jungle.display.x + monster.shift.x,jungle.display.y + monster.shift.y,0xFFFF0000)
						for j,camp in pairs(monster.camps) do
							if camp.status ~= 0 then
								DrawText(camp.team.." - "..camp.drawText,17,jungle.display.x + camp.shift.x + 10,jungle.display.y + camp.shift.y - 3,camp.drawColor)
							end
						end
						monsterCount = monsterCount + 1
					end
				end
			end
		end
		
		function JungleDisplayOnCreateObj(object)
			if object ~= nil then
				jungle.addCampAndCreep(object)
			end
		end
		
		function JungleDisplayOnWndMsg(msg,key)
			if msg == WM_LBUTTONDOWN and IsKeyDown(16) then
				for i,monster in pairs(jungle.monsters[mapName]) do
					if monster.isSeen == true then
						if monster.iconUnder then
							monster.advise = not monster.advise
							break
						else
							for j,camp in pairs(monster.camps) do
								if camp.textUnder then
									if camp.respawnText ~= nil then SendChat(""..camp.respawnText) end
									break
								end
							end
						end
					end
				end
			end
		end
		
		function JungleDisplayOnDeleteObj(object)
			if object ~= nil then
				jungle.removeCreep(object)
			end
		end
		
		function JungleDisplayOnTick()
			if GetGame().isOver then return end
			-- walkaround OnWndMsg bug
			jungle.shiftKeyPressed = IsKeyDown(16)
			if jungle.useMiniMapVersion == false and jungle.display.moveUnder and IsKeyDown(1) then
				jungle.display.move = true
			elseif jungle.useMiniMapVersion == false and jungle.display.move and IsKeyDown(1) == false then
				jungle.display.move = false
				jungle.display.moveUnder = false
				jungle.display.cursorShift = nil
				jungle.writeConfigs()
			elseif jungle.useMiniMapVersion == false and jungle.display.rotateUnder and IsKeyDown(1) then
				jungle.display.rotation = (jungle.display.rotation == 3 and 0 or jungle.display.rotation + 1)
				jungle.writeConfigs()
			end
			local tick = GetTickCount()
			local monsterCount = 0
			for i,monster in pairs(jungle.monsters[mapName]) do
				for j,camp in pairs(monster.camps) do
					local campStatus = 0
					for k,creepPack in ipairs(camp.creeps) do
						for l,creep in ipairs(creepPack) do
							if creep.object ~= nil and creep.object.dead == false then
								if l == 1 then
									campStatus = 1
								elseif campStatus ~= 1 then
									campStatus = 2
								end
							end
						end
					end
					--[[  Not used until camp.showOnMinimap work
					if (camp.object and camp.object.showOnMinimap == 1) then
						-- camp is here
						if campStatus == 0 then campStatus = 3 end
					elseif camp.status == 3 then 						-- empty not seen when killed
						campStatus = 5
					elseif campStatus == 0 and (camp.status == 1 or camp.status == 2) then
						campStatus = 4
						camp.deathTick = tick
					end
					]]
					-- temp fix until camp.showOnMinimap work
					-- not so good
					if jungle.useMiniMapVersion and camp.object ~= nil then camp.minimap = GetMinimap(camp.object) end
					if camp.object ~= nil and campStatus == 0 then
						if (camp.status == 1 or camp.status == 2) then
							campStatus = 4
							camp.deathTick = tick
							camp.advisedBefore = false
							camp.advised = false
							camp.respawnTime = math.ceil((tick - startTick) / 1000) + monster.respawn
							camp.respawnText = (camp.enemyTeam and "Enemy " or "")..monster.name.." respawn at "..TimerText(camp.respawnTime)
						elseif (camp.status == 4) then
							campStatus = 4
						else
							campStatus = 3
						end
					end
					if jungle.useMiniMapVersion == false and campStatus ~= 0 then
						if jungle.display.rotation == 0 then
							camp.shift = { x = monsterCount * jungle.display.size, y = (camp.enemyTeam and jungle.display.size + 26 or jungle.display.size + 6), }
						elseif jungle.display.rotation == 1 then
							camp.shift = { x = jungle.display.size + 6, y = (monsterCount * jungle.display.size) + (camp.enemyTeam and 32 or 12 ), }
						elseif jungle.display.rotation == 2 then
							camp.shift = { x = monsterCount * jungle.display.size, y = (camp.enemyTeam and -(jungle.display.size - 24) or -(jungle.display.size - 44)), }
						elseif jungle.display.rotation == 3 then
							camp.shift = { x = -(jungle.display.size + 6), y = (monsterCount * jungle.display.size) + (camp.enemyTeam and 32 or 12 ), }
						end
					end
					if camp.status ~= campStatus or campStatus == 4 then
						if campStatus ~= 0 then
							if monster.isSeen == false then monster.isSeen = true end
							camp.status = campStatus
						end
						if camp.status == 1 then				-- ready
							camp.drawText = "ready"
							camp.drawColor = 0xFF00FF00
						elseif camp.status == 2 then			-- ready, master creeps dead
							camp.drawText = "stolen"
							camp.drawColor = 0xFFFF0000
						elseif camp.status == 3 then			-- ready, not creeps shown
							camp.drawText = "   ?"
							camp.drawColor = 0xFF00FF00			
						elseif camp.status == 4 then			-- empty from creeps kill
							local secondLeft = jungle.timerSecondLeft(tick, monster.respawn, camp.deathTick)
							if monster.advise == true and (jungle.adviceEnemyMonsters == true or camp.enemyTeam == false) then
								if secondLeft == 0 and camp.advised == false then
									camp.advised = true
									if jungle.textOnRespawn then PrintChat("<font color='#00FFCC'>"..(camp.enemyTeam and "Enemy " or "")..monster.name.." has respawned</font>") end
									if jungle.pingOnRespawn then PingSignal(PING_FALLBACK,camp.object.x,camp.object.y,camp.object.z,2) end
								elseif secondLeft <= jungle.adviceBefore and camp.advisedBefore == false then
									camp.advisedBefore = true
									if jungle.textOnRespawnBefore then PrintChat("<font color='#00FFCC'>"..(camp.enemyTeam and "Enemy " or "")..monster.name.." will respawn in "..secondLeft.." sec</font>") end
									if jungle.pingOnRespawnBefore then PingSignal(PING_FALLBACK,camp.object.x,camp.object.y,camp.object.z,2) end
								end
							end
							-- temp fix until camp.showOnMinimap work
							if secondLeft == 0 then
								camp.status = 0
							end
							camp.drawText = " "..TimerText(secondLeft)
							camp.drawColor = 0xFFFFFF00
						elseif camp.status == 5 then			-- camp found empty (not using yet)
							camp.drawText = "   -"
							camp.drawColor = 0xFFFF0000
						end
					end
					if jungle.shiftKeyPressed and camp.status == 4 then
						camp.drawText = " "..(camp.respawnTime ~= nil and TimerText(camp.respawnTime) or "")
						if jungle.useMiniMapVersion then 
							camp.textUnder = (CursorIsUnder(camp.minimap.x - 9, camp.minimap.y - 5, 20, 8))
						else
							camp.textUnder = (jungle.display.move == false and jungle.display.moveUnder == false and jungle.display.rotateUnder == false and CursorIsUnder(jungle.display.x + camp.shift.x, jungle.display.y + camp.shift.y, jungle.display.size, 16))
						end
					else
						camp.textUnder = false
					end
				end
					-- update monster pos
				if monster.isSeen == true and jungle.useMiniMapVersion == false then
					if jungle.display.rotation == 0 or jungle.display.rotation == 2 then
						monster.shift = { x = monsterCount * jungle.display.size, y = 0, }
					else
						monster.shift = { x = 0, y = monsterCount * jungle.display.size, }
					end
					monster.iconUnder = (jungle.shiftKeyPressed and jungle.display.move == false and jungle.display.moveUnder == false and jungle.display.rotateUnder == false and CursorIsUnder(jungle.display.x + monster.shift.x, jungle.display.y + monster.shift.y, jungle.display.size, jungle.display.size))
					monsterCount = monsterCount + 1
				end
			end
			-- update icon mouse
			if jungle.useMiniMapVersion == false then
				if jungle.display.move == true then
					if jungle.display.cursorShift == nil or jungle.display.cursorShift.x == nil or jungle.display.cursorShift.y == nil then
						jungle.display.cursorShift = { x = GetCursorPos().x - jungle.display.x, y = GetCursorPos().y - jungle.display.y, }
					else
						jungle.display.x = GetCursorPos().x - jungle.display.cursorShift.x
						jungle.display.y = GetCursorPos().y - jungle.display.cursorShift.y
					end
				else
					jungle.display.moveUnder = (jungle.shiftKeyPressed and CursorIsUnder(jungle.display.x, jungle.display.y, 16, 16))
					jungle.display.rotateUnder = (jungle.shiftKeyPressed and CursorIsUnder(jungle.display.x + 16, jungle.display.y, 16, 16))
				end
			end
		end
	end
end

-- ############################################# JUNGLEDISPLAY ################################################

-- ############################################# ENEMY RANGE ################################################

-- Simple Player and Enemy Range Circles
-- by heist
-- v1.0
-- Initial release
-- v1.0.1
-- Adjusted AA range to be more accurate
-- Adopted to studio by Mistal

champAux = {}
champ = {
	Ahri = { 880, 975 },
	Akali = { 800, 0 },
	Alistar = { 650, 0 },
	Amumu = { 0, 600 },
	Anivia = { 650, 1100 },
	Annie = { 625, 0 },
	Ashe = { 1200, 0 },
	Blitzcrank = { 1000, 0 },
	Brand = { 900, 0 },
	Caitlyn = { 1300, 0 },
	Cassiopeia = { 700, 850 },
	Chogath = { 950, 700 },
	Corki = { 1200, 0 },
	Darius = {550, 475}, -- his E and R
	Diana = {830, 900}, -- Q and R
	Draven = {550, 0 }, -- his Ulti is global, his normal range is 550
	DrMundo = { 1000, 0 },
	Evelynn = { 325, 0 },
	Ezreal = { 1000, 0 },
	Fiddlesticks = { 475, 575 },
	Fiora = { 600, 400 },
	Fizz = { 550, 1275 },
	Galio = { 1000, 550 },
	Gangplank = { 625, 0 },
	Garen = { 400, 0 },
	Gragas = { 1150, 1050 },
	Graves = { 750, 0 },
	Hecarim = { 325, 0 }, -- Placeholder
	Heimerdinger = { 1000, 0 },
	Irelia = { 650, 425 },
	Janna = { 800, 1700 },
	JarvanIV = { 770, 650 },
	Jax = { 700, 0 },
	Jayce = { 500, 1050 }, -- normal range attack and ulti
	Karma = { 800, 0 },
	Karthus = { 850, 1000 },
	Kassadin = { 700, 650 },
	Katarina = { 700, 0 },
	Kayle = { 650, 0 },
	Kennen = { 1050, 0 },
	KogMaw = { 1000, 0 },
	Leblanc = { 1300, 600 },
	LeeSin = { 1100, 0 },
	Leona = { 1200, 0 },
	Lulu = { 925, 650 },
	Lux = { 1000, 0 },
	Malphite = { 1000, 0 },
	Malzahar = { 700, 0 },
	Maokai = { 650, 0 },
	MasterYi = { 600, 0 },
	MissFortune = { 625, 1400 },
	MonkeyKing = { 625, 325 },
	Mordekaiser = { 700, 1125 },
	Morgana = { 1300, 600 },
	Nasus = { 700, 0 },
	Nautilus = { 950, 850 },
	Nidalee = { 1500, 0 },
	Nocturne = { 1200, 465 },
	Nunu = { 550, 0 },
	Olaf = { 1000, 0 },
	Orianna = { 825, 0 },
	Pantheon = { 0, 600 },
	Poppy = { 525, 0 },
	Rammus = { 0, 325 },
	Renekton = { 550, 0 },
	Riven = { 0, 250 },
	Rumble = { 600, 1000 },
	Ryze = { 675, 625 },
	Sejuani = { 700, 1150 },
	Shaco = { 625, 0 },
	Shen = { 0, 600 },
	Shyvana = { 1000, 0 },
	Singed = { 0, 125 },
	Sion = { 550, 0 },
	Sivir = { 1100, 0 },
	Skarner = { 600, 350 },
	Sona = { 0, 1000 },
	Soraka = { 0, 725 },
	Swain = { 900, 0 },
	Syndra = { 550, 0 },
	Talon = { 700, 0 },
	Taric = { 0, 625 },
	Teemo = { 680, 0 },
	Tristana = { 900, 700 },
	Trundle = { 0, 1000 },
	Tryndamere = { 660, 0 },
	TwistedFate = { 1700, 0 },
	Twitch = { 1200, 0 },
	Udyr = { 625, 0 },
	Urgot = { 1000, 0 },
	Varus = { 925, 1075 },
	Vayne = { 0, 450 },
	Veigar = { 650, 0 },
	Viktor = { 600, 0 },
	Vladimir = { 600, 700 },
	Volibear = { 425, 0 },
	Warwick = { 0, 700 },
	Xerath = { 1300, 900 },
	XinZhao = { 650, 0 },
	Yorick = { 600, 0 },
	Ziggs = { 1000, 850 },
	Zilean = { 700, 0 },
	Zyra = { 825, 1100 },
}
champAux = champ
player = GetMyHero()
heroindex, c = {}, 0
for i = 1, heroManager.iCount do
local h = heroManager:getHero(i)
if h.name == player.name or h.team ~= player.team then
heroindex[c+1] = i
c = c+1
end
end

function RangesOnDraw()
for _,v in ipairs(heroindex) do
local h = heroManager:getHero(v)
local t = champAux[h.charName]

if h.visible and not h.dead then
         if h.range > 400 and (t == nil or (h.range + 100 ~= t[1] and h.range + 100 ~= t[2])) then
         DrawCircle(h.x, h.y, h.z,h.range + 100, 0xFF646464)
         end
         if t ~= nil then
         if t[1] > 0 then
                 DrawCircle(h.x, h.y, h.z,t[1], 0xFF006400)
         end
         if t[2] > 0 then
                 DrawCircle(h.x, h.y, h.z,t[2], 0xFF640000)
         end
         end
end
end
end

-- ############################################# ENEMY RANGE ################################################

-- ############################################# WARD PREDICTION RANGE ################################################

--[[
	Ward Prediction 1.0 by eXtragoZ
			
		It uses AllClass
	
	Features:
		- Prints in the chat the amount of wards purchased and used by allies and enemies
		- Indicates the position where may be the ward that use the enemy with circles and says the remaining duration
		- You can remove the marks pressing shift and double click in the circle
]]
--[[		Config		]]
local WardPredictionHK = 16 --shift
--[[		Code		]]
local WardPredictionlastclick = 0
local WardPredictiondeletewards = 0
local WardPredictioncountSightWard,WardPredictionlastcountSightWard,WardPredictioncountVisionWard,WardPredictioncountlastcountVisionWard = {},{},{},{}
local WardPredictionitemslot = {ITEM_1,ITEM_2,ITEM_3,ITEM_4,ITEM_5,ITEM_6}
local WardPredictioncolorteam = "#0095FF"
local WardPredictionunittraveled = {}
local WardPredictionMissTimer = {}
local WardPredictionMissSec = {}
local WardPredictiontick_heros = {}
local WardPredictioncenterpos = {}
local WardPredictionpossibleposlist = {}

function WardPredictionOnLoad()
	for i=1, heroManager.iCount do WardPredictioncountSightWard[i],WardPredictionlastcountSightWard[i],WardPredictioncountVisionWard[i],WardPredictioncountlastcountVisionWard[i] = 0,0,0,0 end
	PrintChat(" >> Ward Prediction 1.0 loaded!")
end
function WardPredictionOnTick()
	for i=1, heroManager.iCount do
		local champion = heroManager:GetHero(i)
		WardPredictioncountSightWard[i] = 0
		WardPredictioncountVisionWard[i] = 0
		for j=1, 6 do
			local item = champion:getItem(WardPredictionitemslot[j])
			if item ~= nil and item.id == 2044 then WardPredictioncountSightWard[i] = WardPredictioncountSightWard[i] + item.stacks end
			if item ~= nil and item.id == 2043 then WardPredictioncountVisionWard[i] = WardPredictioncountVisionWard[i] + item.stacks end
		end
		WardPredictioncolorteam = (champion.team == myHero.team and "#0095FF" or "#FF0000")
		if WardPredictionlastcountSightWard[i] > WardPredictioncountSightWard[i] then
			PrintChat("<font color='"..WardPredictioncolorteam.."'>"..champion.charName.."</font><font color='#EEA111'> used "..WardPredictionlastcountSightWard[i]-WardPredictioncountSightWard[i].." </font><font color='#199C33'>Sight Ward</font>")
			if WardPredictionunittraveled[i] ~= nil and champion.team ~= myHero.team then
				table.insert(WardPredictionpossibleposlist, {x = (WardPredictioncenterpos[i].x+champion.x)/2, y = (WardPredictioncenterpos[i].y+champion.y)/2, z = (WardPredictioncenterpos[i].z+champion.z)/2, wardtime = GetTickCount()+180000, warddistance = WardPredictionunittraveled[i]/2+680})
			end
		end
		if WardPredictionlastcountSightWard[i] < WardPredictioncountSightWard[i] then
			PrintChat("<font color='"..WardPredictioncolorteam.."'>"..champion.charName.."</font><font color='#FFFC00'> buy "..WardPredictioncountSightWard[i]-WardPredictionlastcountSightWard[i].." </font><font color='#199C33'>Sight Ward</font>")
		end
		if WardPredictioncountlastcountVisionWard[i] > WardPredictioncountVisionWard[i] then
			PrintChat("<font color='"..WardPredictioncolorteam.."'>"..champion.charName.."</font><font color='#EEA111'> used "..WardPredictioncountlastcountVisionWard[i]-WardPredictioncountVisionWard[i].." </font><font color='#C000FF'>Vision Ward</font>")
			if WardPredictionunittraveled[i] ~= nil and champion.team ~= myHero.team then
				table.insert(WardPredictionpossibleposlist, {x = (WardPredictioncenterpos[i].x+champion.x)/2, y = (WardPredictioncenterpos[i].y+champion.y)/2, z = (WardPredictioncenterpos[i].z+champion.z)/2, wardtime = GetTickCount()+180000, warddistance = WardPredictionunittraveled[i]/2+680})
			end
		end
		if WardPredictioncountlastcountVisionWard[i] < WardPredictioncountVisionWard[i] then
			PrintChat("<font color='"..WardPredictioncolorteam.."'>"..champion.charName.."</font><font color='#FFFC00'> buy "..WardPredictioncountVisionWard[i]-WardPredictioncountlastcountVisionWard[i].." </font><font color='#C000FF'>Vision Ward</font>")
		end
		WardPredictionlastcountSightWard[i] = WardPredictioncountSightWard[i]
		WardPredictioncountlastcountVisionWard[i] = WardPredictioncountVisionWard[i]
	end
	for i,object in ipairs(WardPredictionpossibleposlist) do
		if GetTickCount() > object.wardtime then
			table.remove(WardPredictionpossibleposlist,i)
		elseif GetTickCount()-WardPredictiondeletewards <= 50 then
			if GetDistance(object,mousePos)<=object.warddistance then
				table.remove(WardPredictionpossibleposlist,i)
			end
		end
	end
	for i=1, heroManager.iCount do
		local heros = heroManager:GetHero(i)
		if heros.team ~= myHero.team and not heros.visible and not heros.dead then
			if WardPredictiontick_heros[i] == nil then WardPredictiontick_heros[i] = GetTickCount() end
			WardPredictionMissTimer[i] = GetTickCount() - WardPredictiontick_heros[i]			
			WardPredictionMissSec[i] =  WardPredictionMissTimer[i]/1000
			WardPredictionunittraveled[i] = heros.ms*WardPredictionMissSec[i]
		else
			WardPredictiontick_heros[i] = nil
			WardPredictionMissTimer[i] = nil
			WardPredictionMissSec[i] = 0
			WardPredictionunittraveled[i] = 0
		end
		WardPredictioncenterpos[i] = {x = heros.x, y = heros.y, z = heros.z}
	end
end

function WardPredictionOnDraw()
	local order = 0
	for i,object in ipairs(WardPredictionpossibleposlist) do
		if object.warddistance <= 10000 then
			DrawCircle(object.x, object.y, object.z, object.warddistance, 0xFF11FF)
		end
		if GetDistance(object,mousePos)<=object.warddistance then
			local cursor = GetCursorPos()
			DrawText("Possible ward "..timerText((object.wardtime-GetTickCount())/1000),16, cursor.x, cursor.y + 50+15*order, RGBA(255,100,0,255))
			order = order+1
		end
	end
end

function WardPredictionOnWndMsg(msg,key)
	if IsKeyDown(WardPredictionHK) then
		if msg == WM_LBUTTONUP then
			if GetTickCount()-WardPredictionlastclick <= 200 then
				WardPredictiondeletewards = GetTickCount()
			end
			WardPredictionlastclick = GetTickCount()
		end
	end
end

-- ############################################# WARD PREDICTION RANGE ################################################


-- XT002 --

function OnLoad()
	KCConfig = scriptConfig("XT002 HUD", "xt002hud")
	KCConfig:addParam("MinionMarker", "Enable Minion Marker", SCRIPT_PARAM_ONOFF, true)
	KCConfig:addParam("TowerRange", "Enable Tower Range", SCRIPT_PARAM_ONOFF, true)
	KCConfig:addParam("StunAlert", "Enable Stun Alert", SCRIPT_PARAM_ONOFF, true)
	KCConfig:addParam("LowAwareness", "Enable Low Awareness", SCRIPT_PARAM_ONOFF, true)
	KCConfig:addParam("HiddenObjects", "Enable Hidden Objects", SCRIPT_PARAM_ONOFF, true)
	KCConfig:addParam("JungleDisplay", "Enable Jungle Display", SCRIPT_PARAM_ONOFF, true)
	KCConfig:addParam("Ranges", "Enable Player & Enemy Ranges", SCRIPT_PARAM_ONOFF, false)
	KCConfig:addParam("WardPrediction", "Enable Ward Prediction", SCRIPT_PARAM_ONOFF, false)
	
	JungleDisplayOnLoad()
	TowerRangeOnLoad()
	MinionMarkerOnLoad()
	HiddenObjectsOnLoad()
	WardPredictionOnLoad()
end

function OnTick()
	if KCConfig.TowerRange then
		TowerRangeOnTick()
	end
	if KCConfig.LowAwareness then
		LowAwarenessOnTick()
	end
	if KCConfig.HiddenObjects then
		HiddenObjectsOnTick()
	end
	if KCConfig.JungleDisplay then
		JungleDisplayOnTick()
	end
	if KCConfig.WardPrediction then
		WardPredictionOnTick()
	end
end

function OnCreateObj(obj)
	if KCConfig.MinionMarker then
		MinionMarkerOnCreateObj(obj)
	end
	if KCConfig.HiddenObjects then
		HiddenObjectsOnCreateObj(obj)
	end	
	if KCConfig.JungleDisplay then
		JungleDisplayOnCreateObj(obj)
	end	
end

function OnDeleteObj(obj)
	if KCConfig.TowerRange then
		TowerRangeOnDeleteObj(obj)
	end
	if KCConfig.HiddenObjects then
		HiddenObjectsOnDeleteObj(obj)
	end
	if KCConfig.JungleDisplay then
		if JungleDisplayOnDeleteObj then JungleDisplayOnDeleteObj(obj) end
	end
end

function OnDraw()
	if KCConfig.MinionMarker then
		MinionMarkerOnDraw()
	end
	if KCConfig.TowerRange then
		TowerRangeOnDraw()
	end
	if KCConfig.StunAlert then
		StunAlertOnDraw()
	end
	if KCConfig.LowAwareness then
		LowAwarenessOnDraw()
	end
	if KCConfig.HiddenObjects then
		HiddenObjectsOnDraw()
	end
	if KCConfig.JungleDisplay then
		JungleDisplayOnDraw()
	end
	if KCConfig.Ranges then
		RangesOnDraw()
	end
	if KCConfig.WardPrediction then
		WardPredictionOnDraw()
	end
end

function OnWndMsg(msg,key)
	if KCConfig.JungleDisplay then
		JungleDisplayOnWndMsg(msg, key	)
	end
	if KCConfig.StunAlert then
		StunAlertOnWndMsg(msg, key)
	end
	if KCConfig.WardPrediction then
		WardPredictionOnWndMsg(msg, key)
	end
end

PrintChat(" >> XT002-HUD Loaded <<")
