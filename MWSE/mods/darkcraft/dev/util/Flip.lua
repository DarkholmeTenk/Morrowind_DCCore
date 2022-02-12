local module = {}

module.flip = function(arr)
    local result = {}
    for i,v in pairs(arr) do
        result[v] = i
    end
    return result
end

return module