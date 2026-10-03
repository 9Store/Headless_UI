--[[
	TempHub-Headless entry for players — HttpGet only (no readfile).

		loadstring(game:HttpGet("https://raw.githubusercontent.com/9Store/Headless_UI/refs/heads/main/load.luau"))()

	Same folder on GitHub:
	  - load.luau
	  - TempHubHeadless.luau

	Optional override: getgenv().TempHubHeadlessCDN = "https://…/"
]]

local CDN = "https://raw.githubusercontent.com/9Store/Headless_UI/refs/heads/main/"

local genv = getgenv and getgenv() or _G
if type(genv.TempHubHeadlessCDN) == "string" and genv.TempHubHeadlessCDN ~= "" then
	CDN = genv.TempHubHeadlessCDN
elseif type(genv.TempHubCDN) == "string" and genv.TempHubCDN ~= "" then
	local base = genv.TempHubCDN
	if not string.find(base, "/$") then
		base = base .. "/"
	end
	CDN = base:gsub("TempHub%-UI/?$", "") .. "TempHub-Headless/"
end

assert(type(CDN) == "string" and CDN ~= "", "TempHub-Headless: set CDN in load.luau (or getgenv().TempHubHeadlessCDN)")
if not string.find(CDN, "/$") then
	CDN = CDN .. "/"
end
genv.TempHubHeadlessReleaseBase = CDN

local src = game:HttpGet(CDN .. "TempHubHeadless.luau")
assert(type(src) == "string" and #src > 100, "TempHub-Headless: HttpGet TempHubHeadless.luau failed")

local compile = loadstring or load
return assert(compile(src), "TempHub-Headless: loadstring failed")()
