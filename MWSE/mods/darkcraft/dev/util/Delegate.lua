return {
    delegate = function(original, overwrite)
        local newResult = {}
        for i,v in pairs(original) do
            newResult[i] = v
        end
        for i,v in pairs(overwrite) do
            newResult[i] = v
        end
        return newResult
    end
}