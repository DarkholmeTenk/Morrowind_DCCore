local module = {}

module.shuffle = function(arr)
    local newArray = {}
    for _,v in pairs(arr) do
        local pos = math.random(1, #newArray + 1)
        table.insert(newArray, pos, v)
    end
    return newArray
end

return module