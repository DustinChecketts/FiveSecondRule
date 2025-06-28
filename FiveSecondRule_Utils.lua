FiveSecondRule_Utils = {}
function FiveSecondRule_Utils:ShallowCopy(orig)
    local copy = {}
    for k, v in pairs(orig) do
        copy[k] = v
    end
    return copy
end
