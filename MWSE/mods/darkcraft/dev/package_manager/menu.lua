local favs = require("darkcraft.dev.package_manager.favourites")
local renderer = require("darkcraft.dev.ui.renderer")
local xmlreader = require("darkcraft.dev.ui.util.xmlreader")
local databind = require("darkcraft.dev.ui.util.databind")
local elementRenderers = require("darkcraft.dev.package_manager.menu.MenuElements")

local menu = {}
local MenuID = tes3ui.registerID("DarkcraftPackageManager")
menu.id = MenuID

local menuXml = [[
    <Menu id="DarkcraftPackageManager" fixedFrame="true" width="600" height="800" autoHeight="false" autoWidth="false">
        <Label text="Favourites" />
        <VerticalScrollPane widthProportional="1" heightProportional="1.0">
            <PackageList packages="{favourites}" refresh="{refresh}" favourite="true" />
        </VerticalScrollPane>

        <Label text="Non-Favourite" />
        <VerticalScrollPane widthProportional="1" heightProportional="1.0">
            <PackageList packages="{nonFavourites}" refresh="{refresh}" favourite="false" />
        </VerticalScrollPane>
        <Block autoHeight="true" autoWidth="true" flowDirection="left_to_right">
            <Button mouseClick="{refresh}" text="Refresh" />
            <Button mouseClick="{DarkcraftPackageManager#close}" text="Close" />
        </Block>
    </Menu>
]]

function getPackages()
    local favList = {}
    local nonFavList = {}
    for i,v in pairs(package.loaded) do
        if(imports.isImported(i)) then
            if(favs.isFav(i)) then
                table.insert(favList, i)
            else
                table.insert(nonFavList, i)
            end
        end
    end
    table.sort(favList)
    table.sort(nonFavList)
    return favList, nonFavList
end

menu.open = function()
    mwse.log("Opening package manager UI")
    local favList, nonFavList = getPackages()
    local data = databind:__wrap{
        favourites = favList,
        nonFavourites = nonFavList
    }
    data.refresh = function()
        local favList, nonFavList = getPackages()
        data.favourites = favList
        data.nonFavourites = nonFavList
    end
    local xml = xmlreader.parse(menuXml)
    local renderInstance = renderer:new()
    renderInstance:addRenderGroups(elementRenderers)
    renderInstance:render(nil, xml, data)
end

return menu