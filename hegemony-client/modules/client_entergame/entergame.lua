EnterGame = {}

function safeDecrypt(text)
    if not text or text == '' then
        return ''
    end
    local success, result = pcall(g_crypt.decrypt, text)
    return success and result or ''
end

-- private variables
local loadBox
local enterGame
local motdWindow
local enterGameButton
local clientBox
local protocolLogin
local motdEnabled = true
local tokenWindow
local authErrorBox
local hasAttemptedAuthenticator = false
local serverBox
-- Cada tentativa de login ganha um numero novo. A resposta HTTP chega numa
-- thread separada: se o jogador cancelou e tentou de novo (ou trocou de
-- servidor), a resposta antiga ainda chega depois e nao pode abrir a lista
-- de personagens do servidor errado. O upstream usava math.random(1), que
-- devolve sempre 1 e anulava a checagem.
local loginRequestCounter = 0

-- private functions
local function serverByLogin(login)
    for _, server in ipairs(Hegemony_Servers or {}) do
        if server.login == login then
            return server
        end
    end
end

local function currentServer()
    local option = serverBox and serverBox:getCurrentOption()
    return (option and option.data) or (Hegemony_Servers and Hegemony_Servers[1])
end

-- "http://127.0.0.1:8088/login" -> "127.0.0.1", 8088, "/login"
local function splitLoginUrl(url)
    local host, port, path = url:match('^https?://([^/:]+):?(%d*)(.*)$')
    if not host then
        return '127.0.0.1', 80, '/login'
    end
    if path == '' then
        path = '/'
    end
    return host, tonumber(port) or 80, path
end
local function onError(protocol, message, errorCode)
    if loadBox then
        loadBox:destroy()
        loadBox = nil
    end

    if errorCode == 6 then
        if hasAttemptedAuthenticator then
            if authErrorBox then
              authErrorBox:destroy()
            end
            authErrorBox = displayErrorBox(tr('Authentication Failed'), tr('The token you entered is incorrect.'))
            connect(authErrorBox, {
              onOk = function()
                authErrorBox = nil
                EnterGame.showAuthenticatorInput()
              end
            })
        else
            EnterGame.showAuthenticatorInput()
        end

        return
    end

    if not errorCode then
        EnterGame.clearAccountFields()
    end

    local errorBox = displayErrorBox(tr('Login Error'), message)
    connect(errorBox, {
        onOk = EnterGame.show
    })
end

local function onMotd(protocol, motd)
    G.motdNumber = tonumber(motd:sub(0, motd:find('\n')))
    G.motdMessage = motd:sub(motd:find('\n') + 1, #motd)
end

local function onSessionKey(protocol, sessionKey)
    G.sessionKey = sessionKey
end

local function onCharacterList(protocol, characters, account, otui)
    local httpLogin = enterGame:getChildById('httpLoginBox'):isChecked()

    -- Try add server to the server list
    ServerList.add(G.host, G.port, g_game.getClientVersion(), httpLogin)

    -- Save 'Stay logged in' setting
    g_settings.set('staylogged', enterGame:getChildById('stayLoggedBox'):isChecked())
    g_settings.set('httpLogin', httpLogin)

    if enterGame:getChildById('rememberEmailBox'):isChecked() then
        local account = g_crypt.encrypt(G.account)
        local password = g_crypt.encrypt(G.password)

        g_settings.set('account', account)
        g_settings.set('password', password)

        ServerList.setServerAccount(G.host, G.account)
        ServerList.setServerPassword(G.host, G.password)
        ServerList.setServerAutologin(G.host, enterGame:getChildById('autoLoginBox'):isChecked())

        g_settings.set('autologin', enterGame:getChildById('autoLoginBox'):isChecked())
        ServerList.save()
    else
        -- reset server list account/password
        ServerList.setServerAccount(G.host, '')
        ServerList.setServerPassword(G.host, '')

        EnterGame.clearAccountFields()
    end

    if loadBox then
        loadBox:destroy()
        loadBox = nil
    end

    for _, characterInfo in pairs(characters) do
        if characterInfo.previewState and characterInfo.previewState ~= PreviewState.Default then
            characterInfo.worldName = characterInfo.worldName .. ', Preview'
        end
    end

    CharacterList.create(characters, account, otui)
    CharacterList.show()

    if motdEnabled then
        local lastMotdNumber = g_settings.getNumber('motd')
        if G.motdNumber and G.motdNumber ~= lastMotdNumber then
            g_settings.set('motd', G.motdNumber)
            motdWindow = displayInfoBox(tr('Message of the day'), G.motdMessage)
            connect(motdWindow, {
                onOk = function()
                    CharacterList.show()
                    motdWindow = nil
                end
            })
            CharacterList.hide()
        end
    end
end

local function onUpdateNeeded(protocol, signature)
    if loadBox then
        loadBox:destroy()
        loadBox = nil
    end

    if EnterGame.updateFunc then
        local continueFunc = EnterGame.show
        local cancelFunc = EnterGame.show
        EnterGame.updateFunc(signature, continueFunc, cancelFunc)
    else
        local errorBox = displayErrorBox(tr('Update needed'), tr('Your client needs updating, try redownloading it.'))
        connect(errorBox, {
            onOk = EnterGame.show
        })
    end
end

-- O cliente so fala o protocolo 1525, que entra por email; os textos ficam no
-- otui e aqui so se reafirma o titulo.
local function updateLabelText()
    enterGame:setText('Hegemony')
end

local function loadServerListModule()
    local module = g_modules.getModule('client_serverlist')

    if module and not module:isLoaded() then
        module:load()
    end
end

-- public functions
function EnterGame.init()
    enterGame = g_ui.displayUI('entergame')
    Keybind.new("Misc.", "Change Character", "Ctrl+G", "")
    Keybind.bind("Misc.", "Change Character", {
      {
        type = KEY_DOWN,
        callback = EnterGame.openWindow,
      }
    })

    local stayLogged = g_settings.getBoolean('staylogged')
    local clientVersion = 1525

    enterGame:getChildById('stayLoggedBox'):setChecked(stayLogged)
    enterGame:getChildById('httpLoginBox'):setChecked(true)

    -- A lista vem de Hegemony_Servers (init.lua). 'host' guarda a URL de
    -- login do ultimo servidor usado, e e por ela que ServerList guarda a
    -- conta de cada um.
    serverBox = enterGame:getChildById('serverComboBox')
    for _, server in ipairs(Hegemony_Servers or {}) do
        serverBox:addOption(server.name, server)
    end
    local lastServer = serverByLogin(g_settings.get('host'))
    if lastServer then
        serverBox:setCurrentOptionByData(lastServer, true)
    end

    local installedClients = {}
    if modules.client_assets and modules.client_assets.getInstalledClientVersions then
        installedClients = modules.client_assets.getInstalledClientVersions()
    else
        for _, dirItem in ipairs(g_resources.listDirectoryFiles('/data/things/')) do
            if tonumber(dirItem) then
                installedClients[dirItem] = true
            end
        end
    end

    local amountInstalledClients = 0
    for _ in pairs(installedClients) do
        amountInstalledClients = amountInstalledClients + 1
    end
    local canDownloadAssets = modules.client_assets and modules.client_assets.isEnabled and modules.client_assets.isEnabled()

    clientBox = enterGame:getChildById('clientComboBox')

    for _, proto in pairs(g_game.getSupportedClients()) do
        local protoStr = tostring(proto)
        if installedClients[protoStr] or amountInstalledClients == 0 or (canDownloadAssets and proto >= 1281) then
            installedClients[protoStr] = nil
            clientBox:addOption(proto)
        end
    end

    for protoStr, status in pairs(installedClients) do
        if status then
            print(string.format('Warning: %s recognized as an installed client, but not supported.', protoStr))
        end
    end

    clientBox:setCurrentOption(clientVersion)

    connect(clientBox, {
        onOptionChange = EnterGame.onClientVersionChange
    })

    connect(enterGame:getChildById('rememberEmailBox'), {
        onCheckChange = function(self, checked)
            local host = enterGame:getChildById('serverHostTextEdit'):getText()
            local account = enterGame:getChildById('accountNameTextEdit'):getText()
            local password = enterGame:getChildById('accountPasswordTextEdit'):getText()

            if checked and #account > 0 then
                ServerList.setServerAccount(host, account)
                ServerList.setServerPassword(host, password)
                ServerList.setServerAutologin(host, enterGame:getChildById('autoLoginBox'):isChecked() or false)
                g_settings.set('host', host)
            else
                ServerList.setServerAccount(host, '')
                ServerList.setServerPassword(host, '')
                ServerList.setServerAutologin(host, false)
            end

            ServerList.save()
            g_configs.saveSettings()
        end
    })

    EnterGame.setUniqueServer(nil, nil, clientVersion)
    EnterGame.selectServer(currentServer())
    connect(serverBox, {
        onOptionChange = EnterGame.onServerChange
    })
    updateLabelText()

    enterGame:hide()

    connect(g_game, {
        onGameStart = EnterGame.hidePanels
    })

    connect(g_game, {
        onGameEnd = EnterGame.showPanels
    })

    if g_app.isRunning() and not g_game.isOnline() then
        enterGame:show()
    end
end

function EnterGame.hidePanels()
    if g_modules.getModule("client_bottommenu"):isLoaded()  then
        modules.client_bottommenu.hide()
    end
    modules.client_topmenu.hide()
end

function EnterGame.showPanels()
    if g_modules.getModule("client_bottommenu"):isLoaded()  then
        modules.client_bottommenu.show()
    end
    modules.client_topmenu.show()
end

function EnterGame.showServerList()
    loadServerListModule()

    if ServerList then
        ServerList.show()
    end
end

function EnterGame.firstShow()
    EnterGame.show()

    local host = g_settings.get('host')
    local servers = g_settings.getNode('ServerList') or {}
    local serverData = servers[host] or {}
    local account = safeDecrypt(serverData.account)
    local password = safeDecrypt(serverData.password)
    local autologin = serverData.autologin == true
    if #host > 0 and #password > 0 and #account > 0 and autologin then
        addEvent(function()
            if not g_settings.getBoolean('autologin') then
                return
            end
            EnterGame.doLogin()
        end)
    end

    -- Disable webscraping HTTP requests to silence Bad Request logs
    -- if Services and Services.status then
    --     if g_modules.getModule("client_bottommenu"):isLoaded()  then
    --         EnterGame.postCacheInfo()
    --         EnterGame.postEventScheduler()
    --         EnterGame.postShowCreatureBoost()
    --     end
    -- end
end

function EnterGame.terminate()
    Keybind.delete("Misc.", "Change Character")

    disconnect(clientBox, {
        onOptionChange = EnterGame.onClientVersionChange
    })
    if serverBox then
        disconnect(serverBox, {
            onOptionChange = EnterGame.onServerChange
        })
        serverBox = nil
    end
    disconnect(g_game, {
        onGameStart = EnterGame.hidePanels
    })
    disconnect(g_game, {
        onGameEnd = EnterGame.showPanels
    })

    if enterGame then
        enterGame:destroy()
        enterGame = nil
    end

    if clientBox then
        clientBox = nil
    end

    if motdWindow then
        motdWindow:destroy()
        motdWindow = nil
    end

    if loadBox then
        loadBox:destroy()
        loadBox = nil
    end

    if protocolLogin then
        protocolLogin:cancelLogin()
        protocolLogin = nil
    end

    EnterGame = nil
end

local function reportRequestWarning(requestType, msg, errorCode)
    g_logger.warning(("[Webscraping - %s] %s"):format(requestType, msg), errorCode)
end

function EnterGame.postCacheInfo()
    return
end

function EnterGame.postEventScheduler()
    return
end

function EnterGame.postShowOff()
    return
end

function EnterGame.postShowCreatureBoost()
    return
end

function EnterGame.show()
    if g_game.isOnline() or CharacterList.isVisible() then -- fix login quickly error (http post)
        return
    end

    if loadBox then
        return
    end

    enterGame:show()
    enterGame:raise()
    enterGame:focus()
    hasAttemptedAuthenticator = false
end

function EnterGame.hide()
    enterGame:hide()
end

function EnterGame.openWindow()
    if g_game.isOnline() then
        CharacterList.show()
    elseif not g_game.isLogging() and not CharacterList.isVisible() then
        EnterGame.show()
    end
end

function EnterGame.setAccountName(account)
    local decrypted = safeDecrypt(account or '')
    enterGame:getChildById('accountNameTextEdit'):setText(decrypted)
    enterGame:getChildById('accountNameTextEdit'):setCursorPos(-1)
    enterGame:getChildById('rememberEmailBox'):setChecked(#decrypted > 0)
end

function EnterGame.setPassword(password)
    enterGame:getChildById('accountPasswordTextEdit'):setText(safeDecrypt(password or ''))
end

function EnterGame.setHttpLogin(httpLogin)
    if type(httpLogin) == "boolean" then
        enterGame:getChildById('httpLoginBox'):setChecked(httpLogin)
    else
        enterGame:getChildById('httpLoginBox'):setChecked(#httpLogin > 0)
    end
end

function EnterGame.clearAccountFields()
    enterGame:getChildById('accountNameTextEdit'):clearText()
    enterGame:getChildById('accountPasswordTextEdit'):clearText()
    enterGame:getChildById('accountNameTextEdit'):focus()
    g_settings.remove('account')
    g_settings.remove('password')
end

function EnterGame.toggleStayLoggedBox(clientVersion, init)
    local enabled = (clientVersion >= 1074)
    if enabled == enterGame.stayLoggedBoxEnabled then
        return
    end

    enterGame:getChildById('stayLoggedBox'):setOn(enabled)

    local newHeight = enterGame:getHeight()
    local newY = enterGame:getY()
    if enabled then
        newY = newY - enterGame.stayLoggedBoxHeight
        newHeight = newHeight + enterGame.stayLoggedBoxHeight
    else
        newY = newY + enterGame.stayLoggedBoxHeight
        newHeight = newHeight - enterGame.stayLoggedBoxHeight
    end

    if not init then
        enterGame:setY(newY)
        enterGame:bindRectToParent()
    end

    enterGame:setHeight(newHeight)
    enterGame.stayLoggedBoxEnabled = enabled
end

function EnterGame.onClientVersionChange(comboBox, text, data)
    local clientVersion = tonumber(text)
    EnterGame.toggleStayLoggedBox(clientVersion)
    updateLabelText()
end

-- Troca o servidor ativo: a conta lembrada, o texto de apoio e o G.host que
-- o resto do cliente usa como chave (hotkeys, ServerList) passam a ser dele.
function EnterGame.selectServer(server)
    if not server then
        return
    end

    G.server = server
    G.host = server.login
    -- Antes de mexer nos campos de conta: o onCheckChange do "lembrar" grava
    -- no host que estiver neste campo, e com o host antigo ali a troca de
    -- servidor apagaria a conta salva do servidor anterior.
    enterGame:getChildById('serverHostTextEdit'):setText(server.login)
    enterGame:getChildById('serverPortTextEdit'):setText(tostring(server.loginPort))
    enterGame:getChildById('serverDescriptionLabel'):setText(server.description or '')

    local servers = g_settings.getNode('ServerList') or {}
    local serverData = servers[server.login] or {}
    -- Senha antes da conta: setAccountName marca o "lembrar", e o handler
    -- dele salva o que estiver no campo de senha naquele instante.
    EnterGame.setPassword(serverData.password)
    EnterGame.setAccountName(serverData.account)
    enterGame:getChildById('autoLoginBox'):setChecked(serverData.autologin == true)
    EnterGame.setLoginWebService(server.login)
end

function EnterGame.onServerChange(comboBox, text, server)
    EnterGame.selectServer(server)
    g_settings.set('host', server and server.login or '')
    local accountEdit = enterGame:getChildById('accountNameTextEdit')
    if #accountEdit:getText() == 0 then
        accountEdit:focus()
    else
        enterGame:getChildById('accountPasswordTextEdit'):focus()
    end
end

function EnterGame.openSite(path)
    local server = currentServer()
    if server and server.site then
        g_platform.openUrl(server.site .. (path or ''))
    end
end

function EnterGame.setLoginWebService(url)
    url = url or (currentServer() or {}).login
    if not url then
        return
    end
    url = url:gsub("https://", "http://")
    G.host = url
    if Services then
        Services.loginWebService = url
        Services.login = url
        Services.status = url
    end
    if g_game and g_game.setLoginWebService then
        pcall(g_game.setLoginWebService, url)
    end
end

function EnterGame.tryHttpLogin(clientVersion, httpLogin)
    local server = G.server or currentServer()
    EnterGame.setLoginWebService(server.login)
    g_game.setClientVersion(clientVersion)
    g_game.setProtocolVersion(g_game.getClientProtocolVersion(clientVersion))
    g_game.chooseRsa(G.host)
    if not modules.game_things.isLoaded() then
        if loadBox then
            loadBox:destroy()
            loadBox = nil
        end

        local errorBox = displayErrorBox(tr("Login Error"), string.format("Things are not loaded, please put assets in things/%d/<assets>.", clientVersion))
        connect(errorBox, {
            onOk = EnterGame.show
        })
        return
    end

    -- Show connecting message immediately
    loadBox = displayCancelBox(tr('Connecting'), tr('Your character list is being loaded. Please wait.'))
    connect(loadBox, {
        onCancel = function(msgbox)
            loadBox = nil
            G.requestId = 0
            EnterGame.show()
        end
    })

    local host, port, path = splitLoginUrl(server.login)
    G.port = port

    if g_http then
        if g_http.setVerifyPeer then pcall(g_http.setVerifyPeer, false) end
        if g_http.setVerifyHost then pcall(g_http.setVerifyHost, false) end
    end
    if HTTP then
        if HTTP.setVerifyPeer then pcall(HTTP.setVerifyPeer, false) end
        if HTTP.setVerifyHost then pcall(HTTP.setVerifyHost, false) end
    end

    loginRequestCounter = loginRequestCounter + 1
    G.requestId = loginRequestCounter

    -- httpLogin = true vai direto no http://. Com false o cliente tenta HTTPS
    -- primeiro, falha (o login-server local nao tem TLS) e so entao cai no
    -- HTTP, deixando um erro de SSL no log a cada login.
    local http = LoginHttp.create()
    http:httpLogin(host, path, port, G.account, G.password, G.requestId, true, G.authenticatorToken)
end

function printTable(t)
    for k, v in pairs(t) do
        if type(v) == "table" then
            print(string.format("%q: {", k))
            printTable(v)
            print("}")
        else
            print(string.format("%q:", k) .. tostring(v) .. ",")
        end
    end
end

function EnterGame.loginSuccess(requestId, jsonSession, jsonWorlds, jsonCharacters)
    if requestId ~= G.requestId then
        return
    end

    if loadBox then
        loadBox:destroy()
        loadBox = nil
    end

    if tokenWindow then
        tokenWindow:destroy()
        tokenWindow = nil
    end

    -- Reservas para mundo sem endereco/porta na resposta: o host do proprio
    -- login-server e a porta de jogo declarada em Hegemony_Servers.
    local server = G.server or currentServer()
    local fallbackIp = splitLoginUrl(server.login)
    local fallbackPort = server.gamePort
    local fallbackName = server.name

    local success, err = pcall(function()
        local worlds = {}
        local decodedWorlds = (type(jsonWorlds) == "string" and json.decode(jsonWorlds) or jsonWorlds) or {}
        for _, world in ipairs(decodedWorlds) do
            local wIp = world.externaladdressprotected
            if not wIp or #wIp == 0 then wIp = world.externaladdress end
            if not wIp or #wIp == 0 then wIp = world.externaladdressunprotected end
            if not wIp or #wIp == 0 then wIp = fallbackIp end

            local wPort = tonumber(world.externalportprotected)
            if not wPort or wPort == 0 then wPort = tonumber(world.externalport) end
            if not wPort or wPort == 0 then wPort = tonumber(world.externalportunprotected) end
            if not wPort or wPort == 0 then wPort = fallbackPort end

            worlds[world.id or 0] = {
                name = world.name or fallbackName,
                ip = wIp,
                port = wPort,
                previewState = (world.previewstate == 1),
                pvptype = world.pvptype or 0,
            }
        end

        local characters = {}
        local decodedCharacters = (type(jsonCharacters) == "string" and json.decode(jsonCharacters) or jsonCharacters) or {}
        for index, character in ipairs(decodedCharacters) do
            local world = (character.worldid and worlds[character.worldid]) or worlds[0] or { name = fallbackName, ip = fallbackIp, port = fallbackPort, previewState = false, pvptype = 0 }
            characters[index] = {
                name = character.name,
                level = character.level or 1,
                main = character.ismaincharacter or false,
                dailyreward = character.dailyrewardstate or 0,
                hidden = character.ishidden or false,
                vocation = character.vocation or "Knight",
                outfitid = character.outfitid or 128,
                headcolor = character.headcolor or 0,
                torsocolor = character.torsocolor or 0,
                legscolor = character.legscolor or 0,
                detailcolor = character.detailcolor or 0,
                addonsflags = character.addonsflags or 0,
                worldName = world.name or fallbackName,
                worldIp = (world.ip and #world.ip > 0) and world.ip or fallbackIp,
                worldPort = (world.port and tonumber(world.port) > 0) and tonumber(world.port) or fallbackPort,
                previewState = world.previewState or false,
                pvptype = world.pvptype or 0,
            }
        end

        local session = (type(jsonSession) == "string" and json.decode(jsonSession) or jsonSession) or {}
        local premiumUntil = tonumber(session.premiumuntil) or 0
        local now = os.time()
        local premDays = (premiumUntil > now) and math.floor((premiumUntil - now) / 86400) or 0
        local subStatus = (premiumUntil > now) and (SubscriptionStatus and SubscriptionStatus.Premium or 1) or (SubscriptionStatus and SubscriptionStatus.Free or 0)

        local account = {
            status = session.status or '',
            premDays = premDays,
            subStatus = subStatus
        }

        G.sessionKey = (session and session.sessionkey and #session.sessionkey > 0) and session.sessionkey or ((G.account or "") .. "\n" .. (G.password or ""))

        onCharacterList(nil, characters, account)
    end)

    if not success then
        g_logger.error("Error processing loginSuccess: " .. tostring(err))
        EnterGame.show()
    end
end

function EnterGame.loginFailed(requestId, msg, result)
    if requestId ~= G.requestId then
        return
    end

    if loadBox then
        loadBox:destroy()
        loadBox = nil
    end
    onError(nil, msg, result)
end

function EnterGame.doLogin()
    G.account = enterGame:getChildById('accountNameTextEdit'):getText()
    G.password = enterGame:getChildById('accountPasswordTextEdit'):getText()
    G.stayLogged = enterGame:getChildById('stayLoggedBox'):isChecked()
    G.server = currentServer()
    G.host = G.server.login
    G.gameHost = (splitLoginUrl(G.server.login))
    G.port = G.server.loginPort
    local clientVersion = G.server.protocol or 1525
    G.clientVersion = clientVersion
    local httpLogin = true

    if g_game.isOnline() then
        local errorBox = displayErrorBox(tr('Login Error'), tr('Cannot login while already in game.'))
        connect(errorBox, {
            onOk = EnterGame.show
        })
        return
    end

    g_settings.set('host', G.host)
    g_settings.set('port', G.port)
    g_settings.set('client-version', clientVersion)

    if clientVersion >= 1281 and modules.client_assets and modules.client_assets.ensureClientVersion and
        (not modules.client_assets.isEnabled or modules.client_assets.isEnabled()) and
        not modules.client_assets.isClientVersionInstalled(clientVersion) then
        modules.client_assets.ensureClientVersion(clientVersion, function(success, message)
            if success then
                EnterGame.doLogin()
                return
            end

            local errorBox = displayErrorBox(tr('Login Error'), message or tr('Unable to download client assets.'))
            connect(errorBox, {
                onOk = EnterGame.show
            })
        end)
        return
    end

    EnterGame.hide()

    if clientVersion >= 1281 then
        EnterGame.tryHttpLogin(clientVersion, httpLogin)
    else
        protocolLogin = ProtocolLogin.create()
        protocolLogin.onLoginError = onError
        protocolLogin.onMotd = onMotd
        protocolLogin.onSessionKey = onSessionKey
        protocolLogin.onCharacterList = onCharacterList
        protocolLogin.onUpdateNeeded = onUpdateNeeded

        loadBox = displayCancelBox(tr('Please wait'), tr('Connecting to login server...'))

        connect(loadBox, {
            onCancel = function(msgbox)
                loadBox = nil
                protocolLogin:cancelLogin()
                EnterGame.show()
            end
        })

        g_game.setClientVersion(clientVersion)
        g_game.setProtocolVersion(g_game.getClientProtocolVersion(clientVersion))
        g_game.chooseRsa(G.host)

        if modules.game_things.isLoaded() then
            protocolLogin:login(G.host, G.port, G.account, G.password, G.authenticatorToken, G.stayLogged)
        else
            if loadBox then
                loadBox:destroy()
                loadBox = nil
            end

            local errorBox = displayErrorBox(tr("Login Error"), string.format("Things are not loaded, please put spr and dat in things/%d/<here>.", clientVersion))
            connect(errorBox, {
               onOk = EnterGame.show
            })
            return
        end
    end
end

function EnterGame.displayMotd()
    if not motdWindow then
        motdWindow = displayInfoBox(tr('Message of the day'), G.motdMessage)
        motdWindow.onOk = function()
            motdWindow = nil
        end
    end
end

function EnterGame.setDefaultServer(host, port, protocol)
    local hostTextEdit = enterGame:getChildById('serverHostTextEdit')
    local portTextEdit = enterGame:getChildById('serverPortTextEdit')
    local clientLabel = enterGame:getChildById('clientLabel')
    local accountTextEdit = enterGame:getChildById('accountNameTextEdit')
    local passwordTextEdit = enterGame:getChildById('accountPasswordTextEdit')

    if hostTextEdit:getText() ~= host then
        hostTextEdit:setText(host)
        portTextEdit:setText(port)
        clientBox:setCurrentOption(protocol)
        accountTextEdit:setText('')
        passwordTextEdit:setText('')
    end
end

-- Esconde os campos de servidor/versao do upstream. Host e porta ja nao
-- entram aqui: quem manda e o servidor escolhido (EnterGame.selectServer).
function EnterGame.setUniqueServer(host, port, protocol, windowWidth, windowHeight)
    protocol = protocol or 1525

    local hostTextEdit = enterGame:getChildById('serverHostTextEdit')
    hostTextEdit:setVisible(false)
    hostTextEdit:setHeight(0)

    local portTextEdit = enterGame:getChildById('serverPortTextEdit')
    portTextEdit:setVisible(false)
    portTextEdit:setHeight(0)

    local stayLoggedBox = enterGame:getChildById('stayLoggedBox')
    stayLoggedBox:setChecked(false)
    stayLoggedBox:setOn(false)

    local clientVersion = tonumber(protocol)
    clientBox:setCurrentOption(clientVersion)
    clientBox:setVisible(false)
    clientBox:setHeight(0)

    local serverLabel = enterGame:getChildById('serverLabel')
    serverLabel:setVisible(false)
    serverLabel:setHeight(0)

    local portLabel = enterGame:getChildById('portLabel')
    portLabel:setVisible(false)
    portLabel:setHeight(0)

    local clientLabel = enterGame:getChildById('clientLabel')
    clientLabel:setVisible(false)
    clientLabel:setHeight(0)

    local httpLoginBox = enterGame:getChildById('httpLoginBox')
    httpLoginBox:setChecked(false)
    httpLoginBox:setVisible(false)
    httpLoginBox:setHeight(0)

    local serverListButton = enterGame:getChildById('serverListButton')
    serverListButton:setVisible(false)
    serverListButton:setHeight(0)
    serverListButton:setWidth(0)

    -- O tamanho da janela vem do otui; so muda se quem chamar pedir.
    if windowWidth then
        enterGame:setWidth(windowWidth)
    end
    if windowHeight then
        enterGame:setHeight(windowHeight)
    end

    local server = currentServer()
    local serverInit = server and Servers_init[server.login]
    enterGame.disableToken = not (serverInit and serverInit.useAuthenticator)

    -- preload the assets
    -- this is for the client_bottommenu module
    -- it needs images of outfits
    -- so it can display the boosted creature
    g_game.setClientVersion(clientVersion)
    g_game.setProtocolVersion(g_game.getClientProtocolVersion(clientVersion))
end

function EnterGame.setServerInfo(message)
    local label = enterGame:getChildById('serverInfoLabel')
    label:setText(message)
end

function EnterGame.disableMotd()
    motdEnabled = false
end

function EnterGame.showAuthenticatorInput()
    if tokenWindow then
        tokenWindow:destroy()
        tokenWindow = nil
    end
    
    -- Create a custom message box with embedded text edit
    tokenWindow = g_ui.createWidget('MessageBoxWindow', rootWidget)
    tokenWindow.title = tokenWindow:getChildById('title')
    tokenWindow.title:setText(tr('Two-Factor Authentication'))
    
    tokenWindow.content = tokenWindow:getChildById('content')
    tokenWindow.content:setText(tr('Please enter a new, valid token:'))
    tokenWindow.content:setColor('#c0c0c0')
    tokenWindow.content:resizeToText()
    -- Align content to the left instead of center
    tokenWindow.content:breakAnchors()
    tokenWindow.content:addAnchor(AnchorLeft, 'parent', AnchorLeft)
    tokenWindow.content:addAnchor(AnchorTop, 'parent', AnchorTop)
    tokenWindow.content:setMarginLeft(15)
    tokenWindow.content:setMarginTop(32)
    
    -- Add text edit field for token input
    local tokenEdit = g_ui.createWidget('TextEdit', tokenWindow)
    tokenEdit:setId('tokenEdit')
    tokenEdit:addAnchor(AnchorHorizontalCenter, 'parent', AnchorHorizontalCenter)
    tokenEdit:addAnchor(AnchorTop, 'content', AnchorBottom)
    tokenEdit:setMarginTop(10)
    tokenEdit:setMaxLength(8)
    tokenEdit:setWidth(320)
    tokenEdit:setHeight(16)
    tokenEdit:setMarginLeft(15)
    tokenEdit:setMarginRight(15)
    tokenEdit:focus()
    
    -- Add horizontal separator
    local separator = g_ui.createWidget('HorizontalSeparator', tokenWindow)
    separator:setId('customSeparator')
    separator:addAnchor(AnchorLeft, 'parent', AnchorLeft)
    separator:addAnchor(AnchorRight, 'parent', AnchorRight)
    separator:addAnchor(AnchorTop, 'tokenEdit', AnchorBottom)
    separator:setMarginTop(10)
    separator:setMarginLeft(15)
    separator:setMarginRight(15)
    
    -- Reposition the holder to be below our custom separator
    tokenWindow.holder = tokenWindow:getChildById('holder')
    tokenWindow.holder:breakAnchors()
    tokenWindow.holder:addAnchor(AnchorRight, 'customSeparator', AnchorRight)
    tokenWindow.holder:addAnchor(AnchorLeft, 'customSeparator', AnchorLeft)
    tokenWindow.holder:addAnchor(AnchorTop, 'customSeparator', AnchorBottom)
    tokenWindow.holder:addAnchor(AnchorBottom, 'parent', AnchorBottom)
    tokenWindow.holder:setMarginTop(12)
    
    local okCallback = function()
        local token = tokenEdit:getText()
        if not token or token:len() == 0 then
            if authErrorBox then
              authErrorBox:destroy()
            end
            authErrorBox = displayErrorBox(tr('Error'), tr('Token is required.'))
            connect(authErrorBox, {
              onOk = function()
                authErrorBox = nil
                if tokenWindow then
                    tokenWindow:raise()
                    tokenWindow:focus()
                    tokenEdit:focus()
                end
              end
            })
            return
        end
        
        hasAttemptedAuthenticator = true
        
        G.account = enterGame:getChildById('accountNameTextEdit'):getText()
        G.password = enterGame:getChildById('accountPasswordTextEdit'):getText()
        G.server = currentServer()
        G.host = G.server.login
        G.port = G.server.loginPort
        G.authenticatorToken = token
        local clientVersion = G.server.protocol or 1525
        local httpLogin = true
        
        if tokenWindow then
            tokenWindow:destroy()
            tokenWindow = nil
        end
        
        EnterGame.tryHttpLogin(clientVersion, httpLogin)
    end
    
    local cancelCallback = function()
        hasAttemptedAuthenticator = false
        G.authenticatorToken = nil
        if tokenWindow then
            tokenWindow:destroy()
            tokenWindow = nil
        end
        EnterGame.show()
    end
        
    -- Add Cancel button (to the left of OK button)
    local cancelButton = tokenWindow:addButton(tr('Cancel'), cancelCallback)
    cancelButton:breakAnchors()
    cancelButton:addAnchor(AnchorTop, 'parent', AnchorTop)
    cancelButton:addAnchor(AnchorRight, 'parent', AnchorRight)
    cancelButton:setWidth(45)

    -- Add OK button (right side, added first)
    local okButton = tokenWindow:addButton(tr('Ok'), okCallback)
    okButton:breakAnchors()
    okButton:addAnchor(AnchorTop, 'prev', AnchorTop)
    okButton:addAnchor(AnchorRight, 'prev', AnchorLeft)
    okButton:setMarginRight(10)
    okButton:setWidth(40)
    
    -- Calculate window size based on content
    local windowWidth = 350
    local windowHeight = 28 + tokenWindow.content:getHeight() + 10 + tokenEdit:getHeight() + 10 + 2 + 12 + okButton:getHeight() + 12
    
    tokenWindow:setWidth(windowWidth)
    tokenWindow:setHeight(windowHeight)
    
    -- Connect Enter and Escape keys
    connect(tokenWindow, {
        onEnter = okCallback,
        onEscape = cancelCallback
    })
    
    -- Connect text edit Enter key
    connect(tokenEdit, {
        onEnter = okCallback
    })
end

function EnterGame.doLoginWithToken()
    local servers = Servers_init or {}
    local serverData = servers[G.host]
    if not (serverData and serverData.useAuthenticator) then
        print('Authenticator token is disabled for this server.')
        return
    end
    
    EnterGame.showAuthenticatorInput()
end

function EnterGame.destroyToken()
    if tokenWindow then
      if tokenWindow.destroy then
        tokenWindow:destroy()
      end
      tokenWindow = nil
      hasAttemptedAuthenticator = false
      G.authenticatorToken = nil
    end
end

function ensableBtnCreateNewAccount()
    enterGame.btnCreateNewAccount:enable()
end
