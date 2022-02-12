local module = {}

module.newSet = function()
    local values = {}
    local add = function(value)
        values[value] = true
    end

    local keys = function()
        local result = {}
        for i,_ in pairs(values) do
            table.insert(result, i)
        end
        return result
    end
    return {add = add, keys = keys}
end

return module