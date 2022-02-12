local renderer = require("darkcraft.dev.ui.renderer")
local xmlreader = require("darkcraft.dev.ui.util.xmlreader")
local databind = require("darkcraft.dev.ui.util.databind")

local UiFramework = {
    wrapData = function(data)
        return databind:__wrap(data)
    end,

    setup = function(xmlString)
        local xml = xmlreader.parse(xmlString)
        local renderInstance = renderer:new()
        local data = nil

        local renderStep = {
            renderMenu = function()
                renderInstance:render(nil, xml, data)
            end,

            renderIn = function(element)
                renderInstance:render(element, xml, data)
            end
        }

        local withData = function(newData)
            data = newData
            return renderStep
        end

        local withSimpleData = function(newData)
            data = databind:__wrap(newData)
            return withData(data)
        end

        local withoutData = function()
            return withSimpleData({})
        end

        local dataStep = {
            withData = withData,
            withSimpleData = withSimpleData,
            withoutData = withoutData
        }

        return {
            withRenderGroup = function(group)
                renderInstance:addRenderGroups({group})
                return dataStep
            end,

            withRenderGroups = function(groupArray)
                renderInstance:addRenderGroups(groupArray)
                return dataStep
            end,

            withData = withData,
            withSimpleData = withSimpleData,
            withoutData = withoutData
        }
    end
}

return UiFramework