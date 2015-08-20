--[[
    GetWebResult bugsplat temp fix (All Scripts)
    Patch: 5.16
    Note: Remove after problem is fixed in BoL!
]]

function OnLoad()
    _G.GetWebResult = function(a,b)
      return "0"
    end
    print("Loaded GetWebResult Temp Fix...don't forget to remove later!")
end