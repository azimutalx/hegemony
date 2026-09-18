local bottomMenu

function init()
    bottomMenu = g_ui.displayUI('bottommenu')
    if bottomMenu then
        bottomMenu:hide()
    end
end

function terminate()
    if bottomMenu then
        bottomMenu:destroy()
        bottomMenu = nil
    end
end

function hide()
    if bottomMenu then
        bottomMenu:hide()
    end
end

function show()
    if bottomMenu then
        bottomMenu:hide()
    end
end

function onClickOnCalendar() end
function onClickCloseCalendar() end
function setEventsSchedulerTimestamp(time) end
function reloadEventsSchedulerCurrentPage() end
function reloadEventsSchedulerCalender() end
function setEventsSchedulerCalender(calender) end
function setBoostedCreatureAndBoss(data) end
