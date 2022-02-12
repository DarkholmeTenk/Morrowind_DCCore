local base = require("darkcraft.dev.ui.renderer.base")
local favs = require("darkcraft.dev.package_manager.favourites")

local packageRowXml = [[
    <Block widthProportional="1" autoHeight="true" flowDirection="left_to_right">
        <Button text="X" mouseClick="{clear}" />
        <Label text="{name}" widthProportional="1" />
        <Button text="*" mouseClick="{favToggle}" />
    </Block>
]]

local PackageRowElement = base.xml:extend(packageRowXml, function(attributes, data)
    data.clear = function()
        clearImport(attributes.name)
        attributes.refresh()
    end
    data.favToggle = function()
        favs.toggleFav(attributes.name)
        attributes.refresh()
    end
    data.name = attributes.name
end)

return PackageRowElement