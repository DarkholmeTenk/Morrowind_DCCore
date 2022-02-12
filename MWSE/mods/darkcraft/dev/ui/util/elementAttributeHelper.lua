local elementAttributeHelper = {}

local function bool(value)
    if(type(value) == "string") then
        return value == "true"
    else
        return value
    end
end

local number = function(v)
    if(type(v) == "string") then
        return tonumber(v)
    else
        return v
    end
end

local function str(v)
    return tostring(v)
end



elementAttributeHelper.bool = bool
elementAttributeHelper.number = number
elementAttributeHelper.str = str

elementAttributeHelper.csvSplit = function(secondProcessor)
    return function(v)
        local t = {}
        for str in string.gmatch(v, "([^,]+)") do
            table.insert(t, secondProcessor(str))
        end
        return t
    end
end
local float3 = elementAttributeHelper.csvSplit(number)
elementAttributeHelper.float3 = float3

local VALID_ATTRS = {
    visible = bool,
    disabled = bool,
    positionX = number,
    positionY = number,
    absolutePosAlignX = number,
    absolutePosAlignY = number,
    width = number,
    height = number,
    widthProportional = number,
    heightProportional = number,
    minWidth = number,
    minHeight = number,
    maxWidth = number,
    maxHeight = number,
    autoWidth = bool,
    autoHeight = bool,
    flowDirection = str,
    alpha = number,

    color = float3,

    wrapText = bool,
    text = str,
    font = number,
    justifyText = str,

    borderAllSides = number,
    borderTop = number,
    borderLeft = number,
    borderBottom = number,
    borderRight = number,

    paddingAllSides = number,
    paddingTop = number,
    paddingLeft = number,
    paddingBottom = number,
    paddingRight = number,

    childAlignX = number,
    childAlignY = number,
    childOffsetX = number,
    childOffsetY = number
}

local CheatAttributes = {
    fullWidth = {
        widthProportional = "1"
    },
    fullHeight = {
        heightProportional = "1",
    },
    full = {
        widthProportional = "1",
        heightProportional = "1"
    },
    fullAuto = {
        autoWidth = "true",
        autoHeight = "true"
    },
    flowColumn = {
        flowDirection = "top_to_bottom"
    },
    flowRow = {
        flowDirection = "left_to_right"
    },
    bigColumn = {
        heightProportional = "1",
        widthProportional = "1",
        flowDirection = "top_to_bottom"
    },
    bigRow = {
        heightProportional = "1",
        widthProportional = "1",
        flowDirection = "left_to_right"
    },
    autoRow = {
        autoWidth = "true",
        autoHeight = "true",
        flowDirection = "left_to_right"
    },
    autoColumn = {
        autoWidth = "true",
        autoHeight = "true",
        flowDirection = "top_to_bottom"
    }
}

elementAttributeHelper.apply = function(element, attributes, widgets)
    for cheatTag, cheatValues in pairs(CheatAttributes) do
        if(attributes[cheatTag] ~= nil) then
            for realTag, realValue in pairs(cheatValues) do
                local sv = VALID_ATTRS[realTag](realValue)
                element[realTag] = sv
            end
        end
    end

    for i,v in pairs(VALID_ATTRS) do
        if(attributes[i] ~= nil) then
            local sv = v(attributes[i])
            element[i] = sv
        end
    end
    for i,v in pairs(widgets or {}) do
        if(attributes["widget." .. i] ~= nil) then
            element.widget[i] = v(attributes["widget." .. i])
        end
    end
    if(attributes.fixedSize) then
        element.minWidth = element.width
        element.maxWidth = element.width
        element.minHeight = element.height
        element.maxHeight = element.height
    end
end

return elementAttributeHelper
