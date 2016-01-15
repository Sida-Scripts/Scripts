local version = 2.978
local TESTVERSION = false
local AUTO_UPDATE = true

local function AutoupdaterMsg(msg) print("<font color=\"#6699ff\"><b>VPrediction:</b></font> <font color=\"#FFFFFF\">"..msg..".</font>") end

class "VPredLibUpdate"
function VPredLibUpdate:__init(LocalVersion,UseHttps, Host, VersionPath, ScriptPath, SavePath, CallbackUpdate, CallbackNoUpdate, CallbackNewVersion,CallbackError)
    self.LocalVersion = LocalVersion
    self.Host = Host
    self.VersionPath = '/BoL/TCPUpdater/GetScript'..(UseHttps and '5' or '6')..'.php?script='..self:Base64Encode(self.Host..VersionPath)..'&rand='..math.random(99999999)
    self.ScriptPath = '/BoL/TCPUpdater/GetScript'..(UseHttps and '5' or '6')..'.php?script='..self:Base64Encode(self.Host..ScriptPath)..'&rand='..math.random(99999999)
    self.SavePath = SavePath
    self.CallbackUpdate = CallbackUpdate
    self.CallbackNoUpdate = CallbackNoUpdate
    self.CallbackNewVersion = CallbackNewVersion
    self.CallbackError = CallbackError
    --AddDrawCallback(function() self:OnDraw() end)
    self:CreateSocket(self.VersionPath)
    self.DownloadStatus = 'Connect to Server for VersionInfo'
    AddTickCallback(function() self:GetOnlineVersion() end)
end

function VPredLibUpdate:print(str)
    print('<font color="#FFFFFF">'..clock()..': '..str)
end

function VPredLibUpdate:OnDraw()
    if self.DownloadStatus ~= 'Downloading Script (100%)' and self.DownloadStatus ~= 'Downloading VersionInfo (100%)'then
        DrawText('Download Status: '..(self.DownloadStatus or 'Unknown'),50,10,50,ARGB(0xFF,0xFF,0xFF,0xFF))
    end
end

function VPredLibUpdate:CreateSocket(url)
    if not self.LuaSocket then
        self.LuaSocket = require("socket")
    else
        self.Socket:close()
        self.Socket = nil
        self.Size = nil
        self.RecvStarted = false
    end
    self.LuaSocket = require("socket")
    self.Socket = self.LuaSocket.tcp()
    self.Socket:settimeout(0, 'b')
    self.Socket:settimeout(99999999, 't')
    self.Socket:connect('sx-bol.eu', 80)
    self.Url = url
    self.Started = false
    self.LastPrint = ""
    self.File = ""
end

function VPredLibUpdate:Base64Encode(data)
    local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    return ((data:gsub('.', function(x)
        local r,b='',x:byte()
        for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
        return r;
    end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c=0
        for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
        return b:sub(c+1,c+1)
    end)..({ '', '==', '=' })[#data%3+1])
end

function VPredLibUpdate:GetOnlineVersion()
    if self.GotScriptVersion then return end

    self.Receive, self.Status, self.Snipped = self.Socket:receive(1024)
    if self.Status == 'timeout' and not self.Started then
        self.Started = true
        self.Socket:send("GET "..self.Url.." HTTP/1.1\r\nHost: sx-bol.eu\r\n\r\n")
    end
    if (self.Receive or (#self.Snipped > 0)) and not self.RecvStarted then
        self.RecvStarted = true
        self.DownloadStatus = 'Downloading VersionInfo (0%)'
    end

    self.File = self.File .. (self.Receive or self.Snipped)
    if self.File:find('</s'..'ize>') then
        if not self.Size then
            self.Size = tonumber(self.File:sub(self.File:find('<si'..'ze>')+6,self.File:find('</si'..'ze>')-1))
        end
        if self.File:find('<scr'..'ipt>') then
            local _,ScriptFind = self.File:find('<scr'..'ipt>')
            local ScriptEnd = self.File:find('</scr'..'ipt>')
            if ScriptEnd then ScriptEnd = ScriptEnd - 1 end
            local DownloadedSize = self.File:sub(ScriptFind+1,ScriptEnd or -1):len()
            self.DownloadStatus = 'Downloading VersionInfo ('..math.round(100/self.Size*DownloadedSize,2)..'%)'
        end
    end
    if self.File:find('</scr'..'ipt>') then
        self.DownloadStatus = 'Downloading VersionInfo (100%)'
        local a,b = self.File:find('\r\n\r\n')
        self.File = self.File:sub(a,-1)
        self.NewFile = ''
        for line,content in ipairs(self.File:split('\n')) do
            if content:len() > 5 then
                self.NewFile = self.NewFile .. content
            end
        end
        local HeaderEnd, ContentStart = self.File:find('<scr'..'ipt>')
        local ContentEnd, _ = self.File:find('</sc'..'ript>')
        if not ContentStart or not ContentEnd then
            if self.CallbackError and type(self.CallbackError) == 'function' then
                self.CallbackError()
            end
        else
            self.OnlineVersion = (Base64Decode(self.File:sub(ContentStart + 1,ContentEnd-1)))
            self.OnlineVersion = tonumber(self.OnlineVersion)
            if (self.OnlineVersion or 0) > self.LocalVersion then
                if self.CallbackNewVersion and type(self.CallbackNewVersion) == 'function' then
                    self.CallbackNewVersion(self.OnlineVersion,self.LocalVersion)
                end
                self:CreateSocket(self.ScriptPath)
                self.DownloadStatus = 'Connect to Server for ScriptDownload'
                AddTickCallback(function() self:DownloadUpdate() end)
            else
                if self.CallbackNoUpdate and type(self.CallbackNoUpdate) == 'function' then
                    self.CallbackNoUpdate(self.LocalVersion)
                end
            end
        end
        self.GotScriptVersion = true
    end
end

function VPredLibUpdate:DownloadUpdate()
    if self.GotVPredLibUpdate then return end
    self.Receive, self.Status, self.Snipped = self.Socket:receive(1024)
    if self.Status == 'timeout' and not self.Started then
        self.Started = true
        self.Socket:send("GET "..self.Url.." HTTP/1.1\r\nHost: sx-bol.eu\r\n\r\n")
    end
    if (self.Receive or (#self.Snipped > 0)) and not self.RecvStarted then
        self.RecvStarted = true
        self.DownloadStatus = 'Downloading Script (0%)'
    end

    self.File = self.File .. (self.Receive or self.Snipped)
    if self.File:find('</si'..'ze>') then
        if not self.Size then
            self.Size = tonumber(self.File:sub(self.File:find('<si'..'ze>')+6,self.File:find('</si'..'ze>')-1))
        end
        if self.File:find('<scr'..'ipt>') then
            local _,ScriptFind = self.File:find('<scr'..'ipt>')
            local ScriptEnd = self.File:find('</scr'..'ipt>')
            if ScriptEnd then ScriptEnd = ScriptEnd - 1 end
            local DownloadedSize = self.File:sub(ScriptFind+1,ScriptEnd or -1):len()
            self.DownloadStatus = 'Downloading Script ('..math.round(100/self.Size*DownloadedSize,2)..'%)'
        end
    end
    if self.File:find('</scr'..'ipt>') then
        self.DownloadStatus = 'Downloading Script (100%)'
        local a,b = self.File:find('\r\n\r\n')
        self.File = self.File:sub(a,-1)
        self.NewFile = ''
        for line,content in ipairs(self.File:split('\n')) do
            if content:len() > 5 then
                self.NewFile = self.NewFile .. content
            end
        end
        local HeaderEnd, ContentStart = self.NewFile:find('<sc'..'ript>')
        local ContentEnd, _ = self.NewFile:find('</scr'..'ipt>')
        if not ContentStart or not ContentEnd then
            if self.CallbackError and type(self.CallbackError) == 'function' then
                self.CallbackError()
            end
        else
            local newf = self.NewFile:sub(ContentStart+1,ContentEnd-1)
            local newf = newf:gsub('\r','')
            if newf:len() ~= self.Size then
                if self.CallbackError and type(self.CallbackError) == 'function' then
                    self.CallbackError()
                end
                return
            end
            local newf = Base64Decode(newf)
            if type(load(newf)) ~= 'function' then
                if self.CallbackError and type(self.CallbackError) == 'function' then
                    self.CallbackError()
                end
            else
                local f = io.open(self.SavePath,"w+b")
                f:write(newf)
                f:close()
                if self.CallbackUpdate and type(self.CallbackUpdate) == 'function' then
                    self.CallbackUpdate(self.OnlineVersion,self.LocalVersion)
                end
            end
        end
        self.GotVPredLibUpdate = true
    end
end
function VPredUpdate()
    local ToUpdate = {}
    ToUpdate.Version = version
    ToUpdate.UseHttps = true
    ToUpdate.Host = "raw.githubusercontent.com"
    ToUpdate.VersionPath = "/SidaBoL/Scripts/master/Common/VPrediction.version"
    ToUpdate.ScriptPath =  "/SidaBoL/Scripts/master/Common/VPrediction.lua"
    ToUpdate.SavePath = LIB_PATH.."VPrediction.lua"
    ToUpdate.CallbackUpdate = function(NewVersion,OldVersion) AutoupdaterMsg("VPrediction succesfully updated! Restart to use new version.") end
    ToUpdate.CallbackNoUpdate = function(OldVersion) AutoupdaterMsg(" v"..version.." loaded") end
    ToUpdate.CallbackNewVersion = function(NewVersion) AutoupdaterMsg("New version found. Downloading now.") end
    ToUpdate.CallbackError = function(NewVersion) AutoupdaterMsg("Error updating your VPrediction download it manually.") end
    VPredLibUpdate(ToUpdate.Version,ToUpdate.UseHttps, ToUpdate.Host, ToUpdate.VersionPath, ToUpdate.ScriptPath, ToUpdate.SavePath, ToUpdate.CallbackUpdate,ToUpdate.CallbackNoUpdate, ToUpdate.CallbackNewVersion,ToUpdate.CallbackError)
end
if AUTO_UPDATE then VPredUpdate() end

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
local minionTar = {}
--[[
local canPackets = VIP_USER and GetGameVersion and GetGameVersion():sub(1,4) == "5.22"

local lshift, rshift, band, bxor, DwordToFloat, missileTarget = bit32.lshift, bit32.rshift, bit32.band, bit32.bxor, DwordToFloat, {}
if canPackets then
    AddLoadCallback(function() L5_122() end) --Credits to PewPewPew and Redprince
    class 'L5_122'
    function L5_122:__init()
        self.Bytes = {[0x01] = 0x39,[0x02] = 0x38,[0x03] = 0x36,[0x04] = 0xB7,[0x05] = 0xB9,[0x06] = 0xB8,[0x07] = 0xB6,[0x08] = 0xF7,[0x09] = 0xF9,[0x0A] = 0xF8,[0x0B] = 0xF6,[0x0C] = 0x77,[0x0D] = 0x79,[0x0E] = 0x78,[0x0F] = 0x76,[0x10] = 0x57,[0x11] = 0x59,[0x12] = 0x58,[0x13] = 0x56,[0x14] = 0xD7,[0x15] = 0xD9,[0x16] = 0xD8,[0x17] = 0xD6,[0x18] = 0x17,[0x19] = 0x19,[0x1A] = 0x18,[0x1B] = 0x16,[0x1C] = 0x97,[0x1D] = 0x99,[0x1E] = 0x98,[0x1F] = 0x96,[0x20] = 0x67,[0x21] = 0x69,[0x22] = 0x68,[0x23] = 0x66,[0x24] = 0xE7,[0x25] = 0xE9,[0x26] = 0xE8,[0x27] = 0xE6,[0x28] = 0x27,[0x29] = 0x29,[0x2A] = 0x28,[0x2B] = 0x26,[0x2C] = 0xA7,[0x2D] = 0xA9,[0x2E] = 0xA8,[0x2F] = 0xA6,[0x30] = 0x4B,[0x31] = 0x4D,[0x32] = 0x4C,[0x33] = 0x4A,[0x34] = 0xCB,[0x35] = 0xCD,[0x36] = 0xCC,[0x37] = 0xCA,[0x38] = 0x0B,[0x39] = 0x0D,[0x3A] = 0x0C,[0x3B] = 0x0A,[0x3C] = 0x8B,[0x3D] = 0x8D,[0x3E] = 0x8C,[0x3F] = 0x8A,[0x40] = 0x30,[0x41] = 0x2E,[0x42] = 0x31,[0x43] = 0x2F,[0x44] = 0xB0,[0x45] = 0xAE,[0x46] = 0xB1,[0x47] = 0xAF,[0x48] = 0xF0,[0x49] = 0xEE,[0x4A] = 0xF1,[0x4B] = 0xEF,[0x4C] = 0x70,[0x4D] = 0x6E,[0x4E] = 0x71,[0x4F] = 0x6F,[0x50] = 0x50,[0x51] = 0x4E,[0x52] = 0x51,[0x53] = 0x4F,[0x54] = 0xD0,[0x55] = 0xCE,[0x56] = 0xD1,[0x57] = 0xCF,[0x58] = 0x10,[0x59] = 0x0E,[0x5A] = 0x11,[0x5B] = 0x0F,[0x5C] = 0x90,[0x5D] = 0x8E,[0x5E] = 0x91,[0x5F] = 0x8F,[0x60] = 0x60,[0x61] = 0x5E,[0x62] = 0x61,[0x63] = 0x5F,[0x64] = 0xE0,[0x65] = 0xDE,[0x66] = 0xE1,[0x67] = 0xDF,[0x68] = 0x20,[0x69] = 0x1E,[0x6A] = 0x21,[0x6B] = 0x1F,[0x6C] = 0xA0,[0x6D] = 0x9E,[0x6E] = 0xA1,[0x6F] = 0x9F,[0x70] = 0x44,[0x71] = 0x42,[0x72] = 0x45,[0x73] = 0x43,[0x74] = 0xC4,[0x75] = 0xC2,[0x76] = 0xC5,[0x77] = 0xC3,[0x78] = 0x04,[0x79] = 0x02,[0x7A] = 0x05,[0x7B] = 0x03,[0x7C] = 0x84,[0x7D] = 0x82,[0x7E] = 0x85,[0x7F] = 0x83,[0x80] = 0x3B,[0x81] = 0x3D,[0x82] = 0x3C,[0x83] = 0x3A,[0x84] = 0xBB,[0x85] = 0xBD,[0x86] = 0xBC,[0x87] = 0xBA,[0x88] = 0xFB,[0x89] = 0xFD,[0x8A] = 0xFC,[0x8B] = 0xFA,[0x8C] = 0x7B,[0x8D] = 0x7D,[0x8E] = 0x7C,[0x8F] = 0x7A,[0x90] = 0x5B,[0x91] = 0x5D,[0x92] = 0x5C,[0x93] = 0x5A,[0x94] = 0xDB,[0x95] = 0xDD,[0x96] = 0xDC,[0x97] = 0xDA,[0x98] = 0x1B,[0x99] = 0x1D,[0x9A] = 0x1C,[0x9B] = 0x1A,[0x9C] = 0x9B,[0x9D] = 0x9D,[0x9E] = 0x9C,[0x9F] = 0x9A,[0xA0] = 0x6B,[0xA1] = 0x6D,[0xA2] = 0x6C,[0xA3] = 0x6A,[0xA4] = 0xEB,[0xA5] = 0xED,[0xA6] = 0xEC,[0xA7] = 0xEA,[0xA8] = 0x2B,[0xA9] = 0x2D,[0xAA] = 0x2C,[0xAB] = 0x2A,[0xAC] = 0xAB,[0xAD] = 0xAD,[0xAE] = 0xAC,[0xAF] = 0xAA,[0xB0] = 0x40,[0xB1] = 0x3E,[0xB2] = 0x41,[0xB3] = 0x3F,[0xB4] = 0xC0,[0xB5] = 0xBE,[0xB6] = 0xC1,[0xB7] = 0xBF,[0xB8] = 0x00,[0xB9] = 0xFE,[0xBA] = 0x01,[0xBB] = 0xFF,[0xBC] = 0x80,[0xBD] = 0x7E,[0xBE] = 0x81,[0xBF] = 0x7F,[0xC0] = 0x34,[0xC1] = 0x32,[0xC2] = 0x35,[0xC3] = 0x33,[0xC4] = 0xB4,[0xC5] = 0xB2,[0xC6] = 0xB5,[0xC7] = 0xB3,[0xC8] = 0xF4,[0xC9] = 0xF2,[0xCA] = 0xF5,[0xCB] = 0xF3,[0xCC] = 0x74,[0xCD] = 0x72,[0xCE] = 0x75,[0xCF] = 0x73,[0xD0] = 0x54,[0xD1] = 0x52,[0xD2] = 0x55,[0xD3] = 0x53,[0xD4] = 0xD4,[0xD5] = 0xD2,[0xD6] = 0xD5,[0xD7] = 0xD3,[0xD8] = 0x14,[0xD9] = 0x12,[0xDA] = 0x15,[0xDB] = 0x13,[0xDC] = 0x94,[0xDD] = 0x92,[0xDE] = 0x95,[0xDF] = 0x93,[0xE0] = 0x64,[0xE1] = 0x62,[0xE2] = 0x65,[0xE3] = 0x63,[0xE4] = 0xE4,[0xE5] = 0xE2,[0xE6] = 0xE5,[0xE7] = 0xE3,[0xE8] = 0x24,[0xE9] = 0x22,[0xEA] = 0x25,[0xEB] = 0x23,[0xEC] = 0xA4,[0xED] = 0xA2,[0xEE] = 0xA5,[0xEF] = 0xA3,[0xF0] = 0x48,[0xF1] = 0x46,[0xF2] = 0x49,[0xF3] = 0x47,[0xF4] = 0xC8,[0xF5] = 0xC6,[0xF6] = 0xC9,[0xF7] = 0xC7,[0xF8] = 0x08,[0xF9] = 0x06,[0xFA] = 0x09,[0xFB] = 0x07,[0xFC] = 0x88,[0xFD] = 0x86,[0xFE] = 0x89,[0xFF] = 0x87,[0x00] = 0x37,}

        AddRecvPacketCallback2(function(p)
            if p.header == 0x0013 then
                p.pos = 23
                local target = objManager:GetObjectByNetworkId(self:Float(p, self.Bytes))
                p.pos = 2
                local source = objManager:GetObjectByNetworkId(p:DecodeF())
                if target ~= nil and source ~= nil and target.valid and source.valid and source.type ~= myHero.type and target.type == 'obj_AI_Minion' and source.team == myHero.team then
                    missileTarget[source.networkID] = target
                end
            end
        end)
    end

    function L5_122:Float(p, tbl)
        local b = {}
        for i=4, 1, -1 do b[i] = tbl[p:Decode1()]    end
        return DwordToFloat(bxor(lshift(band(b[1],0xFF),24),lshift(band(b[2],0xFF),16),lshift(band(b[3],0xFF),8),band(b[4],0xFF)))
    end
end]]

function GetAggro(unit)
    if unit.spell and unit.spell.target then
        return unit.spell.target
    else
        return minionTar[unit.networkID] and minionTar[unit.networkID] or nil
    end
 --[[ if canPackets then
        return type(unit) == "number" and missileTarget[unit] or missileTarget[unit.networkID]
    else
        return minionTar[unit.networkID] and minionTar[unit.networkID] or nil
    end]]
end

local _FAST, _MEDIUM, _SLOW = 1, 2, 3
local PA = {}

for i, champ in pairs(GetEnemyHeroes()) do
    PA[champ.networkID] = {}
end
PA[myHero.networkID] = {}
class 'VPrediction' --{
function VPrediction:__init()
    self.version = tonumber(version)
    self.showdevmode = false
    self.hitboxes = {['Braum'] = 80, ['RecItemsCLASSIC'] = 65, ['TeemoMushroom'] = 50.0, ['TestCubeRender'] = 65, ['Xerath'] = 65, ['Kassadin'] = 65, ['Rengar'] = 65, ['Thresh'] = 55.0, ['RecItemsTUTORIAL'] = 65, ['Ziggs'] = 55.0, ['ZyraPassive'] = 20.0, ['ZyraThornPlant'] = 20.0, ['KogMaw'] = 65, ['HeimerTBlue'] = 35.0, ['EliseSpider'] = 65, ['Skarner'] = 80.0, ['ChaosNexus'] = 65, ['Katarina'] = 65, ['Riven'] = 65, ['SightWard'] = 1, ['HeimerTYellow'] = 35.0, ['Ashe'] = 65, ['VisionWard'] = 1, ['TT_NGolem2'] = 80.0, ['ThreshLantern'] = 65, ['RecItemsCLASSICMap10'] = 65, ['RecItemsODIN'] = 65, ['TT_Spiderboss'] = 200.0, ['RecItemsARAM'] = 65, ['OrderNexus'] = 65, ['Soraka'] = 65, ['Jinx'] = 65, ['TestCubeRenderwCollision'] = 65, ['Red_Minion_Wizard'] = 48.0, ['JarvanIV'] = 65, ['Blue_Minion_Wizard'] = 48.0, ['TT_ChaosTurret2'] = 88.4, ['TT_ChaosTurret3'] = 88.4, ['TT_ChaosTurret1'] = 88.4, ['ChaosTurretGiant'] = 88.4, ['Dragon'] = 100.0, ['LuluSnowman'] = 50.0, ['Worm'] = 100.0, ['ChaosTurretWorm'] = 88.4, ['TT_ChaosInhibitor'] = 65, ['ChaosTurretNormal'] = 88.4, ['AncientGolem'] = 100.0, ['ZyraGraspingPlant'] = 20.0, ['HA_AP_OrderTurret3'] = 88.4, ['HA_AP_OrderTurret2'] = 88.4, ['Tryndamere'] = 65, ['OrderTurretNormal2'] = 88.4, ['Singed'] = 65, ['OrderInhibitor'] = 65, ['Diana'] = 65, ['HA_FB_HealthRelic'] = 65, ['TT_OrderInhibitor'] = 65, ['GreatWraith'] = 80.0, ['Yasuo'] = 65, ['OrderTurretDragon'] = 88.4, ['OrderTurretNormal'] = 88.4, ['LizardElder'] = 65.0, ['HA_AP_ChaosTurret'] = 88.4, ['Ahri'] = 65, ['Lulu'] = 65, ['ChaosInhibitor'] = 65, ['HA_AP_ChaosTurret3'] = 88.4, ['HA_AP_ChaosTurret2'] = 88.4, ['ChaosTurretWorm2'] = 88.4, ['TT_OrderTurret1'] = 88.4, ['TT_OrderTurret2'] = 88.4, ['TT_OrderTurret3'] = 88.4, ['LuluFaerie'] = 65, ['HA_AP_OrderTurret'] = 88.4, ['OrderTurretAngel'] = 88.4, ['YellowTrinketUpgrade'] = 1, ['MasterYi'] = 65, ['Lissandra'] = 65, ['ARAMOrderTurretNexus'] = 88.4, ['Draven'] = 65, ['FiddleSticks'] = 65, ['SmallGolem'] = 80.0, ['ARAMOrderTurretFront'] = 88.4, ['ChaosTurretTutorial'] = 88.4, ['NasusUlt'] = 80.0, ['Maokai'] = 80.0, ['Wraith'] = 50.0, ['Wolf'] = 50.0, ['Sivir'] = 65, ['Corki'] = 65, ['Janna'] = 65, ['Nasus'] = 80.0, ['Golem'] = 80.0, ['ARAMChaosTurretFront'] = 88.4, ['ARAMOrderTurretInhib'] = 88.4, ['LeeSin'] = 65, ['HA_AP_ChaosTurretTutorial'] = 88.4, ['GiantWolf'] = 65.0, ['HA_AP_OrderTurretTutorial'] = 88.4, ['YoungLizard'] = 50.0, ['Jax'] = 65, ['LesserWraith'] = 50.0, ['Blitzcrank'] = 80.0, ['brush_D_SR'] = 65, ['brush_E_SR'] = 65, ['brush_F_SR'] = 65, ['brush_C_SR'] = 65, ['brush_A_SR'] = 65, ['brush_B_SR'] = 65, ['ARAMChaosTurretInhib'] = 88.4, ['Shen'] = 65, ['Nocturne'] = 65, ['Sona'] = 65, ['ARAMChaosTurretNexus'] = 88.4, ['YellowTrinket'] = 1, ['OrderTurretTutorial'] = 88.4, ['Caitlyn'] = 65, ['Trundle'] = 65, ['Malphite'] = 80.0, ['Mordekaiser'] = 80.0, ['ZyraSeed'] = 65, ['Vi'] = 50, ['Tutorial_Red_Minion_Wizard'] = 48.0, ['Renekton'] = 80.0, ['Anivia'] = 65, ['Fizz'] = 65, ['Heimerdinger'] = 55.0, ['Evelynn'] = 65, ['Rumble'] = 80.0, ['Leblanc'] = 65, ['Darius'] = 80.0, ['OlafAxe'] = 50.0, ['Viktor'] = 65, ['XinZhao'] = 65, ['Orianna'] = 65, ['Vladimir'] = 65, ['Nidalee'] = 65, ['Tutorial_Red_Minion_Basic'] = 48.0, ['ZedShadow'] = 65, ['Syndra'] = 65, ['Zac'] = 80.0, ['Olaf'] = 65, ['Veigar'] = 55.0, ['Twitch'] = 65, ['Alistar'] = 80.0, ['Akali'] = 65, ['Urgot'] = 80.0, ['Leona'] = 65, ['Talon'] = 65, ['Karma'] = 65, ['Jayce'] = 65, ['Galio'] = 80.0, ['Shaco'] = 65, ['Taric'] = 65, ['TwistedFate'] = 65, ['Varus'] = 65, ['Garen'] = 65, ['Swain'] = 65, ['Vayne'] = 65, ['Fiora'] = 65, ['Quinn'] = 65, ['Kayle'] = 65, ['Blue_Minion_Basic'] = 48.0, ['Brand'] = 65, ['Teemo'] = 55.0, ['Amumu'] = 55.0, ['Annie'] = 55.0, ['Odin_Blue_Minion_caster'] = 48.0, ['Elise'] = 65, ['Nami'] = 65, ['Poppy'] = 55.0, ['AniviaEgg'] = 65, ['Tristana'] = 55.0, ['Graves'] = 65, ['Morgana'] = 65, ['Gragas'] = 80.0, ['MissFortune'] = 65, ['Warwick'] = 65, ['Cassiopeia'] = 65, ['Tutorial_Blue_Minion_Wizard'] = 48.0, ['DrMundo'] = 80.0, ['Volibear'] = 80.0, ['Irelia'] = 65, ['Odin_Red_Minion_Caster'] = 48.0, ['Lucian'] = 65, ['Yorick'] = 80.0, ['RammusPB'] = 65, ['Red_Minion_Basic'] = 48.0, ['Udyr'] = 65, ['MonkeyKing'] = 65, ['Tutorial_Blue_Minion_Basic'] = 48.0, ['Kennen'] = 55.0, ['Nunu'] = 65, ['Ryze'] = 65, ['Zed'] = 65, ['Nautilus'] = 80.0, ['Gangplank'] = 65, ['shopevo'] = 65, ['Lux'] = 65, ['Sejuani'] = 80.0, ['Ezreal'] = 65, ['OdinNeutralGuardian'] = 65, ['Khazix'] = 65, ['Sion'] = 80.0, ['Aatrox'] = 65, ['Hecarim'] = 80.0, ['Pantheon'] = 65, ['Shyvana'] = 50.0, ['Zyra'] = 65, ['Karthus'] = 65, ['Rammus'] = 65, ['Zilean'] = 65, ['Chogath'] = 80.0, ['Malzahar'] = 65, ['YorickRavenousGhoul'] = 1.0, ['YorickSpectralGhoul'] = 1.0, ['JinxMine'] = 65, ['YorickDecayedGhoul'] = 1.0, ['XerathArcaneBarrageLauncher'] = 65, ['Odin_SOG_Order_Crystal'] = 65, ['TestCube'] = 65, ['ShyvanaDragon'] = 80.0, ['FizzBait'] = 65, ['ShopKeeper'] = 65, ['Blue_Minion_MechMelee'] = 65.0, ['OdinQuestBuff'] = 65, ['TT_Buffplat_L'] = 65, ['TT_Buffplat_R'] = 65, ['KogMawDead'] = 65, ['TempMovableChar'] = 48.0, ['Lizard'] = 50.0, ['GolemOdin'] = 80.0, ['OdinOpeningBarrier'] = 65, ['TT_ChaosTurret4'] = 88.4, ['TT_Flytrap_A'] = 65, ['TT_Chains_Order_Periph'] = 65, ['TT_NWolf'] = 65.0, ['ShopMale'] = 65, ['OdinShieldRelic'] = 65, ['TT_Chains_Xaos_Base'] = 65, ['LuluSquill'] = 50.0, ['TT_Shopkeeper'] = 65, ['redDragon'] = 100.0, ['MonkeyKingClone'] = 65, ['Odin_skeleton'] = 65, ['OdinChaosTurretShrine'] = 88.4, ['Cassiopeia_Death'] = 65, ['OdinCenterRelic'] = 48.0, ['Ezreal_cyber_1'] = 65, ['Ezreal_cyber_3'] = 65, ['Ezreal_cyber_2'] = 65, ['OdinRedSuperminion'] = 55.0, ['TT_Speedshrine_Gears'] = 65, ['JarvanIVWall'] = 65, ['DestroyedNexus'] = 65, ['ARAMOrderNexus'] = 65, ['Red_Minion_MechCannon'] = 65.0, ['OdinBlueSuperminion'] = 55.0, ['SyndraOrbs'] = 65, ['LuluKitty'] = 50.0, ['SwainNoBird'] = 65, ['LuluLadybug'] = 50.0, ['CaitlynTrap'] = 65, ['TT_Shroom_A'] = 65, ['ARAMChaosTurretShrine'] = 88.4, ['Odin_Windmill_Propellers'] = 65, ['DestroyedInhibitor'] = 65, ['TT_NWolf2'] = 50.0, ['OdinMinionGraveyardPortal'] = 1.0, ['SwainBeam'] = 65, ['Summoner_Rider_Order'] = 65.0, ['TT_Relic'] = 65, ['odin_lifts_crystal'] = 65, ['OdinOrderTurretShrine'] = 88.4, ['SpellBook1'] = 65, ['Blue_Minion_MechCannon'] = 65.0, ['TT_ChaosInhibitor_D'] = 65, ['Odin_SoG_Chaos'] = 65, ['TrundleWall'] = 65, ['HA_AP_HealthRelic'] = 65, ['OrderTurretShrine'] = 88.4, ['OriannaBall'] = 48.0, ['ChaosTurretShrine'] = 88.4, ['LuluCupcake'] = 50.0, ['HA_AP_ChaosTurretShrine'] = 88.4, ['TT_Chains_Bot_Lane'] = 65, ['TT_NWraith2'] = 50.0, ['TT_Tree_A'] = 65, ['SummonerBeacon'] = 65, ['Odin_Drill'] = 65, ['TT_NGolem'] = 80.0, ['Shop'] = 65, ['AramSpeedShrine'] = 65, ['DestroyedTower'] = 65, ['OriannaNoBall'] = 65, ['Odin_Minecart'] = 65, ['Summoner_Rider_Chaos'] = 65.0, ['OdinSpeedShrine'] = 65, ['TT_Brazier'] = 65, ['TT_SpeedShrine'] = 65, ['odin_lifts_buckets'] = 65, ['OdinRockSaw'] = 65, ['OdinMinionSpawnPortal'] = 1.0, ['SyndraSphere'] = 48.0, ['TT_Nexus_Gears'] = 65, ['Red_Minion_MechMelee'] = 65.0, ['SwainRaven'] = 65, ['crystal_platform'] = 65, ['MaokaiSproutling'] = 48.0, ['Urf'] = 65, ['TestCubeRender10Vision'] = 65, ['MalzaharVoidling'] = 10.0, ['GhostWard'] = 1, ['MonkeyKingFlying'] = 65, ['LuluPig'] = 50.0, ['AniviaIceBlock'] = 65, ['TT_OrderInhibitor_D'] = 65, ['yonkey'] = 65, ['Odin_SoG_Order'] = 65, ['RammusDBC'] = 65, ['FizzShark'] = 65, ['LuluDragon'] = 50.0, ['OdinTestCubeRender'] = 65, ['OdinCrane'] = 65, ['TT_Tree1'] = 65, ['ARAMOrderTurretShrine'] = 88.4, ['TT_Chains_Order_Base'] = 65, ['Odin_Windmill_Gears'] = 65, ['ARAMChaosNexus'] = 65, ['TT_NWraith'] = 50.0, ['TT_OrderTurret4'] = 88.4, ['Odin_SOG_Chaos_Crystal'] = 65, ['TT_SpiderLayer_Web'] = 65, ['OdinQuestIndicator'] = 1.0, ['JarvanIVStandard'] = 65, ['TT_DummyPusher'] = 65, ['OdinClaw'] = 65, ['EliseSpiderling'] = 1.0, ['QuinnValor'] = 65, ['UdyrTigerUlt'] = 65, ['UdyrTurtleUlt'] = 65, ['UdyrUlt'] = 65, ['UdyrPhoenixUlt'] = 65, ['ShacoBox'] = 10, ['HA_AP_Poro'] = 65, ['AnnieTibbers'] = 80.0, ['UdyrPhoenix'] = 65, ['UdyrTurtle'] = 65, ['UdyrTiger'] = 65, ['HA_AP_OrderShrineTurret'] = 88.4, ['HA_AP_OrderTurretRubble'] = 65, ['HA_AP_Chains_Long'] = 65, ['HA_AP_OrderCloth'] = 65, ['HA_AP_PeriphBridge'] = 65, ['HA_AP_BridgeLaneStatue'] = 65, ['HA_AP_ChaosTurretRubble'] = 88.4, ['HA_AP_BannerMidBridge'] = 65, ['HA_AP_PoroSpawner'] = 50.0, ['HA_AP_Cutaway'] = 65, ['HA_AP_Chains'] = 65, ['HA_AP_ShpSouth'] = 65, ['HA_AP_HeroTower'] = 65, ['HA_AP_ShpNorth'] = 65, ['ChaosInhibitor_D'] = 65, ['ZacRebirthBloblet'] = 65, ['OrderInhibitor_D'] = 65, ['Nidalee_Spear'] = 65, ['Nidalee_Cougar'] = 65, ['TT_Buffplat_Chain'] = 65, ['WriggleLantern'] = 1, ['TwistedLizardElder'] = 65.0, ['RabidWolf'] = 65.0, ['HeimerTGreen'] = 50.0, ['HeimerTRed'] = 50.0, ['ViktorFF'] = 65, ['TwistedGolem'] = 80.0, ['TwistedSmallWolf'] = 50.0, ['TwistedGiantWolf'] = 65.0, ['TwistedTinyWraith'] = 50.0, ['TwistedBlueWraith'] = 50.0, ['TwistedYoungLizard'] = 50.0, ['Red_Minion_Melee'] = 48.0, ['Blue_Minion_Melee'] = 48.0, ['Blue_Minion_Healer'] = 48.0, ['Ghast'] = 60.0, ['blueDragon'] = 100.0, ['Red_Minion_MechRange'] = 65.0, ['Test_CubeSphere'] = 65,}
    self.projectilespeeds = {["Velkoz"]= 2000,["TeemoMushroom"] = math.huge,["TestCubeRender"] = math.huge ,["Xerath"] = 2000.0000 ,["Kassadin"] = math.huge ,["Rengar"] = math.huge ,["Thresh"] = 1000.0000 ,["Ziggs"] = 1500.0000 ,["ZyraPassive"] = 1500.0000 ,["ZyraThornPlant"] = 1500.0000 ,["KogMaw"] = 1800.0000 ,["HeimerTBlue"] = 1599.3999 ,["EliseSpider"] = 500.0000 ,["Skarner"] = 500.0000 ,["ChaosNexus"] = 500.0000 ,["Katarina"] = 467.0000 ,["Riven"] = 347.79999 ,["SightWard"] = 347.79999 ,["HeimerTYellow"] = 1599.3999 ,["Ashe"] = 2000.0000 ,["VisionWard"] = 2000.0000 ,["TT_NGolem2"] = math.huge ,["ThreshLantern"] = math.huge ,["TT_Spiderboss"] = math.huge ,["OrderNexus"] = math.huge ,["Soraka"] = 1000.0000 ,["Jinx"] = 2750.0000 ,["TestCubeRenderwCollision"] = 2750.0000 ,["Red_Minion_Wizard"] = 650.0000 ,["JarvanIV"] = 20.0000 ,["Blue_Minion_Wizard"] = 650.0000 ,["TT_ChaosTurret2"] = 1200.0000 ,["TT_ChaosTurret3"] = 1200.0000 ,["TT_ChaosTurret1"] = 1200.0000 ,["ChaosTurretGiant"] = 1200.0000 ,["Dragon"] = 1200.0000 ,["LuluSnowman"] = 1200.0000 ,["Worm"] = 1200.0000 ,["ChaosTurretWorm"] = 1200.0000 ,["TT_ChaosInhibitor"] = 1200.0000 ,["ChaosTurretNormal"] = 1200.0000 ,["AncientGolem"] = 500.0000 ,["ZyraGraspingPlant"] = 500.0000 ,["HA_AP_OrderTurret3"] = 1200.0000 ,["HA_AP_OrderTurret2"] = 1200.0000 ,["Tryndamere"] = 347.79999 ,["OrderTurretNormal2"] = 1200.0000 ,["Singed"] = 700.0000 ,["OrderInhibitor"] = 700.0000 ,["Diana"] = 347.79999 ,["HA_FB_HealthRelic"] = 347.79999 ,["TT_OrderInhibitor"] = 347.79999 ,["GreatWraith"] = 750.0000 ,["Yasuo"] = 347.79999 ,["OrderTurretDragon"] = 1200.0000 ,["OrderTurretNormal"] = 1200.0000 ,["LizardElder"] = 500.0000 ,["HA_AP_ChaosTurret"] = 1200.0000 ,["Ahri"] = 1750.0000 ,["Lulu"] = 1450.0000 ,["ChaosInhibitor"] = 1450.0000 ,["HA_AP_ChaosTurret3"] = 1200.0000 ,["HA_AP_ChaosTurret2"] = 1200.0000 ,["ChaosTurretWorm2"] = 1200.0000 ,["TT_OrderTurret1"] = 1200.0000 ,["TT_OrderTurret2"] = 1200.0000 ,["TT_OrderTurret3"] = 1200.0000 ,["LuluFaerie"] = 1200.0000 ,["HA_AP_OrderTurret"] = 1200.0000 ,["OrderTurretAngel"] = 1200.0000 ,["YellowTrinketUpgrade"] = 1200.0000 ,["MasterYi"] = math.huge ,["Lissandra"] = 2000.0000 ,["ARAMOrderTurretNexus"] = 1200.0000 ,["Draven"] = 1700.0000 ,["FiddleSticks"] = 1750.0000 ,["SmallGolem"] = math.huge ,["ARAMOrderTurretFront"] = 1200.0000 ,["ChaosTurretTutorial"] = 1200.0000 ,["NasusUlt"] = 1200.0000 ,["Maokai"] = math.huge ,["Wraith"] = 750.0000 ,["Wolf"] = math.huge ,["Sivir"] = 1750.0000 ,["Corki"] = 2000.0000 ,["Janna"] = 1200.0000 ,["Nasus"] = math.huge ,["Golem"] = math.huge ,["ARAMChaosTurretFront"] = 1200.0000 ,["ARAMOrderTurretInhib"] = 1200.0000 ,["LeeSin"] = math.huge ,["HA_AP_ChaosTurretTutorial"] = 1200.0000 ,["GiantWolf"] = math.huge ,["HA_AP_OrderTurretTutorial"] = 1200.0000 ,["YoungLizard"] = 750.0000 ,["Jax"] = 400.0000 ,["LesserWraith"] = math.huge ,["Blitzcrank"] = math.huge ,["ARAMChaosTurretInhib"] = 1200.0000 ,["Shen"] = 400.0000 ,["Nocturne"] = math.huge ,["Sona"] = 1500.0000 ,["ARAMChaosTurretNexus"] = 1200.0000 ,["YellowTrinket"] = 1200.0000 ,["OrderTurretTutorial"] = 1200.0000 ,["Caitlyn"] = 2500.0000 ,["Trundle"] = 347.79999 ,["Malphite"] = 1000.0000 ,["Mordekaiser"] = math.huge ,["ZyraSeed"] = math.huge ,["Vi"] = 1000.0000 ,["Tutorial_Red_Minion_Wizard"] = 650.0000 ,["Renekton"] = math.huge ,["Anivia"] = 1400.0000 ,["Fizz"] = math.huge ,["Heimerdinger"] = 1500.0000 ,["Evelynn"] = 467.0000 ,["Rumble"] = 347.79999 ,["Leblanc"] = 1700.0000 ,["Darius"] = math.huge ,["OlafAxe"] = math.huge ,["Viktor"] = 2300.0000 ,["XinZhao"] = 20.0000 ,["Orianna"] = 1450.0000 ,["Vladimir"] = 1400.0000 ,["Nidalee"] = 1750.0000 ,["Tutorial_Red_Minion_Basic"] = math.huge ,["ZedShadow"] = 467.0000 ,["Syndra"] = 1800.0000 ,["Zac"] = 1000.0000 ,["Olaf"] = 347.79999 ,["Veigar"] = 1100.0000 ,["Twitch"] = 2500.0000 ,["Alistar"] = math.huge ,["Akali"] = 467.0000 ,["Urgot"] = 1300.0000 ,["Leona"] = 347.79999 ,["Talon"] = math.huge ,["Karma"] = 1500.0000 ,["Jayce"] = 347.79999 ,["Galio"] = 1000.0000 ,["Shaco"] = math.huge ,["Taric"] = math.huge ,["TwistedFate"] = 1500.0000 ,["Varus"] = 2000.0000 ,["Garen"] = 347.79999 ,["Swain"] = 1600.0000 ,["Vayne"] = 2000.0000 ,["Fiora"] = 467.0000 ,["Quinn"] = 2000.0000 ,["Kayle"] = math.huge ,["Blue_Minion_Basic"] = math.huge ,["Brand"] = 2000.0000 ,["Teemo"] = 1300.0000 ,["Amumu"] = 500.0000 ,["Annie"] = 1200.0000 ,["Odin_Blue_Minion_caster"] = 1200.0000 ,["Elise"] = 1600.0000 ,["Nami"] = 1500.0000 ,["Poppy"] = 500.0000 ,["AniviaEgg"] = 500.0000 ,["Tristana"] = 2250.0000 ,["Graves"] = 3000.0000 ,["Morgana"] = 1600.0000 ,["Gragas"] = math.huge ,["MissFortune"] = 2000.0000 ,["Warwick"] = math.huge ,["Cassiopeia"] = 1200.0000 ,["Tutorial_Blue_Minion_Wizard"] = 650.0000 ,["DrMundo"] = math.huge ,["Volibear"] = 467.0000 ,["Irelia"] = 467.0000 ,["Odin_Red_Minion_Caster"] = 650.0000 ,["Lucian"] = 2800.0000 ,["Yorick"] = math.huge ,["RammusPB"] = math.huge ,["Red_Minion_Basic"] = math.huge ,["Udyr"] = 467.0000 ,["MonkeyKing"] = 20.0000 ,["Tutorial_Blue_Minion_Basic"] = math.huge ,["Kennen"] = 1600.0000 ,["Nunu"] = 500.0000 ,["Ryze"] = 2400.0000 ,["Zed"] = 467.0000 ,["Nautilus"] = 1000.0000 ,["Gangplank"] = 1000.0000 ,["Lux"] = 1600.0000 ,["Sejuani"] = 500.0000 ,["Ezreal"] = 2000.0000 ,["OdinNeutralGuardian"] = 1800.0000 ,["Khazix"] = 500.0000 ,["Sion"] = math.huge ,["Aatrox"] = 347.79999 ,["Hecarim"] = 500.0000 ,["Pantheon"] = 20.0000 ,["Shyvana"] = 467.0000 ,["Zyra"] = 1700.0000 ,["Karthus"] = 1200.0000 ,["Rammus"] = math.huge ,["Zilean"] = 1200.0000 ,["Chogath"] = 500.0000 ,["Malzahar"] = 2000.0000 ,["YorickRavenousGhoul"] = 347.79999 ,["YorickSpectralGhoul"] = 347.79999 ,["JinxMine"] = 347.79999 ,["YorickDecayedGhoul"] = 347.79999 ,["XerathArcaneBarrageLauncher"] = 347.79999 ,["Odin_SOG_Order_Crystal"] = 347.79999 ,["TestCube"] = 347.79999 ,["ShyvanaDragon"] = math.huge ,["FizzBait"] = math.huge ,["Blue_Minion_MechMelee"] = math.huge ,["OdinQuestBuff"] = math.huge ,["TT_Buffplat_L"] = math.huge ,["TT_Buffplat_R"] = math.huge ,["KogMawDead"] = math.huge ,["TempMovableChar"] = math.huge ,["Lizard"] = 500.0000 ,["GolemOdin"] = math.huge ,["OdinOpeningBarrier"] = math.huge ,["TT_ChaosTurret4"] = 500.0000 ,["TT_Flytrap_A"] = 500.0000 ,["TT_NWolf"] = math.huge ,["OdinShieldRelic"] = math.huge ,["LuluSquill"] = math.huge ,["redDragon"] = math.huge ,["MonkeyKingClone"] = math.huge ,["Odin_skeleton"] = math.huge ,["OdinChaosTurretShrine"] = 500.0000 ,["Cassiopeia_Death"] = 500.0000 ,["OdinCenterRelic"] = 500.0000 ,["OdinRedSuperminion"] = math.huge ,["JarvanIVWall"] = math.huge ,["ARAMOrderNexus"] = math.huge ,["Red_Minion_MechCannon"] = 1200.0000 ,["OdinBlueSuperminion"] = math.huge ,["SyndraOrbs"] = math.huge ,["LuluKitty"] = math.huge ,["SwainNoBird"] = math.huge ,["LuluLadybug"] = math.huge ,["CaitlynTrap"] = math.huge ,["TT_Shroom_A"] = math.huge ,["ARAMChaosTurretShrine"] = 500.0000 ,["Odin_Windmill_Propellers"] = 500.0000 ,["TT_NWolf2"] = math.huge ,["OdinMinionGraveyardPortal"] = math.huge ,["SwainBeam"] = math.huge ,["Summoner_Rider_Order"] = math.huge ,["TT_Relic"] = math.huge ,["odin_lifts_crystal"] = math.huge ,["OdinOrderTurretShrine"] = 500.0000 ,["SpellBook1"] = 500.0000 ,["Blue_Minion_MechCannon"] = 1200.0000 ,["TT_ChaosInhibitor_D"] = 1200.0000 ,["Odin_SoG_Chaos"] = 1200.0000 ,["TrundleWall"] = 1200.0000 ,["HA_AP_HealthRelic"] = 1200.0000 ,["OrderTurretShrine"] = 500.0000 ,["OriannaBall"] = 500.0000 ,["ChaosTurretShrine"] = 500.0000 ,["LuluCupcake"] = 500.0000 ,["HA_AP_ChaosTurretShrine"] = 500.0000 ,["TT_NWraith2"] = 750.0000 ,["TT_Tree_A"] = 750.0000 ,["SummonerBeacon"] = 750.0000 ,["Odin_Drill"] = 750.0000 ,["TT_NGolem"] = math.huge ,["AramSpeedShrine"] = math.huge ,["OriannaNoBall"] = math.huge ,["Odin_Minecart"] = math.huge ,["Summoner_Rider_Chaos"] = math.huge ,["OdinSpeedShrine"] = math.huge ,["TT_SpeedShrine"] = math.huge ,["odin_lifts_buckets"] = math.huge ,["OdinRockSaw"] = math.huge ,["OdinMinionSpawnPortal"] = math.huge ,["SyndraSphere"] = math.huge ,["Red_Minion_MechMelee"] = math.huge ,["SwainRaven"] = math.huge ,["crystal_platform"] = math.huge ,["MaokaiSproutling"] = math.huge ,["Urf"] = math.huge ,["TestCubeRender10Vision"] = math.huge ,["MalzaharVoidling"] = 500.0000 ,["GhostWard"] = 500.0000 ,["MonkeyKingFlying"] = 500.0000 ,["LuluPig"] = 500.0000 ,["AniviaIceBlock"] = 500.0000 ,["TT_OrderInhibitor_D"] = 500.0000 ,["Odin_SoG_Order"] = 500.0000 ,["RammusDBC"] = 500.0000 ,["FizzShark"] = 500.0000 ,["LuluDragon"] = 500.0000 ,["OdinTestCubeRender"] = 500.0000 ,["TT_Tree1"] = 500.0000 ,["ARAMOrderTurretShrine"] = 500.0000 ,["Odin_Windmill_Gears"] = 500.0000 ,["ARAMChaosNexus"] = 500.0000 ,["TT_NWraith"] = 750.0000 ,["TT_OrderTurret4"] = 500.0000 ,["Odin_SOG_Chaos_Crystal"] = 500.0000 ,["OdinQuestIndicator"] = 500.0000 ,["JarvanIVStandard"] = 500.0000 ,["TT_DummyPusher"] = 500.0000 ,["OdinClaw"] = 500.0000 ,["EliseSpiderling"] = 2000.0000 ,["QuinnValor"] = math.huge ,["UdyrTigerUlt"] = math.huge ,["UdyrTurtleUlt"] = math.huge ,["UdyrUlt"] = math.huge ,["UdyrPhoenixUlt"] = math.huge ,["ShacoBox"] = 1500.0000 ,["HA_AP_Poro"] = 1500.0000 ,["AnnieTibbers"] = math.huge ,["UdyrPhoenix"] = math.huge ,["UdyrTurtle"] = math.huge ,["UdyrTiger"] = math.huge ,["HA_AP_OrderShrineTurret"] = 500.0000 ,["HA_AP_Chains_Long"] = 500.0000 ,["HA_AP_BridgeLaneStatue"] = 500.0000 ,["HA_AP_ChaosTurretRubble"] = 500.0000 ,["HA_AP_PoroSpawner"] = 500.0000 ,["HA_AP_Cutaway"] = 500.0000 ,["HA_AP_Chains"] = 500.0000 ,["ChaosInhibitor_D"] = 500.0000 ,["ZacRebirthBloblet"] = 500.0000 ,["OrderInhibitor_D"] = 500.0000 ,["Nidalee_Spear"] = 500.0000 ,["Nidalee_Cougar"] = 500.0000 ,["TT_Buffplat_Chain"] = 500.0000 ,["WriggleLantern"] = 500.0000 ,["TwistedLizardElder"] = 500.0000 ,["RabidWolf"] = math.huge ,["HeimerTGreen"] = 1599.3999 ,["HeimerTRed"] = 1599.3999 ,["ViktorFF"] = 1599.3999 ,["TwistedGolem"] = math.huge ,["TwistedSmallWolf"] = math.huge ,["TwistedGiantWolf"] = math.huge ,["TwistedTinyWraith"] = 750.0000 ,["TwistedBlueWraith"] = 750.0000 ,["TwistedYoungLizard"] = 750.0000 ,["Red_Minion_Melee"] = math.huge ,["Blue_Minion_Melee"] = math.huge ,["Blue_Minion_Healer"] = 1000.0000 ,["Ghast"] = 750.0000 ,["blueDragon"] = 800.0000 ,["Red_Minion_MechRange"] = 3000, ["SRU_OrderMinionRanged"] = 650, ["SRU_ChaosMinionRanged"] = 650, ["SRU_OrderMinionSiege"] = 1200, ["SRU_ChaosMinionSiege"] = 1200, ["SRUAP_Turret_Chaos1"]  = 1200, ["SRUAP_Turret_Chaos2"]  = 1200, ["SRUAP_Turret_Chaos3"] = 1200, ["SRUAP_Turret_Order1"]  = 1200, ["SRUAP_Turret_Order2"]  = 1200, ["SRUAP_Turret_Order3"] = 1200, ["SRUAP_Turret_Chaos4"] = 1200, ["SRUAP_Turret_Chaos5"] = 500, ["SRUAP_Turret_Order4"] = 1200, ["SRUAP_Turret_Order5"] = 500 }

    self.ActiveAttacks = {}
    self.MinionsAttacks = {}

    if not _G.VPredictionMenu then
        _G.VPredictionMenu = scriptConfig("VPrediction", "VPrediction")

        _G.VPredictionMenu:addParam("Mode", "Cast Mode", SCRIPT_PARAM_LIST, 1, {"Fast", "Medium", "Slow" })

        --[[Collision]]
        _G.VPredictionMenu:addSubMenu("Collision", "Collision")
            _G.VPredictionMenu.Collision:addParam("Buffer", "Collision buffer", SCRIPT_PARAM_SLICE, 20, 0, 100)
            _G.VPredictionMenu.Collision:addParam("Minions", "Normal minions", SCRIPT_PARAM_ONOFF, true)
            _G.VPredictionMenu.Collision:addParam("Mobs", "Jungle minions", SCRIPT_PARAM_ONOFF, true)
            _G.VPredictionMenu.Collision:addParam("Others", "Others", SCRIPT_PARAM_ONOFF, true)
            _G.VPredictionMenu.Collision:addParam("CHealth", "Check if minions are about to die", SCRIPT_PARAM_ONOFF, true)
            _G.VPredictionMenu.Collision:addParam("info", "-", SCRIPT_PARAM_INFO, "^ Can cause fps drops")

            _G.VPredictionMenu.Collision:addParam("UnitPos", "Check collision at the unit pos", SCRIPT_PARAM_ONOFF, true)
            _G.VPredictionMenu.Collision:addParam("CastPos", "Check collision at the cast pos", SCRIPT_PARAM_ONOFF, true)
            _G.VPredictionMenu.Collision:addParam("PredictPos", "Check collision at the predicted pos", SCRIPT_PARAM_ONOFF, false)


        _G.VPredictionMenu:addSubMenu("Developers", "Developers")
                _G.VPredictionMenu.Developers:addParam("Debug", "Enable debug", SCRIPT_PARAM_ONOFF, false)
                _G.VPredictionMenu.Developers:addParam("SC", "Show collision", SCRIPT_PARAM_ONOFF, false)

        _G.VPredictionMenu:addParam("Version", "Version", SCRIPT_PARAM_INFO, tostring(self.version))
    end

    --[[Use waypoints from the last 10 seconds]]
    self.WaypointsTime = 10

    self.EnemyMinions = minionManager(MINION_ENEMY, 2000, myHero, MINION_SORT_HEALTH_ASC)
    self.JungleMinions = minionManager(MINION_JUNGLE, 2000, myHero, MINION_SORT_HEALTH_ASC)
    self.OtherMinions = minionManager(MINION_OTHER, 2000, myHero, MINION_SORT_HEALTH_ASC)

    self.TargetsVisible = {}
    self.TargetsWaypoints = {}
    self.TargetsImmobile = {}
    self.TargetsDashing = {}
    self.TargetsSlowed = {}
    self.DontShoot = {}
    self.DontShoot2 = {}
    self.DontShootUntilNewWaypoints = {}

    AddNewPathCallback(function(unit, startPos, endPos, isDash ,dashSpeed,dashGravity, dashDistance) self:OnNewPath(unit, startPos, endPos, isDash, dashSpeed, dashGravity, dashDistance) end)

    AddTickCallback(function() self:OnTick() end)
    AddDrawCallback(function() self:OnDraw() end)
    AddAnimationCallback(function(unit, action) self:Animation(unit, action) end)
    AddProcessSpellCallback(function(unit, spell) self:OnProcessSpell(unit, spell) end)
    --AddProcessSpellCallback(function(unit, spell) self:CollisionProcessSpell(unit, spell) end)

    if AddProcessAttackCallback then
        --AddProcessAttackCallback(function(unit, spell) self:OnProcessSpell(unit, spell) end)
        AddProcessAttackCallback(function(unit, spell) self:CollisionProcessSpell(unit, spell) end)
    end
    self.BlackList =
    {
            {name = "aatroxq", duration = 0.75}, --[[4 Dashes, OnDash fails]]
    }

    --[[Spells that will cause OnDash to fire, dont shoot and wait to OnDash]]
    self.dashAboutToHappend =
    {
            {name = "ahritumble", duration = 0.25},--ahri's r
            {name = "akalishadowdance", duration = 0.25},--akali r
            {name = "headbutt", duration = 0.25},--alistar w
            {name = "caitlynentrapment", duration = 0.25},--caitlyn e
            {name = "carpetbomb", duration = 0.25},--corki w
            {name = "dianateleport", duration = 0.25},--diana r
            {name = "fizzpiercingstrike", duration = 0.25},--fizz q
            {name = "fizzjump", duration = 0.25},--fizz e
            {name = "gragasbodyslam", duration = 0.25},--gragas e
            {name = "gravesmove", duration = 0.25},--graves e
            {name = "ireliagatotsu", duration = 0.25},--irelia q
            {name = "jarvanivdragonstrike", duration = 0.25},--jarvan q
            {name = "jaxleapstrike", duration = 0.25},--jax q
            {name = "khazixe", duration = 0.25},--khazix e and e evolved
            {name = "leblancslide", duration = 0.25},--leblanc w
            {name = "leblancslidem", duration = 0.25},--leblanc w (r)
            {name = "blindmonkqtwo", duration = 0.25},--lee sin q
            {name = "blindmonkwone", duration = 0.25},--lee sin w
            {name = "luciane", duration = 0.25},--lucian e
            {name = "maokaiunstablegrowth", duration = 0.25},--maokai w
            {name = "nocturneparanoia2", duration = 0.25},--nocturne r
            {name = "pantheon_leapbash", duration = 0.25},--pantheon e?
            {name = "renektonsliceanddice", duration = 0.25},--renekton e
            {name = "riventricleave", duration = 0.25},--riven q
            {name = "rivenfeint", duration = 0.25},--riven e
            {name = "sejuaniarcticassault", duration = 0.25},--sejuani q
            {name = "shenshadowdash", duration = 0.25},--shen e
            {name = "shyvanatransformcast", duration = 0.25},--shyvana r
            {name = "rocketjump", duration = 0.25},--tristana w
            {name = "slashcast", duration = 0.25},--tryndamere e
            {name = "vaynetumble", duration = 0.25},--vayne q
            {name = "viq", duration = 0.25},--vi q
            {name = "monkeykingnimbus", duration = 0.25},--wukong q
            {name = "xenzhaosweep", duration = 0.25},--xin xhao q
            {name = "yasuodashwrapper", duration = 0.25},--yasuo e

    }
    --[[Spells that don't allow movement (durations approx)]]
    self.spells = {
            {name = "katarinar", duration = 1}, --Katarinas R
            {name = "drain", duration = 1}, --Fiddle W
            {name = "crowstorm", duration = 1}, --Fiddle R
            {name = "consume", duration = 0.5}, --Nunu Q
            {name = "absolutezero", duration = 1}, --Nunu R
            {name = "rocketgrab", duration = 0.5}, --Blitzcrank Q
            {name = "staticfield", duration = 0.5}, --Blitzcrank R
            {name = "cassiopeiapetrifyinggaze", duration = 0.5}, --Cassio's R
            {name = "ezrealtrueshotbarrage", duration = 1}, --Ezreal's R
            {name = "galioidolofdurand", duration = 1}, --Ezreal's R
            --{name = "gragasdrunkenrage", duration = 1}, --Gragas W, Rito changed it so that it allows full movement while casting
            {name = "luxmalicecannon", duration = 1}, --Lux R
            {name = "reapthewhirlwind", duration = 1}, --Jannas R
            {name = "jinxw", duration = 0.6}, --jinxW
            {name = "jinxr", duration = 0.6}, --jinxR
            {name = "missfortunebullettime", duration = 1}, --MissFortuneR
            {name = "shenstandunited", duration = 1}, --ShenR
            {name = "threshe", duration = 0.4}, --ThreshE
            {name = "threshrpenta", duration = 0.75}, --ThreshR
            {name = "infiniteduress", duration = 1}, --Warwick R
            {name = "meditate", duration = 1} --yi W
    }

    self.blinks = {
            {name = "ezrealarcaneshift", range = 475, delay = 0.25, delay2=0.8},--Ezreals E
            {name = "deceive", range = 400, delay = 0.25, delay2=0.8}, --Shacos Q
            {name = "riftwalk", range = 700, delay = 0.25, delay2=0.8},--KassadinR
            {name = "gate", range = 5500, delay = 1.5, delay2=1.5},--Twisted fate R
            {name = "katarinae", range = math.huge, delay = 0.25, delay2=0.8},--Katarinas E
            {name = "elisespideredescent", range = math.huge, delay = 0.25, delay2=0.8},--Elise E
            {name = "elisespidere", range = math.huge, delay = 0.25, delay2=0.8},--Elise insta E
    }

    return self
end

function VPrediction:GetTime()
        return os.clock()
end
function VPrediction:GetVersion()
    return self.version
end

function VPrediction:OnProcessSpell(unit, spell)
    if unit and unit.type == myHero.type then
        for i, s in ipairs(self.spells) do
            if spell.name:lower() == s.name then
                self.TargetsImmobile[unit.networkID] = self:GetTime() + s.duration
                return
            end
        end

        for i, s in ipairs(self.blinks) do
            local LandingPos = GetDistance(unit, Vector(spell.endPos)) < s.range and Vector(spell.endPos) or Vector(unit) + s.range * (Vector(spell.endPos) - Vector(unit)):normalized()
            if spell.name:lower() == s.name and not IsWall(D3DXVECTOR3(spell.endPos.x, spell.endPos.y, spell.endPos.z)) then
                self.TargetsDashing[unit.networkID] = {isblink = true, duration = s.delay, endT = self:GetTime() + s.delay, endT2 = self:GetTime() + s.delay2, startPos = Vector(unit), endPos = LandingPos}
                return
            end
        end

        for i, s in ipairs(self.BlackList) do
            if spell.name:lower() == s.name then
                self.DontShoot[unit.networkID] = self:GetTime() + s.duration
                return
            end
        end

        for i, s in ipairs(self.dashAboutToHappend) do
            if spell.name:lower() == s.name then
                self.DontShoot2[unit.networkID] = self:GetTime() + s.duration
                return
            end
        end
    end
end

--[[function OnNewWP(unit)
    if not lWP then
        lWP = Vector(unit.endPath)
        lastWP = os.clock()
    end
    if Vector(unit.endPath) ~= lWP then
        lWP = Vector(unit.endPath)
        lastWP = os.clock()
    end
    if lastWP < os.clock() - 1 then
        return false
    else
        return true
    end
end]]

function VPrediction:OnNewPath(unit, startPos, endPos, isDash, dashSpeed ,dashGravity, dashDistance)
    if unit.type == myHero.type and unit.team ~= myHero.team or unit == myHero then
        if PA[unit.networkID][#PA[unit.networkID] -1] then
            local p1 = PA[unit.networkID][#PA[unit.networkID] -1].p
            local p2 = PA[unit.networkID][#PA[unit.networkID]].p
            local angle = Vector(unit.x, unit.y, unit.z):angleBetween(Vector(p2.x, p2.y, p2.z), Vector(p1.x, p1.y, p1.z))
            if angle > 20 then
                local submit = {t = os.clock(), p = endPos}
                table.insert(PA[unit.networkID], submit)
            end
        else
            local submit = {t = os.clock(), p = endPos}
            table.insert(PA[unit.networkID], submit)
        end
    end
    local object = unit
    local NetworkID = unit.networkID
    if object and object.valid and object.networkID and object.type == myHero.type then
        self.DontShootUntilNewWaypoints[NetworkID] = false
        if self.TargetsWaypoints[NetworkID] == nil then
                self.TargetsWaypoints[NetworkID] = {}
        end
        local WaypointsToAdd = self:GetCurrentWayPoints(unit)
        if WaypointsToAdd and #WaypointsToAdd >= 1 then
                --[[Save only the last waypoint (where the player clicked)]]
                table.insert(self.TargetsWaypoints[NetworkID], {unitpos = Vector(object) , waypoint = WaypointsToAdd[#WaypointsToAdd], time = self:GetTime(), n = #WaypointsToAdd})
        end
    elseif object and object.valid and object.type ~= myHero.type then
        local i = 1
        while i <= #self.ActiveAttacks do
            if (self.ActiveAttacks[i].Attacker and self.ActiveAttacks[i].Attacker.valid and self.ActiveAttacks[i].Attacker.networkID == NetworkID and (self.ActiveAttacks[i].starttime + self.ActiveAttacks[i].windUpTime - GetLatency()/2000) > self:GetTime()) then
                local wpts = self:GetWaypoints(unit.networkID)
                if #wpts > 1 then
                    table.remove(self.ActiveAttacks, i)
                else
                    i = i + 1
                end
            else
                i = i + 1
            end
        end
    end
    --[[OnDash Alternative]]
    if isDash then
        local dash = {}
        if unit.type == myHero.type then
            dash.startPos = startPos
            dash.endPos = endPos
            dash.speed = dashSpeed
            dash.startT = self:GetTime() - GetLatency()/2000
            local dis = GetDistance(startPos, endPos)
            dash.endT = dash.startT + (dis/dashSpeed)
            self.TargetsDashing[unit.networkID] = dash
            self.DontShootUntilNewWaypoints[unit.networkID] = true
        end
    end
end


function VPrediction:IsImmobile(unit, delay, radius, speed, from, spelltype)
    if self.TargetsImmobile[unit.networkID] then
        local ExtraDelay = speed == math.huge and  0 or (GetDistance(from, unit) / speed)
        if (self.TargetsImmobile[unit.networkID] > (self:GetTime() + delay + ExtraDelay) and spelltype == "circular") then
            return true, Vector(unit), Vector(unit) + (radius/3) * (Vector(from) - Vector(unit)):normalized()
        elseif (self.TargetsImmobile[unit.networkID] + (radius / unit.ms)) > (self:GetTime() + delay + ExtraDelay) then
            return true, Vector(unit), Vector(unit)
        end
    end
    return false, Vector(unit), Vector(unit)
end

function VPrediction:isSlowed(unit, delay, speed, from)
    if self.TargetsSlowed[unit.networkID] then
        if self.TargetsSlowed[unit.networkID] > (self:GetTime() + delay + GetDistance(unit, from) / speed) then
            return true
        end
    end
    return false
end

function VPrediction:IsDashing(unit, delay, radius, speed, from)
    local TargetDashing = false
    local CanHit = false
    local Position

    if self.TargetsDashing[unit.networkID] then
        local dash = self.TargetsDashing[unit.networkID]
        if dash.endT >= self:GetTime() then
            TargetDashing = true
            if dash.isblink then
                if (dash.endT - self:GetTime()) <= (delay + GetDistance(from, dash.endPos)/speed) then
                    Position = Vector(dash.endPos.x, 0, dash.endPos.z)
                    CanHit = (unit.ms * (delay + GetDistance(from, dash.endPos)/speed - (dash.endT2 - self:GetTime()))) < radius
                end

                if ((dash.endT - self:GetTime()) >= (delay + GetDistance(from, dash.startPos)/speed)) and not CanHit then
                    Position = Vector(dash.startPos.x, 0, dash.startPos.z)
                    CanHit = true
                end
            else
                local t1, p1, t2, p2, dist = VectorMovementCollision(dash.startPos, dash.endPos, dash.speed, from, speed, (self:GetTime() - dash.startT) + delay)
                t1, t2 = (t1 and 0 <= t1 and t1 <= (dash.endT - self:GetTime() - delay)) and t1 or nil, (t2 and 0 <= t2 and t2 <=  (dash.endT - self:GetTime() - delay)) and t2 or nil
                local t = t1 and t2 and math.min(t1,t2) or t1 or t2
                if t then
                    Position = t==t1 and Vector(p1.x, 0, p1.y) or Vector(p2.x, 0, p2.y)
                    CanHit = true
                else
                    Position = Vector(dash.endPos.x, 0, dash.endPos.z)
                    CanHit = (unit.ms * (delay + GetDistance(from, Position)/speed - (dash.endT - self:GetTime()))) < radius
                end
            end
        end
    end
    return TargetDashing, CanHit, Position
end

function VPrediction:GetWaypoints(NetworkID, from, to)
    local Result = {}
    to = to and to or self:GetTime()
    if self.TargetsWaypoints[NetworkID] then
        for i, waypoint in ipairs(self.TargetsWaypoints[NetworkID]) do
            if from <= waypoint.time  and to >= waypoint.time then
                table.insert(Result, waypoint)
            end
        end
    end
    return Result, #Result
end

function VPrediction:CountWaypoints(NetworkID, from, to)
    local R, N = self:GetWaypoints(NetworkID, from, to)
    return N
end

function VPrediction:GetWaypointsLength(Waypoints)
    local result = 0
    for i = 1, #Waypoints -1 do
        result = result + GetDistance(Waypoints[i], Waypoints[i + 1])
    end
    return result
end

function VPrediction:CutWaypoints(Waypoints, distance)
    local result = {}
    local remaining = distance
    if distance > 0 then
        for i = 1, #Waypoints -1 do
            local A, B = Waypoints[i], Waypoints[i + 1]
            local dist = GetDistance(A, B)
            if dist >= remaining then
                result[1] = Vector(A) + remaining * (Vector(B) - Vector(A)):normalized()

                for j = i + 1, #Waypoints do
                    result[j - i + 1] = Waypoints[j]
                end
                remaining = 0
                break
            else
                remaining = remaining - dist
            end
        end
    else
        local A, B = Waypoints[1], Waypoints[2]
        result = Waypoints
        result[1] = Vector(A) - distance * (Vector(B) - Vector(A)):normalized()
    end

    return result
end

function VPrediction:GetCurrentWayPoints(object)
    local result = {}

    if object.hasMovePath then
        table.insert(result, Vector(object))
        for i = object.pathIndex, object.pathCount do

            path = object:GetPath(i)
            table.insert(result, Vector(path))
        end
    else
        table.insert(result, Vector(object))
    end
    return result
end

--[[Calculate the hero position based on the last waypoints]]
function VPrediction:CalculateTargetPosition(unit, delay, radius, speed, from, spelltype, second)
    if unit.type == myHero.type and unit.team ~= myHero.team or unit == myHero then
        --print(unit.charName.." "..#PA[unit.networkID])
        if #PA[unit.networkID] > 4 then
            return Vector(unit), Vector(unit)
        elseif #PA[unit.networkID] > 3 then
            delay = delay*.8
            speed = speed*1.20
        end

    end
    local spot
    if ValidTarget(unit) and unit.endPath or unit == myHero then    ---- FIX
        local p90x = second and second or unit.pos
        local pathPot = (unit.ms*((GetDistance(myHero.pos, p90x)/speed)+delay))

        if unit.pathCount < 3 then
            local v = Vector(unit) + (Vector(unit.endPath)-Vector(unit)):normalized()*(pathPot - unit.boundingRadius+10)
            if GetDistance(unit, v) > 1 then
                if GetDistance(unit.endPath, unit) >= GetDistance(unit, v) then
                    spot = v
                else
                    spot = Vector(unit.endPath)
                end
            else
                spot = Vector(unit.endPath)
            end
        else
            for i = unit.pathIndex, unit.pathCount do
                if unit:GetPath(i) and unit:GetPath(i-1) then
                    local pStart = i == unit.pathIndex and unit.pos or unit:GetPath(i-1)
                    local pEnd = unit:GetPath(i)
                    local iPathDist = GetDistance(pStart, pEnd)
                    if unit:GetPath(unit.pathIndex  - 1) then
                        if pathPot > iPathDist then
                            pathPot = pathPot-iPathDist
                        else
                            local v = Vector(pStart) + (Vector(pEnd)-Vector(pStart)):normalized()*(pathPot- unit.boundingRadius+10)
                            spot = v
                            if second then
                                return spot, spot
                            else
                                return self:CalculateTargetPosition(unit, delay, radius, speed, from, spelltype, spot)
                            end
                        end
                    end
                end
            end
            if GetDistance(unit, unit.endPath) > unit.boundingRadius then
                spot = Vector(unit.endPath)
            else
                spot = Vector(unit)
            end
        end
    end
    spot = spot and spot or Vector(unit)
    if second then
        return spot, spot
    else
        return self:CalculateTargetPosition(unit, delay, radius, speed, from, spelltype, spot)
    end
end

function VPrediction:MaxAngle(unit, currentwaypoint, from)
    local WPtable, n = self:GetWaypoints(unit.networkID, from)
    local Max = 0
    local CV = (Vector(currentwaypoint.x, 0, currentwaypoint.y) - Vector(unit))
        for i, waypoint in ipairs(WPtable) do
            local angle = Vector(0, 0, 0):angleBetween(CV, Vector(waypoint.waypoint.x, 0, waypoint.waypoint.y) - Vector(waypoint.unitpos.x, 0, waypoint.unitpos.y))
            if angle > Max then
                Max = angle
            end
        end
    return Max
end

function VPrediction:WayPointAnalysis(unit, delay, radius, range, speed, from, spelltype)
    local Position, CastPosition, HitChance
    local SavedWayPoints = self.TargetsWaypoints[unit.networkID] and self.TargetsWaypoints[unit.networkID] or {}
    local CurrentWayPoints = self:GetCurrentWayPoints(unit)
    local VisibleSince = self.TargetsVisible[unit.networkID] and self.TargetsVisible[unit.networkID] or self:GetTime()

    if delay < 0.25 then
        HitChance = 2
    else
        HitChance = 1
    end

    Position, CastPosition = self:CalculateTargetPosition(unit, delay, radius, speed, from, spelltype)

    if self:CountWaypoints(unit.networkID, self:GetTime() - 0.1) >= 1 or self:CountWaypoints(unit.networkID, self:GetTime() - 1) == 1 then
        HitChance = 2
    end

    local N = (_G.VPredictionMenu.Mode == _SLOW) and 3 or 2
    local t1 = (_G.VPredictionMenu.Mode == _SLOW) and 1 or 0.5
    if self:CountWaypoints(unit.networkID, self:GetTime() - 0.75) >= N then
        local angle = self:MaxAngle(unit, CurrentWayPoints[#CurrentWayPoints], self:GetTime() - t1)
        if angle > 90 then
            HitChance = 1
        elseif angle < 30 and self:CountWaypoints(unit.networkID, self:GetTime() - 0.1) >= 1 then
            HitChance = 2
        end
    end

    N = (_G.VPredictionMenu.Mode == _SLOW) and 2 or 1
    if self:CountWaypoints(unit.networkID, self:GetTime() - N) == 0 then
        HitChance = 2
    end

    if _G.VPredictionMenu.Mode == _FAST then
        HitChance = 2
    end

    if #CurrentWayPoints <= 1 and self:GetTime() - VisibleSince > 1 then
        HitChance = 2
    end

    if self:isSlowed(unit, delay, speed, from) then
        HitChance = 2
    end

    if Position and CastPosition and ((radius / unit.ms >= delay + GetDistance(from, CastPosition)/speed) or (radius / unit.ms >= delay + GetDistance(from, Position)/speed)) then
        HitChance = 3
    end
            --[[Angle too wide]]
    if Vector(from):angleBetween(Vector(unit), Vector(CastPosition)) > 60 then
        HitChance = 1
    end

    if not Position or not CastPosition then
        HitChance = 0
        CastPosition = Vector(unit)
        Position = CastPosition
    end

    if GetDistance(myHero, unit) < 250 and unit ~= myHero then
        HitChance = 2
        Position, CastPosition = self:CalculateTargetPosition(unit, delay*0.5, radius, speed*2, from, spelltype)
        Position = CastPosition
    end

    if #SavedWayPoints == 0 and (self:GetTime() - VisibleSince) > 3 then
        HitChance = 2
    end

    if self.DontShootUntilNewWaypoints[unit.networkID] then
        HitChance = 0
        CastPosition = Vector(unit)
        Position = CastPosition
    end

    return CastPosition, HitChance, Position
end

function VPrediction:GetBestCastPosition(unit, delay, radius, range, speed, from, collision, spelltype)
    assert(unit, "VPrediction: Target can't be nil")

    range = range and range - 15 or math.huge
    radius = radius == 0 and 1 or (radius + self:GetHitBox(unit)) - 4
    speed = speed and speed or math.huge
    from = from and from or Vector(myHero)
    if from.networkID and from.networkID == myHero.networkID then
        from = Vector(myHero)
    end
    local IsFromMyHero = GetDistanceSqr(from, myHero) < 50*50 and true or false

    delay = delay + (0.07 + GetLatency() / 2000)

    local Position, CastPosition, HitChance = Vector(unit), Vector(unit), 0
    local TargetDashing, CanHitDashing, DashPosition = self:IsDashing(unit, delay, radius, speed, from)
    local TargetImmobile, ImmobilePos, ImmobileCastPosition = self:IsImmobile(unit, delay, radius, speed, from, spelltype)
    local VisibleSince = self.TargetsVisible[unit.networkID] and self.TargetsVisible[unit.networkID] or self:GetTime()

    if unit.type ~= myHero.type then
        Position, CastPosition = self:CalculateTargetPosition(unit, delay, radius, speed, from, spelltype)
        HitChance = 2
    else
        if self.DontShoot[unit.networkID] and self.DontShoot[unit.networkID] > self:GetTime() then
            Position, CastPosition = Vector(unit),  Vector(unit)
            HitChance = 0
        elseif TargetDashing then
            if CanHitDashing then
                    HitChance = 5
            else
                    HitChance = 0
            end
            Position, CastPosition = DashPosition, DashPosition
        elseif self.DontShoot2[unit.networkID] and self.DontShoot2[unit.networkID] > self:GetTime() then
            Position, CastPosition = Vector(unit.x, unit.y, unit.z),  Vector(unit.x, unit.y, unit.z)
            HitChance = 7
        elseif TargetImmobile then
            Position, CastPosition = ImmobilePos, ImmobileCastPosition
            HitChance = 4
        elseif not self.DontUseWayPoints then
            CastPosition, HitChance, Position = self:WayPointAnalysis(unit, delay, radius, range, speed, from, spelltype)
        end
    end

    --[[Out of range]]
    if IsFromMyHero then
        if (spelltype == "line" and GetDistanceSqr(from, Position) >= range * range) then
            HitChance = 0
        end
        if (spelltype == "circular" and (GetDistanceSqr(from, Position) >= (range + radius)^2)) then
            HitChance = 0
        end

        if self.ShotAtMaxRange and HitChance ~= 0 and spelltype == "circular" and (GetDistanceSqr(from, CastPosition) > range ^ 2) then
            if GetDistanceSqr(from, Position) <= (range + radius / 1.4) ^ 2 then
                if GetDistanceSqr(from, Position) <= range * range then
                    CastPosition = Position
                else
                    CastPosition = Vector(from) + range * (Vector(Position) - Vector(from)):normalized()
                end
            end
        elseif (GetDistanceSqr(from, CastPosition) > range ^ 2) then
            HitChance = 0
        end
    end

    radius = radius - self:GetHitBox(unit) + 4

    if collision and HitChance > 0 then
        self.EnemyMinions.range = range + 500 * (delay + range/speed)
        self.JungleMinions.range = self.EnemyMinions.range
        self.OtherMinions.range = self.EnemyMinions.range
        self.EnemyMinions:update()
        self.JungleMinions:update()
        self.OtherMinions:update()

        if _G.VPredictionMenu.Collision.CastPos and self:CheckMinionCollision(unit, CastPosition, delay, radius, range, speed, from, false, false) then
            HitChance = -1
        elseif _G.VPredictionMenu.Collision.PredictPos and self:CheckMinionCollision(unit, Position, delay, radius, range, speed, from, false, false) then
            HitChance = -1
        end
        if _G.VPredictionMenu.Collision.UnitPos and self:CheckMinionCollision(unit, unit, delay, radius, range, speed, from, false, false) then
            HitChance = -1
        end
    end
    return CastPosition, HitChance, Position
end

--------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------
--Collision
--------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------

function VPrediction:GetPredictedHealth(unit, time, delay)
    local IncDamage = 0
    local i = 1
    local MaxDamage = 0
    local count = 0

    delay = delay and delay or 0.07
    while i <= #self.ActiveAttacks do
        if self.ActiveAttacks[i].Attacker and not self.ActiveAttacks[i].Attacker.dead and self.ActiveAttacks[i].Target and self.ActiveAttacks[i].Target.networkID == unit.networkID then
            local hittime = self.ActiveAttacks[i].starttime + self.ActiveAttacks[i].windUpTime + (GetDistance(self.ActiveAttacks[i].pos, unit)) / self.ActiveAttacks[i].projectilespeed + delay
            if self:GetTime() < hittime - delay and hittime < self:GetTime() + time  then
                IncDamage = IncDamage + self.ActiveAttacks[i].damage
                count = count + 1
                if self.ActiveAttacks[i].damage > MaxDamage then
                    MaxDamage = self.ActiveAttacks[i].damage
                end
            end
        end
        i = i + 1
    end

    return unit.health - IncDamage, MaxDamage, count
end
function VPrediction:GetClosestUnit(obj)
    local closest = nil

    for i = 1, objManager.maxObjects do
        local object = objManager:GetObject(i)

        if object and object.valid and obj ~= object and (object.type == myHero.type or object.type == "obj_AI_Minion") and object.team ~= myHero.team and  GetDistanceSqr(object.pos, myHero.pos) < 2000*2000  then
            if GetDistanceSqr(obj.pos, object.pos) < 250*250 then
                if object.charName and object.charName ~= "SRU_BaronSpawn" then
                    if closest == nil then
                        closest = object
                    elseif GetDistanceSqr(object.pos, obj) < GetDistanceSqr(closest.pos, obj) then
                        closest = object
                    end
                end
            end
        end
    end
    return closest
end
function VPrediction:GetPredictedHealth2(unit, t)
    local damage = 0
    local i = 1

    while i <= #self.ActiveAttacks do
        local n = 0
        if (self:GetTime() - 0.1) <= self.ActiveAttacks[i].starttime + self.ActiveAttacks[i].animationTime and self.ActiveAttacks[i].Target and self.ActiveAttacks[i].Target.valid and self.ActiveAttacks[i].Target.networkID == unit.networkID and self.ActiveAttacks[i].Attacker and self.ActiveAttacks[i].Attacker.valid and not self.ActiveAttacks[i].Attacker.dead then
            local FromT = self.ActiveAttacks[i].starttime
            local ToT = t + self:GetTime()

            while FromT < ToT do
                if FromT >= self:GetTime() and (FromT + (self.ActiveAttacks[i].windUpTime + GetDistance(unit, self.ActiveAttacks[i].pos) / self.ActiveAttacks[i].projectilespeed)) < ToT then
                    n = n + 1
                end
                FromT = FromT + self.ActiveAttacks[i].animationTime
            end
        end
        damage = damage + n * self.ActiveAttacks[i].damage
        i = i + 1
    end

    return unit.health - damage
end
function VPrediction:Animation(unit, action)
    if unit and unit.valid and unit.type ~= myHero.type and unit.team == myHero.team and action:lower():find("atta") and not self.projectilespeeds[unit.charName] then

        local time = self:GetTime() + 0.393 - GetLatency()/2000
        local tar = GetAggro(unit)
        if tar then
            table.insert(self.ActiveAttacks, {Attacker = unit, pos = Vector(unit), Target = tar, animationTime = math.huge, damage = unit.totalDamage, hittime=time, starttime = self:GetTime() - GetLatency()/2000, windUpTime = 0.393, projectilespeed = math.huge})
        end
    end
end
function VPrediction:CollisionProcessSpell(unit, spell)
    if unit and unit.valid and spell.target and unit.type ~= myHero.type and spell.target.type == 'obj_AI_Minion' and unit.team == myHero.team and spell and spell.name and (spell.name:lower():find("attack") or (spell.name == "frostarrow")) and spell.windUpTime and spell.target then
        if GetDistanceSqr(unit) < 4000000 then
            if self.projectilespeeds[unit.charName] then
                local time = self:GetTime() + GetDistance(spell.target, unit) / self:GetProjectileSpeed(unit) - GetLatency()/2000
                local i = 1
                while i <= #self.ActiveAttacks do
                    if (self.ActiveAttacks[i].Attacker and self.ActiveAttacks[i].Attacker.valid and self.ActiveAttacks[i].Attacker.networkID == unit.networkID) or ((self.ActiveAttacks[i].hittime + 3) < self:GetTime()) then
                        table.remove(self.ActiveAttacks, i)
                    else
                        i = i + 1
                    end
                end

                table.insert(self.ActiveAttacks, {Attacker = unit, pos = Vector(unit), Target = spell.target, animationTime = spell.animationTime, damage = self:CalcDamageOfAttack(unit, spell.target, spell, 0), hittime=time, starttime = self:GetTime() - GetLatency()/2000, windUpTime = 0, projectilespeed = self:GetProjectileSpeed(unit)})
            else
                minionTar[unit.networkID] = spell.target
            end
        end
    end
end

function VPrediction:CheckCol(unit, minion, Position, delay, radius, range, speed, from, draw)
    if unit.networkID == minion.networkID then
        return false
    end

    --[[Check first if the minion is going to be dead when skillshots reaches his position]]
    if minion.type ~= myHero.type and self:GetPredictedHealth(minion,  delay + GetDistance(from, minion) / speed) < 0 then
        return false
    end

    local waypoints = self:GetCurrentWayPoints(minion)
    local MPos, CastPosition = minion.pathCount == 1 and Vector(minion) or self:CalculateTargetPosition(minion, delay, radius, speed, from, "line")
    if GetDistanceSqr(from, MPos) <= (range)^2 and GetDistanceSqr(from, minion) <= (range + 100)^2 then
        local buffer = (minion.pathCount > 1) and _G.VPredictionMenu.Collision.Buffer or 8

        if minion.type == myHero.type then
            buffer = buffer + self:GetHitBox(minion)
        end

        if draw then
            DrawCircle3D(minion.x, myHero.y, minion.z, self:GetHitBox(minion) + buffer, 1, ARGB(255, 255, 255, 255))
            DrawCircle3D(MPos.x, myHero.y, MPos.z, self:GetHitBox(minion) + buffer, 1, ARGB(255, 255, 255, 255))
            self:DLine(MPos, minion, Color)
        end

        if minion.pathCount > 1 then
            local proj1, pointLine, isOnSegment = VectorPointProjectionOnLineSegment(from, Position, Vector(MPos))
            if isOnSegment and (GetDistanceSqr(MPos, proj1) <= (self:GetHitBox(minion) + radius + buffer) ^ 2) then
                return true
            end
        end

        local proj2, pointLine, isOnSegment = VectorPointProjectionOnLineSegment(from, Position, Vector(minion))
        if isOnSegment and (GetDistanceSqr(minion, proj2) <= (self:GetHitBox(minion) + radius + buffer) ^ 2) then
            return true
        end
    end
    return false
end

function VPrediction:CheckMinionCollision(unit, Position, delay, radius, range, speed, from, draw, updatemanagers)
    Position = Vector(Position)
    from = from and Vector(from) or myHero
    --local draw = true
    if updatemanagers then
        self.EnemyMinions.range = range + 500 * (delay + range / speed)
        self.JungleMinions.range = self.EnemyMinions.range
        self.OtherMinions.range = self.EnemyMinions.range
        self.EnemyMinions:update()
        self.JungleMinions:update()
        self.OtherMinions:update()
    end

    local result = false
    if _G.VPredictionMenu.Collision.Minions then
        for i, minion in ipairs(self.EnemyMinions.objects) do
            if self:CheckCol(unit, minion, Position, delay, radius, range, speed, from, draw) then
                if not draw then
                    return true
                else
                    result = true
                end
            end
        end
    end

    if _G.VPredictionMenu.Collision.Mobs then
        for i, minion in ipairs(self.JungleMinions.objects) do
            if self:CheckCol(unit, minion, Position, delay, radius, range, speed, from, draw) then
                if not draw then
                    return true
                else
                    result = true
                end
            end
        end
    end

    if _G.VPredictionMenu.Collision.Others then
        for i, minion in ipairs(self.OtherMinions.objects) do
            if minion.team ~= myHero.team and self:CheckCol(unit, minion, Position, delay, radius, range, speed, from, draw) then
                if not draw then
                    return true
                else
                    result = true
                end
            end
        end
    end

    if self.ChampionCollision then
        for i, enemy in ipairs(GetEnemyHeroes()) do
            if self:CheckCol(unit, enemy, Position, delay, radius, range, speed, from, draw) then
                if not draw then
                    return true
                else
                    result = true
                end
            end
        end
    end

    if draw then
        local Direction = Vector(Position - from):perpendicular():normalized()
        local Color = result and ARGB(255, 255, 0, 0) or ARGB(255, 0, 255, 0)
        local P1r = Vector(from) + radius * Vector(Direction)
        local P1l = Vector(from) - radius * Vector(Direction)
        local P2r = Vector(from) + radius * Direction - Vector(Direction):perpendicular() * GetDistance(from, Position)
        local P2l = Vector(from) - radius * Direction - Vector(Direction):perpendicular() * GetDistance(from, Position)

        self:DLine(P1r, P1l, Color)
        self:DLine(P1r, P2r, Color)
        self:DLine(P1l, P2l, Color)
        self:DLine(P2r, P2l, Color)
        if not result and IsKeyDown(string.byte("T")) then
            CastSpell(_Q, Position.x, Position.z)
        end
    end

    return result
end

function VPrediction:GetCircularCastPosition(unit, delay, radius, range, speed, from, collision)
    return self:GetBestCastPosition(unit, delay, radius, range, speed, from, collision, "circular")
end

                            --Added dmg param to increase minimum health predicted on collision if desired for champs such as Kalista Q; Or to increase buffer on predicted health by doing negative
function VPrediction:GetLineCastPosition(unit, delay, radius, range, speed, from, collision)
    return self:GetBestCastPosition(unit, delay, radius, range, speed, from, collision, "line")
end

function VPrediction:GetPredictedPos(unit, delay, speed, from, collision)
    return self:GetBestCastPosition(unit, delay, 1, math.huge, speed, from, collision, "circular")
end

--TODO: Recode this stuff and make it more readable :D
function VPrediction:GetCircularAOECastPosition(unit, delay, radius, range, speed, from, collision)
    local CastPosition, HitChance, Position = self:GetBestCastPosition(unit, delay, radius, range, speed, from, collision, "circular")
    local points = {}
    local mainCastPosition, mainHitChance, mainPosition = CastPosition, HitChance, Position

    table.insert(points, Position)

    for i, target in ipairs(GetEnemyHeroes()) do
        if target.networkID ~= unit.networkID and ValidTarget(target, range * 1.5) then
            CastPosition, HitChance, Position = self:GetBestCastPosition(target, delay, radius, range, speed, from, collision, "circular")
            if GetDistance(from, Position) < (range + radius) and (Hitchance ~= -1 or not collision) then
                table.insert(points, Position)
            end
        end
    end

    while #points > 1 do
        local Mec = MEC(points)
        local Circle = Mec:Compute()

        if Circle.radius <= radius + self:GetHitBox(unit) - 8 then
            return Circle.center, mainHitChance, #points
        end

        local maxdist = -1
        local maxdistindex = 0

        for i=2, #points do
            local d = GetDistanceSqr(points[i], points[1])
            if d > maxdist or maxdist == -1 then
                maxdistindex = i
                maxdist = d
            end
        end

        table.remove(points, maxdistindex)
    end

    return mainCastPosition, mainHitChance, #points, mainPosition
end

function VPrediction:GetLineAOECastPosition(unit, delay, radius, range, speed, from)
    local CastPosition, HitChance, Position = self:GetBestCastPosition(unit, delay, radius, range, speed, from, false, "line")
    local points = {}
    local Positions = {}
    local mainCastPosition, mainHitChance = CastPosition, HitChance

    table.insert(Positions, {unit = unit, HitChance = HitChance, Position = Position, CastPosition = CastPosition})
    table.insert(points, Position)

    range = range and range - 4 or 20000
    radius = radius == 0 and 1 or (radius + self:GetHitBox(unit)) - 4
    from = from and Vector(from) or Vector(myHero)

    local function CircleCircleIntersection(C1, C2, R1, R2)
        local D = GetDistance(C1, C2)
        local A = (R1 * R1 - R2 * R2 + D * D ) / (2 * D)
        local H = math.sqrt(R1 * R1 - A * A);
        local Direction = (Vector(C2) - Vector(C1)):normalized()
        local PA = Vector(C1) + A * Direction

        local S1 = PA + H * Direction:perpendicular()
        local S2 = PA - H * Direction:perpendicular()

        return S1, S2
    end

    local function GetPosiblePoints(from, pos, width, range)
        local middlepoint = (from + pos)/2
        local P1, P2 = CircleCircleIntersection(from, middlepoint, width, GetDistance(middlepoint, from))

        local V1 = (P1 - from)
        local V2 = (P2 - from)

        return from + range * (pos - V1 - from):normalized(), from + range * (pos - V2 - from):normalized()
    end

    local function CountHits(P1, P2, width, points)
        local hits = 0
        local hitt = {}
        width = width + 2
        for i, point in ipairs(points) do
            local pointSegment, pointLine, isOnSegment = VectorPointProjectionOnLineSegment(P1, P2, point)
            if isOnSegment and GetDistanceSqr(pointSegment, point) <= width * width then
                hits = hits + 1
                table.insert(hitt, point)
            elseif i == 1 then
                return -1
            end
        end
        return hits, hitt
    end

    for i, target in ipairs(GetEnemyHeroes()) do
        if target.networkID ~= unit.networkID and ValidTarget(target, range * 1.5) then
            CastPosition, HitChance, Position = self:GetBestCastPosition(target, delay, radius, range, speed, from, false, "line")
            if GetDistance(from, Position) < (range + radius) then
                table.insert(points, Position)
                table.insert(Positions, {unit = target, HitChance = HitChance, Position = Position, CastPosition = CastPosition})
            end
        end
    end

    local MaxHit = 1
    local MaxHitPos

    if #points > 1 then
        for i, candidate in ipairs(points) do
            local C1, C2 = GetPosiblePoints(from, points[i], radius - 20, range)
            local hits, MPoints1 = CountHits(from, C1, radius, points)
            local hits2, MPoints2 = CountHits(from, C2, radius, points)
            if hits >= MaxHit then
                MaxHitPos = C1
                MaxHit = hits
                MaxHitPoints = MPoints1
            end
            if hits2 >= MaxHit then
                MaxHitPos = C2
                MaxHit = hits2
                MaxHitPoints = MPoints2
            end
        end
    end

    if MaxHit > 1 then
        --center the line
        local maxdist = -1
        local p1
        local p2
        for i, hitp in ipairs(MaxHitPoints) do
            for o, hitp2 in ipairs(MaxHitPoints) do
                local StartP, EndP = Vector(from), (Vector(hitp) + Vector(hitp2)) / 2
                local pointSegment, pointLine, isOnSegment = VectorPointProjectionOnLineSegment(StartP, EndP, hitp)
                local pointSegment2, pointLine2, isOnSegment2 = VectorPointProjectionOnLineSegment(StartP, EndP, hitp2)

                local dist = GetDistanceSqr(hitp, pointLine) + GetDistanceSqr(hitp2, pointLine2)
                if dist >= maxdist then
                    maxdist = dist
                    p1 = hitp
                    p2 = hitp2
                end
            end
        end

        if self.ReturnHitTable then
            for i = #Positions, 1, -1 do
                local pointSegment, pointLine, isOnSegment = VectorPointProjectionOnLineSegment(Vector(from), (p1 + p2) / 2, Positions[i].Position)
                if (not isOnSegment) or (GetDistanceSqr(pointLine, Positions[i].Position) > (radius + 5)^2) then
                    table.remove(Positions, i)
                end
            end
        end

        return (p1 + p2) / 2, mainHitChance, MaxHit, Positions
    else
        return mainCastPosition, mainHitChance, 1, Positions
    end
end

function VPrediction:GetConeAOECastPosition(unit, delay, angle, range, speed, from)
    range = range and range - 4 or 20000
    radius = 1
    from = from and Vector(from) or Vector(myHero)
    angle = (angle < math.pi * 2) and angle or (angle * math.pi / 180)

    local CastPosition, HitChance, Position = self:GetBestCastPosition(unit, delay, radius, range, speed, from, false, "line")
    local points = {}
    local mainCastPosition, mainHitChance = CastPosition, HitChance

    table.insert(points, Vector(Position) - Vector(from))

    local function CountVectorsBetween(V1, V2, points)
        local result = 0
        local hitpoints = {}
        for i, test in ipairs(points) do
                local NVector = Vector(V1):crossP(test)
                local NVector2 = Vector(test):crossP(V2)
                if NVector.y >= 0 and NVector2.y >= 0 then
                        result = result + 1
                        table.insert(hitpoints, test)
                elseif i == 1 then
                        return -1 --doesnt hit the main target
                end
        end
        return result, hitpoints
    end

    local function CheckHit(position, angle, points)
        local direction = Vector(position):normalized()
        local v1 = Vector(position):rotated(0, -angle / 2, 0)
        local v2 = Vector(position):rotated(0, angle / 2, 0)
        return CountVectorsBetween(v1, v2, points)
    end

    for i, target in ipairs(GetEnemyHeroes()) do
        if target.networkID ~= unit.networkID and ValidTarget(target, range * 1.5) then
            CastPosition, HitChance, Position = self:GetBestCastPosition(target, delay, radius, range, speed, from, false, "line")
            if GetDistanceSqr(from, Position) < range * range then
                table.insert(points, Vector(Position) - Vector(from))
            end
        end
    end

    local MaxHitPos
    local MaxHit = 1
    local MaxHitPoints = {}

    if #points > 1 then
        for i, point in ipairs(points) do
            local pos1 = Vector(point):rotated(0, angle / 2, 0)
            local pos2 = Vector(point):rotated(0, - angle / 2, 0)

            local hits, points1 = CheckHit(pos1, angle, points)
            local hits2, points2 = CheckHit(pos2, angle, points)

            if hits >= MaxHit then
                MaxHitPos = C1
                MaxHit = hits
                MaxHitPoints = points1
            end
            if hits2 >= MaxHit then
                MaxHitPos = C2
                MaxHit = hits2
                MaxHitPoints = points2
            end
        end
    end

    if MaxHit > 1 then
        --Center the cone
        local maxangle = -1
        local p1
        local p2
        for i, hitp in ipairs(MaxHitPoints) do
                for o, hitp2 in ipairs(MaxHitPoints) do
                        local cangle = Vector():angleBetween(hitp2, hitp)
                        if cangle > maxangle then
                                maxangle = cangle
                                p1 = hitp
                                p2 = hitp2
                        end
                end
        end


        return Vector(from) + range * (((p1 + p2) / 2)):normalized(), mainHitChance, MaxHit
    else
        return mainCastPosition, mainHitChance, 1
    end
end

function VPrediction:OnTick()
    --[[Delete the old saved Waypoints]]
    if self.lastick == nil or self:GetTime() - self.lastick > 0.2 then
        self.lastick = self:GetTime()
        for i, enemy in pairs(GetEnemyHeroes()) do
            for i, tbl in pairs(PA[enemy.networkID]) do
                if os.clock() - 1.5 > tbl.t then
                    table.remove(PA[enemy.networkID], i)
                end
            end
        end
        for i, tbl in pairs(PA[myHero.networkID]) do
            if os.clock() - 1.5 > tbl.t then
                table.remove(PA[myHero.networkID], i)
            end
        end
        for NID, TargetWaypoints in pairs(self.TargetsWaypoints) do
            local i = 1
            while i <= #self.TargetsWaypoints[NID] do
                if self.TargetsWaypoints[NID][i]["time"] + self.WaypointsTime < self:GetTime() then
                    table.remove(self.TargetsWaypoints[NID], i)
                else
                    i = i + 1
                end
            end
        end
    end
end

--[[Drawing functions for debug: ]]
function VPrediction:DrawSavedWaypoints(object, time, color, drawPoints)
    colour = color and color or ARGB(255, 0, 255, 0)
    for i = object.pathIndex, object.pathCount do
        if object:GetPath(i) and object:GetPath(i-1) then
            local pStart = i == object.pathIndex and object.pos or object:GetPath(i-1)
            self:DLine(pStart, object:GetPath(i), colour)
        end
    end
    if drawPoints then
        local Waypoints = self:GetCurrentWayPoints(object)
        for i, waypoint in ipairs(Waypoints) do
            DrawCircle3D(waypoint.x, myHero.y, waypoint.z, 10, 2, ARGB(255, 0,0, 255), 200)
        end
    end
end

function VPrediction:DrawHitBox(object)
    DrawCircle3D(object.x, object.y, object.z, self:GetHitBox(object), 1, ARGB(255, 255, 255, 255))
    if object then
        DrawCircle3D(object.x, object.y, object.z, self:GetHitBox(object), 1, ARGB(255, 0, 255, 0))
    end
end

function VPrediction:DLine(From, To, Color)
    DrawLine3D(From.x, From.y, From.z, To.x, To.y, To.z, 2, Color)
end

function VPrediction:OnDraw()
    if self.showdevmode and _G.VPredictionMenu.Developers.Debug then
        LastGetTarget = LastGetTarget or myHero
        local target = GetTarget() or LastGetTarget
        LastGetTarget = target
        for i, enemy in ipairs(GetEnemyHeroes()) do
            self:DrawHitBox(enemy)
        end
        if _G.VPredictionMenu.Developers.SC then
            self.EnemyMinions:update()
            self.JungleMinions:update()
            self.OtherMinions:update()
            self:CheckMinionCollision(Vector(myHero) + 1050 * (Vector(mousePos) - Vector(myHero)):normalized(), 0.25, 70, 1050, 1800, myHero, true)
        end
        if target then
            self:DrawHitBox(target)
            local CastPosition,  HitChance,  Position = self:GetCircularCastPosition(target, 0.6, 70, 900, math.huge)
            if HitChance >= -1 then
                DrawText3D(tostring(HitChance), CastPosition.x, myHero.y, CastPosition.z, 40, ARGB(255, 255, 255, 255), true)
                DrawCircle3D(Position.x, myHero.y, Position.z, 70 + self:GetHitBox(target), 1, ARGB(255, 0, 255, 0))
                DrawCircle3D(CastPosition.x, myHero.y, CastPosition.z, 70 + self:GetHitBox(target), 1, ARGB(255, 255, 0, 0))
            end
            local waypoint = self:GetCurrentWayPoints(target)
            for i  = 1, #waypoint-1 do
                self:DLine(Vector(waypoint[i].x, myHero.y, waypoint[i].y), Vector(waypoint[i+1].x, myHero.y, waypoint[i+1].y), ARGB(255,255,255,255))
            end
        end
    end
end

function VPrediction:GetHitBox(object)
    if self.nohitboxmode and object.type and object.type == myHero.type then
        return 0
    end
    return (self.hitboxes[object.charName] ~= nil and self.hitboxes[object.charName] ~= 0) and self.hitboxes[object.charName]  or 65
end

function VPrediction:GetProjectileSpeed(unit)
    return self.projectilespeeds[unit.charName] and self.projectilespeeds[unit.charName] or math.huge
end

function VPrediction:CalcDamageOfAttack(source, target, spell, additionalDamage)
    -- read initial armor and damage values
    local armorPenPercent = source.armorPenPercent
    local armorPen = source.armorPen
    local totalDamage = source.totalDamage + (additionalDamage or 0)
    local damageMultiplier = spell.name:find("CritAttack") and 2 or 1

    -- minions give wrong values for armorPen and armorPenPercent
    if source.type == "obj_AI_Minion" then
        armorPenPercent = 1
    elseif source.type == "obj_AI_Turret" then
        armorPenPercent = 0.7
    end

    -- turrets ignore armor penetration and critical attacks
    if target.type == "obj_AI_Turret" then
        armorPenPercent = 1
        armorPen = 0
        damageMultiplier = 1
    end

    -- calculate initial damage multiplier for negative and positive armor

    local targetArmor = (target.armor * armorPenPercent) - armorPen
    if targetArmor < 0 then -- minions can't go below 0 armor.
        --damageMultiplier = (2 - 100 / (100 - targetArmor)) * damageMultiplier
        damageMultiplier = 1 * damageMultiplier
    else
        damageMultiplier = 100 / (100 + targetArmor) * damageMultiplier
    end

    -- use ability power or ad based damage on turrets
    if source.type == myHero.type and target.type == "obj_AI_Turret" then
        totalDamage = math.max(source.totalDamage, source.damage + 0.4 * source.ap)
    end

    -- minions deal less damage to enemy heros
    if source.type == "obj_AI_Minion" and target.type == myHero.type and source.team ~= TEAM_NEUTRAL then
        damageMultiplier = 0.60 * damageMultiplier
    end

    -- heros deal less damage to turrets
    if source.type == myHero.type and target.type == "obj_AI_Turret" then
        damageMultiplier = 0.95 * damageMultiplier
    end

    -- minions deal less damage to turrets
    if source.type == "obj_AI_Minion" and target.type == "obj_AI_Turret" then
        damageMultiplier = 0.475 * damageMultiplier
    end

    -- siege minions and superminions take less damage from turrets
    if source.type == "obj_AI_Turret" and (target.charName == "Red_Minion_MechCannon" or target.charName == "Blue_Minion_MechCannon") then
        damageMultiplier = 0.8 * damageMultiplier
    end

    -- caster minions and basic minions take more damage from turrets
    if source.type == "obj_AI_Turret" and (target.charName == "Red_Minion_Wizard" or target.charName == "Blue_Minion_Wizard" or target.charName == "Red_Minion_Basic" or target.charName == "Blue_Minion_Basic") then
        damageMultiplier = (1 / 0.875) * damageMultiplier
    end

    -- turrets deal more damage to all units by default
    if source.type == "obj_AI_Turret" then
        damageMultiplier = 1.05 * damageMultiplier
    end

    -- calculate damage dealt
    return damageMultiplier * totalDamage
end