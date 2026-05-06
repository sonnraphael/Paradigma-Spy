local _require = require

function require(name)
    local ok, result = pcall(_require, name)
    if not ok then
        print("[ERROR][REQUIRE FAILED]:", name)
        print(result)
        return nil
    end

    if result == nil then
        print("[WARN][REQUIRE NIL]:", name)
    else
        print("[OK][REQUIRE]:", name)
    end

    return result
end

function safeCall(name, fn, ...)
    if type(fn) ~= "function" then
        print("[ERROR][NIL CALL]:", name, "=>", fn)
        print(debug.traceback())
        return nil
    end

    print("[CALL]:", name)
    return fn(...)
end

function wrapFunctions(tbl, path)
    if type(tbl) ~= "table" then return tbl end

    for k, v in pairs(tbl) do
        local currentPath = path .. "." .. tostring(k)

        if type(v) == "function" then
            tbl[k] = function(...)
                print("[FUNC CALL]:", currentPath)
                return v(...)
            end

        elseif type(v) == "table" then
            wrapFunctions(v, currentPath)
        end
    end

    return tbl
end

setmetatable(_G, {
    __index = function(_, key)
        print("[WARN][GLOBAL NIL ACCESS]:", key)
        return nil
    end
})

function safeIndex(tbl, key, path)
    if type(tbl) ~= "table" then
        print("[ERROR][INDEX NON-TABLE]:", path)
        return nil
    end

    local value = tbl[key]

    if value == nil then
        print("[WARN][NIL FIELD]:", path .. "." .. tostring(key))
    end

    return value
end

function requireWrap(name)
    local mod = require(name)

    if type(mod) == "table" then
        wrapFunctions(mod, name)
    end

    return mod
end

function runSafe(fn)
    local function errHandler(err)
        print("[FATAL ERROR]:", err)
        print(debug.traceback())
    end

    return xpcall(fn, errHandler)
end

--[[
	⣿⣿⣿⣿⣿⣿SIGMA SPY⣿⣿⣿⣿⣿⣿
	⣿⣿⣯⡉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠁
	⠉⠻⣿⣿⣦⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
	⠀⠀⠈⠻⣿⣿⣷⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
	⠀⠀⠀⠀⠀⠙⢿⣿⣿⣦⡀⠀⠀⠀⠀⠀⠀⠀⠀
	⠀⠀⠀⠀⠀⠀⠀⣉⣿⣿⣿⠆⠀⠀⠀⠀⠀⠀⠀
	⠀⠀⠀⠀⠀⣠⣾⣿⣿⠟⠁⠀⠀⠀⠀⠀⠀⠀⠀
	⠀⠀⢀⣴⣿⣿⡿⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
	⣀⣴⣿⣿⠟⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
	⣿⣿⣟⣁⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⡀
	⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇

    Written by @depso
    MIT License
    
    https://github.com/depthso
]]

--// File handling configuration 
local FilesConfig = {
	UseWorkspace = false,
	RepoUrl = "https://raw.githubusercontent.com/sonnraphael/Paradigma-Spy/refs/heads/main" -- "http://127.0.0.1:3000"
}

--// Service handlers
local Services = setmetatable({}, {
	__index = function(self, Name: string): Instance
		local Service = game:GetService(Name)
		return cloneref(Service)
	end,
})

--// Services
local Players: Players = Services.Players

--// Fetch Files module code
local FilesScript
if FilesConfig.UseWorkspace then
	FilesScript = readfile(`{FilesConfig.Folder}/lib/Files.lua`)
else
	FilesScript = game:HttpGet(`{FilesConfig.RepoUrl}/lib/Files.lua`)
end

--// Load files module
local Files = loadstring(FilesScript)()
Files:PushConfig(FilesConfig)
Files:Init({
	Services = Services
})

--// Modules
local Scripts = {
	--// User configurations
	Config = Files:GetModule("Sigma Spy/Config", "Config"),
	ReturnSpoofs = Files:GetModule("Sigma Spy/Return spoofs", "Return Spoofs"),

	--// Libraries
	Process = Files:GetModule("lib/Process"),
	Hook = Files:GetModule("lib/Hook"),
	Flags = Files:GetModule("lib/Flags"),
	Ui = Files:GetModule("lib/Ui"),
	Generation = Files:GetModule("lib/Generation"),
	Communication = Files:GetModule("lib/Communication")
}

--// Dependencies
local Modules = Files:LoadLibraries(Scripts)
local Process = Modules.Process
local Hook = Modules.Hook
local Config = Modules.Config
local Ui = Modules.Ui
local Generation = Modules.Generation
local Communication = Modules.Communication

--// Unpack config
local BlackListedServices = Config.BlackListedServices

--// Use custom font (optional)
local FontContent = Files:GetAsset("ProggyClean.ttf", true)
local FontJsonFile = Files:CreateFont("ProggyClean", FontContent)
Ui:SetFont(FontJsonFile, FontContent)

--// Actor code
local ActorCode = Files:CompileModule(Scripts)
ActorCode ..= [=[
	local ExtraData = {
		IsActor = true
	}
	print("ChannelId", ...)
	Libraries.Hook:BeginService(Libraries, ExtraData, ...)
]=]

--// Load modules
Files:LoadModules(Modules, {
	Modules = Modules,
	Services = Services
})

--// ReGui Create window
local Window = Ui:CreateWindow()

--// Check if Sigma spy is supported
local Supported = Process:CheckIsSupported()
if not Supported then 
	Window:Close()
	return
end

--// Generation swaps
local LocalPlayer = Players.LocalPlayer
Generation:SetSwapsCallback(function(self)
	self:AddSwap(LocalPlayer, {
		String = "LocalPlayer",
	})
	self:AddSwap(LocalPlayer.Character, {
		String = "Character",
		NextParent = LocalPlayer
	})
end)

--// Beta alert modal
Ui:ShowModal({
	"<b>Attention!</b>",
	"Sigma Spy is in BETA, please expect issues\n",
	"Report any issues to the Github page (depthso/Sigma-Spy)\n",
	"Many thanks!"
})

--// Create window content
Ui:CreateWindowContent(Window)

--// Create communication channel
local ChannelId = Communication:CreateChannel()
Communication:AddCommCallback("QueueLog", function(...)
	Ui:QueueLog(...)
end)

--// Begin hook
Hook:BeginService(Modules, nil, ChannelId) -- Run on self
Hook:RunOnActors(ActorCode, ChannelId) -- Run on actors

--// Remote added
game.DescendantAdded:Connect(function(Remote) -- TODO
	Hook:ConnectClientRecive(Remote)
end)

--// Collect missing remotes
Hook:MultiConnect(getnilinstances())

--// Search for remotes
for _, Service in next, game:GetChildren() do
	if table.find(BlackListedServices, Service.ClassName) then continue end
	Hook:MultiConnect(Service:GetDescendants())
end

--// Begin the Log queue service
Ui:BeginLogService()
