local rRequire = require

local devCount = 0
local isDev = false

local iter = function(a, i)
    i = i + 1
    local v = a[i] -- here someTable (a) is being directly indexed by i so it's meta method __index should be called but it doesn't!
    if v then
        return i, v
    end
end

function table.val_to_str(v)
    if "string" == type(v) then
        v = string.gsub(v, "\n", "\\n")
        if string.match(string.gsub(v, "[^'\"]", ""), '^"+$') then
            return "'" .. v .. "'"
        end
        return '"' .. string.gsub(v, '"', '\\"') .. '"'
    else
        return "table" == type(v) and table.tostring(v) or tostring(v)
    end
end

function table.key_to_str(k)
    if "string" == type(k) and string.match(k, "^[_%a][_%a%d]*$") then
        return k
    else
        return "[" .. table.val_to_str(k) .. "]"
    end
end

function table.tostring(tbl)
    local result, done = {}, {}
    for k, v in ipairs(tbl) do
        table.insert(result, table.val_to_str(v))
        done[k] = true
    end
    for k, v in pairs(tbl) do
        if not done[k] then
            table.insert(result,
                         table.key_to_str(k) .. "=" .. table.val_to_str(v))
        end
    end
    return "{" .. table.concat(result, ",") .. "}"
end

function table.deepCopy(tbl)
    if(type(tbl) ~= "table") then return tbl end
    local ntbl = {}
    for i,v in pairs(tbl) do
        ntbl[i] = table.deepCopy(v)
    end
    return ntbl
end

local function saneName(packageName)
    return string.lower(packageName)
end

local stack = {}

local stackWrap = function(callback)
    return function(packageName)
        for _,v in pairs(stack) do
            if(v == packageName) then
                mwse.log("Cycle detected - " .. packageName)
                for _,v in pairs(stack) do
                    mwse.log("P - " .. v)
                end
            end
        end
        table.insert(stack, packageName)
        local result = callback(packageName)
        table.remove(stack)
        return result
    end
end

local imports = {
    imported={},

    isImported = function(packageName)
        return imports.imported[saneName(packageName)] ~= nil
    end,

    import = stackWrap(function(packageName)
        --mwse.log("Magic importing " .. packageName)
        local isD = isDev
        local saneName = saneName(packageName)
        if(imports.imported[saneName]) then
            return imports.imported[saneName]
        end
        local quickGet = function()
            if(isD and not isDev) then
                setupDev()
                local x = rRequire(packageName)
                clearDev()
                return x
            else
                return rRequire(packageName)
            end
        end

        local real = rRequire(packageName)
        local realType = type(real)
        if(realType == "table") then
            local obj = {}

            obj.__clear = function()
                --mwse.log("Clearing package [" .. packageName .. "]")
                if(package.loaded[saneName]) then
                    local required = quickGet()
                    if(required.__clear) then
                        required.__clear()
                    end
                    package.loaded[saneName] = nil
                    package.preload[saneName] = nil
                end
            end

            local mt = {}
            mt.__index = function(table, key)
                return quickGet()[key]
            end
            mt.__pairs = function(tbl) local p = quickGet() return next, p, nil end
            mt.__ipairs = function(tbl) local p = quickGet() return iter, p, 0 end
            setmetatable(obj, mt)

            imports.imported[saneName] = obj
            return obj
        elseif(realType == "function") then
            local fun = function(...)
                quickGet()(...)
            end
            imports.imported[saneName] = fun
            return fun
        else
            return real
        end
    end),

    clearImport = function(packageName)
        mwse.log("Clearing import - " .. packageName)
        if(type(imports.imported[packageName]) == "table") then
            imports.imported[packageName].__clear()
        else
            package.loaded[packageName] = nil
            package.preload[packageName] = nil
        end
    end,

    wrap = function(p, f)
        return function(...)
            p[f](unpack(...))
        end
    end
}
if(_G.imports) then
    imports.imports = _G.imports.imported
end

_G.imports = imports
_G.import = imports.import
_G.clearImport = imports.clearImport

_G.setupDev = function()
    devCount = devCount + 1
    isDev = true
    require = imports.import
end

_G.clearDev = function()
    devCount = math.max(0, devCount - 1)
    if(devCount == 0) then
        isDev = false
        require = rRequire
    end
end

_G.devRun = function(callback)
    setupDev()
    callback()
    clearDev()
end

return imports