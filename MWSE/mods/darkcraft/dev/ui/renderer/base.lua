local renderers = {}
local debug = require("darkcraft.core.debug")
local elementAttributeHelper = import("darkcraft.dev.ui.util.elementAttributeHelper")
local xmlreader = import("darkcraft.dev.ui.util.xmlreader")
local databind = import("darkcraft.dev.ui.util.databind")
local Delegate = require("darkcraft.dev.util.Delegate")
local TableHelper = require("darkcraft.dev.util.TableHelper")

local function debugUpdate(text)
    --mwse.log(text)
end

local function debugUpdateObj(o, text)
    --debug(o, text)
end

local function getArgs(attributes, extraArgs)
    local realID = nil
    if(attributes.id) then
        realID = tes3ui.registerID(elementAttributeHelper.number(attributes.id))
    end
    local args = {
        id = realID
    }
    for i,v in pairs(extraArgs) do
        if(attributes[i]) then
            args[i] = v(attributes[i])
        end
    end
    return args
end

local function purify(wrapped)
    return {
        render = function(me, renderer, parent, attributes, children, renderData)
            local attributeCopy = table.shallowCopy(attributes)
            local result = wrapped:render(renderer, parent, attributes, children, renderData)
            return Delegate.delegate(result, {
                update = function(newAttributes)
                    if(not TableHelper.eq(newAttributes, attributeCopy)) then
                        result.update(newAttributes)
                    end
                end
            })
        end
    }
end

renderers.replaceElement = {
    render = function(self, renderer, parent, attributes, children, renderData)
        local buildElement = function(attributes)
            local args = getArgs(attributes, self.extraArgs)
            local element = self.elementProducer(parent, args)
            elementAttributeHelper.apply(element, attributes)
            for _,v in pairs(self.events) do
                if(attributes[v] and type(attributes[v]) == "function") then
                    element:register(v, function(...) attributes[v](element, arg) end)
                end
            end
            renderer:renderChildren(element, children, renderData)
            return element
        end
        local element = buildElement(attributes)
        return {
            getFirstElement = function()
                return element
            end,

            getElementCount = function()
                return 1
            end,

            destroy = function()
                element:destroy()
            end,

            update = function(newAttributes)
                local newElement = buildElement(newAttributes)
                parent:reorderChildren(element, newElement, 1)
                element:destroy()
                element = newElement
            end
        }
    end,

    extend = function(self, elementProducer, extraArgs, events)
        local newObj = { elementProducer = elementProducer,
            extraArgs = extraArgs or {},
            events = events or {}}
        setmetatable(newObj, self)
        self.__index = self
        return newObj
    end
}

renderers.simpleElement = {
    render = function(self, renderer, parent, attributes, children, renderData)
        local args = getArgs(attributes, self.extraArgs)
        local element = self.elementProducer(parent, args)
        elementAttributeHelper.apply(element, attributes)
        local dead = false

        for _,v in pairs(self.events) do
            if(attributes[v] and type(attributes[v]) == "function") then
                element:register(v, function(...)
                    attributes[v](element, ..., renderer)
                end)
            end
        end
        local childrenObjs = renderer:renderChildren(element, children, renderData)
        return {
            element = element,
            destroy = function()
                if(not dead) then
                    dead = true
                    for _,v in pairs(childrenObjs) do v.destroy() end
                    element:destroy()
                end
            end,

            update = function(newAttributes)
                if(dead) then return end
                debugUpdateObj(newAttributes, "Updating SIMPLE attributes - " .. tostring(self.labelId))
                elementAttributeHelper.apply(element, newAttributes)
                attributes = newAttributes
                for _,v in pairs(childrenObjs) do
                    v.updateData()
                end
            end
        }
    end,

    withWidget = function(self, properties)
        local eArgs = self.extraArgs
        return {
            render = function(me, renderer, parent, attributes, children, renderData)
                local result = self:render(renderer, parent, attributes, children, renderData)
                return {
                    destroy = result.destroy,
                    update = function(newAttributes)
                        result.update(newAttributes)
                        local element = result.element
                        for _,property in pairs(properties) do
                            local value = newAttributes[property]
                            if(value ~= nil) then
                                if(eArgs[property]) then
                                    value = eArgs[property](value)
                                end
                                if(element.widget ~= nil and element.widget[property] ~= nil) then
                                    element.widget[property] = value
                                end
                            end
                        end
                    end
                }
            end
        }
    end,

    extend = function(self, elementProducer, extraArgs, events, widgets)
        local newObj = { elementProducer = elementProducer,
            extraArgs = extraArgs or {},
            events = events or {},
            widgets = widgets or {}}
        setmetatable(newObj, self)
        self.__index = self
        return newObj
    end
}

renderers.provider = {
    render = function(self, renderer, parent, attributes, children, renderData)
        local current = self.dataFunction(attributes, renderData, nil)
        local childrenObjs = renderer:renderChildren(parent, children, renderData)
        return {
            destroy = function()
            end,

            update = function(newAttributes)
                self.dataFunction(newAttributes, renderData, current)
            end
        }
    end,

    extend = function(self, dataFunction)
        local newObj = { dataFunction = dataFunction }
        setmetatable(newObj, self)
        self.__index = self
        return newObj
    end
}

local count = 0
renderers.xml = {
    render = function(self, renderer, parent, attributes, children, renderData)
        local data = databind:__wrap(table.shallowCopy(attributes))
        local destroyListeners = {}
        data.children = children
        data.uid = "UID" .. tostring(count)
        count = count + 1
        data.onDestroy = function(destroyId, destroyCallback)
            destroyListeners[destroyId] = destroyCallback
        end
        if(self.expand ~= nil) then
            self.expand(attributes, data, renderData)
        end
        local obj = renderer:render(parent, self.xml, data)
        return {
            destroy = function()
                --mwse.log("Destroying ".. obj.name)
                for _,v in pairs(destroyListeners) do v() end
                obj.destroy()
            end,

            update = function(newAttributes)
                for i,v in pairs(attributes) do
                    if(newAttributes[i] == nil) then
                        data[i] = nil
                    end
                end
                for i,v in pairs(newAttributes) do
                    data[i] = v
                end
                for _,v in pairs(destroyListeners) do v() end
                attributes = newAttributes
                if(self.expand) then
                    self.expand(attributes, data, renderData)
                end
                debugUpdate("Updating XML element (" .. self.xmlStr .. ")")
                debugUpdateObj(data, "XML Data")
                obj.updateData()
            end
        }
    end,

    extend = function(self, xmlString, expand)
        local newObj = { xml = xmlreader.parse(xmlString), xmlStr = xmlString, expand = expand }
        setmetatable(newObj, self)
        self.__index = self
        return newObj
    end
}

renderers.pure = purify

return renderers