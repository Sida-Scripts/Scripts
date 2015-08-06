_G.GetWebResultb = _G.GetWebResult
_G.GetWebResult = function(a,b)
    return b:find("SidaBoL/") and "version=90.56" or GetWebResultb(a,b)
end
print("Loaded SAC Temp Fix...don't forget to remove later!")