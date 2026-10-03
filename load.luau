--[[
	TempHub-Headless entry for players — HttpGet only (no readfile).

		loadstring(game:HttpGet("https://raw.githubusercontent.com/OWNER/REPO/main/TempHub-Headless/load.luau"))()

	Upload to the same GitHub folder:
	  - load.luau          (this file — set CDN below)
	  - TempHubHeadless.luau

	Optional: getgenv().TempHubHeadlessCDN = "https://…/TempHub-Headless/"
]]

local CDN = "" -- e.g. "https://raw.githubusercontent.com/OWNER/REPO/main/TempHub-Headless/"

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
