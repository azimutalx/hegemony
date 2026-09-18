-- Hegemony PvP Client Initialization Script

Services = {
    login = "http://127.0.0.1:8088/login",
    status = "http://127.0.0.1:8088/login",
    createAccount = "http://127.0.0.1:8088/login",
    loginWebService = "http://127.0.0.1:8088/login",
    websites = "http://127.0.0.1/",
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

local ENABLE_SERVERS = true

Servers_init = {}

if ENABLE_SERVERS then
    Servers_init = {
        ["http://127.0.0.1:8088/login"] = {
            port = 8088,
            protocol = 1525,
            httpLogin = false,
            useAuthenticator = false
        },
        ["127.0.0.1"] = {
            port = 7171,
            protocol = 1525,
            httpLogin = false
        }
    }
end

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
    
    g_window.setTitle("Hegemony PvP - Tactical War MMORPG")
end

-- run updater, must use data.zip
if g_app.hasUpdater() then
    g_modules.ensureModuleLoaded("updater")
    return Updater.init(loadModules)
end

loadModules()
