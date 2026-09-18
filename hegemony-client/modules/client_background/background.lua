local background
local clientVersionLabel

function init()
    background = g_ui.displayUI('background')
    background:lower()

    clientVersionLabel = background:getChildById('clientVersionLabel')
    if clientVersionLabel then
        clientVersionLabel:setText("Hegemony PvP - Tactical War MMORPG\nBuild: 4.1 Release")
    end

    connect(g_game, {
        onGameStart = hide,
        onGameEnd = show
    })
end

function terminate()
    disconnect(g_game, {
        onGameStart = hide,
        onGameEnd = show
    })

    if background then
        background:destroy()
        background = nil
    end
    clientVersionLabel = nil
end

function hide()
    if background then
        background:hide()
    end
end

function show()
    if background then
        background:show()
    end
end

function hideVersionLabel()
    if clientVersionLabel then
        clientVersionLabel:hide()
    end
end

function setVersionText(text)
    if clientVersionLabel then
        clientVersionLabel:setText(text)
    end
end

function getBackground()
    return background
end
