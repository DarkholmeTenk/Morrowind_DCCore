local function eq(a, b)
    if(a == b) then return true end
    if(type(a) == type(b) and type(a) == "table") then
        for i,_ in pairs(a) do
            if(b[i] == nil) then return false end
        end
        for i,_ in pairs(b) do
            if(a[i] == nil) then return false end
        end
        for i,v in pairs(a) do
            if(not eq(v, b[i])) then
                return false
            end
        end
        return true
    end
    return false

end

return {
    flattenKeys = function(tab)
        local arr = {}
        for i,_ in pairs(tab) do
            table.insert(arr, i)
        end
        return arr
    end,

    randomPick = function(tab)
        local size = #tab
        local rand = math.floor(math.random(1, size + 1))
        return tab[rand], rand
    end,

    eq = eq
}