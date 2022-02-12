local inGetter = false
local function constructContext(contextObject, label)
    local oLabel = label or "Unknown"
    if(contextObject.__context == nil) then
        local result = {}
        local extra = {
            __context = result,
            __listeners = {},
            __getting = false
        }
        extra.__extra = extra
        local inCall = false
        local refresh = function(mLabel)
            if(not inCall and not inGetter) then
                local l = mLabel or "Unknown"
                local c = 0
                for _,_ in pairs(extra.__listeners) do c = c+1 end
                mwse.log("Hitting refresh callbacks. " .. oLabel .. "." .. l .. " - " ..tostring(c))
                inCall = true
                for _,v in pairs(extra.__listeners) do v() end
                inCall  = false
            end
        end
        extra.__refresh = refresh
        local mt = {
            __index = function(table, key)
                if(extra[key] ~= nil) then
                    return extra[key]
                end
                local value = contextObject[key]
                if(type(value) == "function") then
                    return function(...)
                        local subValue = {value(...)}
                        refresh(key)
                        return unpack(subValue)
                    end
                end
                return value
            end,
            __newindex = function(table, key, value)
                table[key] = value
                refresh(key)
            end
        }
        setmetatable(result, mt)
        contextObject.__context = result
    end
    return contextObject.__context
end

return {
    useContext = function(contextObject, label)
        return constructContext(contextObject, label or "UNLABELED")
    end,
    useContextValue = function(data, contextObject, valueName, getter)
        local g = getter or function() return contextObject[valueName] end
        local uid = data.uid
        local contextWrapper = constructContext(contextObject)
        local function refresh()
            inGetter = true
            local nv = g(contextWrapper)
            inGetter = false
            mwse.log("Getting " .. valueName .. " = " .. tostring(nv))
            if(data[valueName] ~= nv) then
                data[valueName] = nv
            end
        end
        data.onDestroy(valueName, function()
            contextWrapper.__listeners[uid] = nil
        end)
        contextWrapper.__listeners[uid] = function()
            refresh()
        end

        refresh()
    end,
    useContextValues = function(data, contextObject, xid, getter)
        mwse.log("Called useContextValues " .. xid)
        local g = getter or function() return contextObject[valueName] end
        local uid = data.uid
        local contextWrapper = constructContext(contextObject)
        local lastValue = {}
        local init = false
        local debugPrint = function(x) if(init) then mwse.log(x)  end end
        local function refresh()
            inGetter = true
            local nv = g(contextWrapper)
            inGetter = false
            for id, value in pairs(nv) do
                if(data[id] ~= value) then
                    debugPrint("Updating " .. xid .."." .. id .. " = " ..tostring(value))
                    data[id] = value
                end
            end
            for id, _ in pairs(lastValue) do
                if(data[id] ~= nv[id]) then
                    data[id] = nv[id]
                end
            end
            lastValue = nv
            init = true
        end
        data.onDestroy(xid, function()
            contextWrapper.__listeners[uid] = nil
        end)
        contextWrapper.__listeners[uid] = function()
            refresh()
        end

        refresh()
    end,
    refresh = function(contextObject)
        constructContext(contextObject).__refresh()
    end
}