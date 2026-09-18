-- Hegemony PvP Client Initialization Script

-- Services e do upstream; o login de verdade usa Hegemony_Servers (abaixo),
-- e EnterGame.setLoginWebService reescreve estes campos com o servidor
-- escolhido na tela de login.
Services = {
    websites = "",
    clientAssets = {
        enabled = false,
        repository = "dudantas/tibia-client",
        installSounds = true,
        strictManifestSha256 = false,
        allowRawFallbackHashMismatch = true,
        allowMissingPackedRawFallback = true,
        preferArchive = true,
        fallbackToArchiveOnManifestFailure = true,
        installArchiveExtras = true,
        archiveExtraPrefixes = { "bin" },
        installPackagedFiles = true
    },
}

-- Os servidores do cliente, NA ORDEM em que aparecem na tela de login.
-- Uma lista ordenada e a fonte: o Servers_init do upstream e um mapa, e pairs()
-- nao garante ordem. `login` e a URL do login-server (webservice); o endereco
-- e a porta do JOGO nao ficam aqui — vem na resposta do login, em
-- worlds[].externaladdressprotected / externalportprotected. `gamePort` so e
-- usado como reserva se a resposta vier sem porta.
--
-- Hegemony_Host e a maquina que roda o servidor: 127.0.0.1 para jogar na
-- propria maquina, o IP do Tailscale do anfitriao (100.x.y.z) no pacote dos
-- amigos. tools/empacotar.py troca so esta linha. O servidor precisa anunciar
-- o mesmo endereco (CANARY_SERVER_IP no docker/.env), porque o endereco do
-- JOGO vem da resposta do login, nao daqui.
--
-- Servidores de fora deste repositorio entram por mods/servidores_extras.lua
-- (lido mais abaixo, depois que a pasta mods/ entra no caminho de busca).
Hegemony_Host = "127.0.0.1"
Hegemony_Servers = {
    {
        name = "Hegemony PvP", description = "Mundo aberto, pvp-enforced, nasce no 80",
        login = "http://" .. Hegemony_Host .. ":8088/login", site = "http://" .. Hegemony_Host .. "/",
        loginPort = 7171, gamePort = 7172, protocol = 1525
    },
}

g_app.setName("Hegemony PvP")
g_app.setCompactName("hegemony")
g_app.setOrganizationName("hegemonypvp")

g_app.hasUpdater = function()
    return (Services.updater and Services.updater ~= "" and g_modules.getModule("updater"))
end

-- setup logger
g_logger.setLogFile(g_resources.getWorkDir() .. g_app.getCompactName() .. '.log')
g_logger.info("Operating system: " .. g_platform.getOSName())

-- print first terminal message
g_logger.info(g_app.getName() .. ' ' .. g_app.getVersion() .. ' rev ' .. g_app.getBuildRevision() .. ' (' ..
    g_app.getBuildCommit() .. ') built on ' .. g_app.getBuildDate() .. ' for arch ' ..
    g_app.getBuildArch())

-- add data directory to the search path
if not g_resources.addSearchPath(g_resources.getWorkDir() .. 'data', true) then
    g_logger.fatal('Unable to add data directory to the search path.')
end

-- add modules directory to the search path
if not g_resources.addSearchPath(g_resources.getWorkDir() .. 'modules', true) then
    g_logger.fatal('Unable to add modules directory to the search path.')
end

g_html.addGlobalStyle('/data/styles/html.css')
g_html.addGlobalStyle('/data/styles/custom.css')

-- try to add mods path too
g_resources.addSearchPath(g_resources.getWorkDir() .. 'mods', true)

if g_resources.fileExists('/servidores_extras.lua') then
    dofile('/servidores_extras.lua')
end

-- Servers_init continua existindo porque client_serverlist e partes do
-- entergame o consultam; sai de Hegemony_Servers ja com os extras. httpLogin =
-- true: com false o cliente tenta HTTPS antes a cada login e registra "SSL
-- connection failed" em todos.
Servers_init = {}
for _, servidor in ipairs(Hegemony_Servers) do
    Servers_init[servidor.login] = {
        port = servidor.loginPort,
        protocol = servidor.protocol,
        httpLogin = true,
        useAuthenticator = false
    }
end

-- setup directory for saving configurations
g_resources.setupUserWriteDir(('%s/'):format(g_app.getCompactName()))

-- search all packages
g_resources.searchAndAddPackages('/', '.otpkg', true)

-- load settings
g_configs.loadSettings('/config.otml')

g_modules.discoverModules()

-- libraries modules 0-99
g_modules.autoLoadModules(99)
g_modules.ensureModuleLoaded('corelib')
g_modules.ensureModuleLoaded('gamelib')
g_modules.ensureModuleLoaded('modulelib')
g_modules.ensureModuleLoaded("startup")

g_modules.autoLoadModules(999)
g_modules.ensureModuleLoaded('game_shaders') -- pre load

local function loadModules()
    -- client modules 100-499
    g_modules.autoLoadModules(499)
    g_modules.ensureModuleLoaded('client')

    -- game modules 500-999
    g_modules.autoLoadModules(999)
    g_modules.ensureModuleLoaded('game_interface')

    -- mods 1000-9999
    g_modules.autoLoadModules(9999)
    if g_modules.getModule('client_mods') then
        g_modules.ensureModuleLoaded('client_mods')
    end

    local script = '/' .. g_app.getCompactName() .. 'rc.lua'

    if g_resources.fileExists(script) then
        dofile(script)
    end
    
    g_window.setTitle("Hegemony")
end

-- run updater, must use data.zip
if g_app.hasUpdater() then
    g_modules.ensureModuleLoaded("updater")
    return Updater.init(loadModules)
end

loadModules()
