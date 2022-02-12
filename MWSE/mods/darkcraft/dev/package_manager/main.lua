require('darkcraft.dev.package_manager.import')

devRun(function()
    local menu = require('darkcraft.dev.package_manager.menu')
    local config = require('darkcraft.dev.config')
    local favs = require('darkcraft.dev.package_manager.favourites')

    local isKeybindPressed = function(e, kb)
        return e.keyCode == kb.keyCode and
                e.isControlDown == kb.isControlDown and
                e.isShiftDown == kb.isShiftDown and
                e.isAltDown == kb.isAltDown
    end

    event.register("keyDown", function(e)
        if(isKeybindPressed(e, config.getClearKeybind())) then
            for i,v in pairs(favs.getFavs()) do
                clearImport(i)
            end
            return
        end

        if(tes3ui.findMenu(menu.id) or not isKeybindPressed(e, config.getMenuKeybind())) then
            return
        end
        menu.open()
    end)
end)