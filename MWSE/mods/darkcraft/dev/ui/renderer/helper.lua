local base = import('darkcraft.dev.ui.renderer.base')
local eah = import("darkcraft.dev.ui.util.elementAttributeHelper")

local helper = {
    FieldLabel = base.xml:extend([[
        <Block flowDirection="left_to_right" autoWidth="true" autoHeight="true">
            <Block width="{fieldWidth}" autoHeight="true">
                <Label text="{fieldLabel}" />
            </Block>
            <Label text="{fieldValue}" wrapText="true"/>
        </Block>
    ]], function(attributes, data)
        data.fieldWidth = attributes.fieldWidth or 150
    end),
    Field = base.xml:extend([[
        <Block flowDirection="left_to_right" autoWidth="true" autoHeight="true">
            <Block width="{fieldWidth}" autoHeight="true">
                <Label text="{fieldLabel}" />
            </Block>
            <Children children="{children}"/>
        </Block>
    ]], function(attributes, data)
        data.fieldWidth = attributes.fieldWidth or 150
    end),
    Toggle = base.xml:extend([[
        <Button text="{text}" mouseClick="{click}" />
    ]], function(attributes, data)
        local isSet = attributes.default == "true" or attributes.default == true
        data.text = isSet and attributes.trueText or attributes.falseText
        data.click = function()
            isSet = not isSet
            data.text = isSet and attributes.trueText or attributes.falseText
            attributes.onChange(isSet)
        end
    end),
    ScaledSlider = base.xml:extend([[
        <Slider current="{calcCurrent}" max="{calcMax}" step="1" jump="{calcJump}" widthProportional="1" PartScrollBar_changed="{change}"/>
    ]], function(attributes, data)
        local diff = (attributes.max - attributes.min) / attributes.step
        data.calcMax = diff
        data.calcCurrent = (attributes.current - attributes.min) / attributes.step
        data.calcJump = attributes.jump / attributes.step
        data.change = function(e)
            attributes.onChange((e.widget.current * attributes.step) + attributes.min)
        end
    end)
}

return helper