local base = require("darkcraft.dev.ui.renderer.base")

local packageListXml = [[
    <ForEach from="{packages}" value="packageName" flowDirection="top_to_bottom" widthProportional="1.0" heightProportional="1.0" >
        <PackageRow name="{packageName}" favourite="{favourite}" refresh="{refresh}" />
    </ForEach>
]]

local PackageListElement = base.xml:extend(packageListXml, function(attributes, data)
    data.packages = attributes.packages
    data.favourite = attributes.favourite
end)

return PackageListElement