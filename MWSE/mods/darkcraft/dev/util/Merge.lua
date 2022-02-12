return {
    merge = function(tables)
        local newArr = {}
        for _,arr in ipairs(tables) do
            for i,v in pairs(arr) do
                newArr[i] = v
            end
        end
        return newArr
    end
}