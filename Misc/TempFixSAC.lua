--[[
    GetWebResult bugsplat temp fix (SAC only)
    Patch: 5.16
    Note: Remove after problem is fixed in BoL!
]]

function OnLoad()
    _G.GetWebResultb = _G.GetWebResult
    _G.GetWebResult = function(a,b)
        return b:find("SidaBoL/") and "version=0.36" or GetWebResultb(a,b)
    end
    print("Loaded SAC Temp Fix...don't forget to remove when BoL problem is fixed!")
end