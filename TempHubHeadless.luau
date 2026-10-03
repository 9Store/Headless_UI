--[[
	TempHub Headless - kaitun status board. Not the full hub.

		local Headless = loadstring(readfile("TempHub-Headless/TempHubHeadless.luau"))()
		local Board = Headless:Create({ Title = "TEMPHUB" })
		Board:SetStatus("farming", "Accent")
]]

local genv = getgenv and getgenv() or _G
local BUILD = 13

if type(genv.TempHubHeadless) == "table" and genv._THHeadlessBuild == BUILD then
	return genv.TempHubHeadless
end

local function envFn(name)
	local f = rawget(_G, name)
	if type(f) == "function" then
		return f
	end
	if syn and type(syn[name]) == "function" then
		return syn[name]
	end
	if type(genv[name]) == "function" then
		return genv[name]
	end
	return nil
end

local function ref(inst)
	if type(cloneref) == "function" then
		local ok, v = pcall(cloneref, inst)
		if ok then
			return v
		end
	end
	return inst
end

local Players = ref(game:GetService("Players"))
local TweenService = ref(game:GetService("TweenService"))
local RunService = ref(game:GetService("RunService"))

local MAIN = Color3.fromRGB(10, 10, 10)
local SECOND = Color3.fromRGB(22, 22, 24)
local ACCENT = Color3.fromRGB(59, 130, 246)
local TEXT = Color3.fromRGB(244, 244, 245)
local MUTED = Color3.fromRGB(161, 161, 170)
local LINE = Color3.fromRGB(28, 28, 32)
local SUCCESS = Color3.fromRGB(74, 222, 128)
local WARN = Color3.fromRGB(251, 191, 36)
local FAILED = Color3.fromRGB(251, 113, 133)

local FONT_FAMILY = "rbxassetid://12187365364"
local FONT_GOTHAM = "rbxasset://fonts/families/GothamSSm.json"
local FONT = Font.new(FONT_FAMILY, Enum.FontWeight.Medium, Enum.FontStyle.Normal)
local FONT_BOLD = Font.new(FONT_FAMILY, Enum.FontWeight.Bold, Enum.FontStyle.Normal)
local FONT_HEAVY = Font.new(FONT_GOTHAM, Enum.FontWeight.Heavy, Enum.FontStyle.Normal)
local FONT_SEMI = Font.new(FONT_FAMILY, Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)

local LOGO_PATHS = {
	"TempHub-UI/261b4a73-267f-449e-89eb-4d487d75ce3a.png",
	"TempHub-UI\\261b4a73-267f-449e-89eb-4d487d75ce3a.png",
	"TempHub-Headless/temphub-logo.png",
	"TempHub-Headless\\temphub-logo.png",
	"temp/temphub-logo.png",
}

local function withSlash(base)
	if type(base) ~= "string" or base == "" then
		return nil
	end
	if not string.find(base, "/$") then
		return base .. "/"
	end
	return base
end

local function httpGet(url, minLen)
	if type(url) ~= "string" or url == "" then
		return nil
	end
	minLen = tonumber(minLen) or 500
	local ok, src = pcall(function()
		return game:HttpGet(url)
	end)
	if not (ok and type(src) == "string") then
		ok, src = pcall(function()
			return game:HttpGetAsync(url)
		end)
	end
	if ok and type(src) == "string" and #src >= minLen then
		return src
	end
	return nil
end

local TONE = {
	Accent = ACCENT,
	Success = SUCCESS,
	Warn = WARN,
	Failed = FAILED,
	Muted = MUTED,
	Text = TEXT,
	Info = TEXT,
}

local function toneColor(name)
	if typeof(name) == "Color3" then
		return name
	end
	return TONE[tostring(name or "")] or TEXT
end

local function asText(v)
	if type(v) == "string" then
		return v
	end
	if type(v) == "number" then
		return tostring(v)
	end
	return ""
end

local function tween(inst, dur, props, style)
	local tw = TweenService:Create(
		inst,
		TweenInfo.new(dur, style or Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		props
	)
	tw:Play()
	return tw
end

local function corner(inst, px)
	local c = inst:FindFirstChildOfClass("UICorner")
	if not c then
		c = Instance.new("UICorner")
		c.Parent = inst
	end
	c.CornerRadius = UDim.new(0, px)
	return c
end

local function circle(inst)
	local c = corner(inst, 0)
	c.CornerRadius = UDim.new(1, 0)
	return c
end

local function pad(inst, t, r, b, l)
	local p = Instance.new("UIPadding")
	p.PaddingTop = UDim.new(0, t)
	p.PaddingRight = UDim.new(0, r or t)
	p.PaddingBottom = UDim.new(0, b or t)
	p.PaddingLeft = UDim.new(0, l or r or t)
	p.Parent = inst
	return p
end

local function label(parent, props)
	local lab = Instance.new("TextLabel")
	lab.BackgroundTransparency = 1
	lab.BorderSizePixel = 0
	lab.FontFace = props.Font or FONT
	lab.Text = props.Text or ""
	lab.TextColor3 = props.Color or TEXT
	lab.TextSize = props.Size or 13
	lab.TextXAlignment = props.Align or Enum.TextXAlignment.Left
	lab.TextYAlignment = props.VAlign or Enum.TextYAlignment.Center
	lab.TextTruncate = props.Truncate or Enum.TextTruncate.AtEnd
	lab.RichText = props.Rich == true
	lab.ZIndex = props.ZIndex or 2
	if props.Auto then
		lab.AutomaticSize = props.Auto
		lab.Size = props.SizeDim or UDim2.new(0, 0, 0, props.H or 16)
	else
		lab.Size = props.SizeDim or UDim2.new(1, 0, 0, props.H or 16)
	end
	lab.Position = props.Pos or UDim2.fromOffset(0, 0)
	lab.Parent = parent
	return lab
end

local function guiParent()
	local ok, core = pcall(function()
		return ref(game:GetService("CoreGui"))
	end)
	if ok and core then
		return core
	end
	if type(gethui) == "function" then
		local okH, h = pcall(gethui)
		if okH and h then
			return h
		end
	end
	local lp = Players.LocalPlayer
	return lp and lp:FindFirstChildOfClass("PlayerGui")
end

local function eachGuiRoot(fn)
	local seen = {}
	local function add(root)
		if root and not seen[root] then
			seen[root] = true
			fn(root)
		end
	end
	pcall(function()
		add(ref(game:GetService("CoreGui")))
	end)
	if type(gethui) == "function" then
		pcall(function()
			add(gethui())
		end)
	end
	local lp = Players.LocalPlayer
	if lp then
		add(lp:FindFirstChildOfClass("PlayerGui"))
	end
end

local function resolveLogo()
	local gca = envFn("getcustomasset") or envFn("getsynasset")
	if type(gca) ~= "function" then
		return nil
	end
	local cachePath = "temp/temphub-logo.png"
	local function tryPath(path)
		local ok, asset = pcall(gca, path)
		if ok and type(asset) == "string" and asset ~= "" then
			return asset
		end
		return nil
	end
	for _, path in ipairs(LOGO_PATHS) do
		local asset = tryPath(path)
		if asset then
			return asset
		end
	end
	-- Players: no local png — HttpGet from Headless CDN into temp/, then getcustomasset.
	local urls = {}
	local seen = {}
	local function addUrl(u)
		if type(u) ~= "string" or u == "" or seen[u] then
			return
		end
		seen[u] = true
		urls[#urls + 1] = u
	end
	addUrl(genv.TempHubLogoUrl)
	local function addBase(base)
		base = withSlash(base)
		if not base then
			return
		end
		addUrl(base .. "temphub-logo.png")
		addUrl(base .. "261b4a73-267f-449e-89eb-4d487d75ce3a.png")
	end
	addBase(genv.TempHubHeadlessReleaseBase)
	addBase(genv.TempHubHeadlessCDN)
	addBase(genv.TempHubReleaseBase)
	addBase("https://raw.githubusercontent.com/9Store/Headless_UI/refs/heads/main/")
	local writeFile = envFn("writefile")
	local makeFolder = envFn("makefolder") or envFn("mkdir")
	if type(writeFile) ~= "function" then
		return nil
	end
	for _, url in ipairs(urls) do
		local src = httpGet(url, 500)
		if src then
			pcall(function()
				if type(makeFolder) == "function" then
					makeFolder("temp")
				end
			end)
			local ok = pcall(writeFile, cachePath, src)
			if ok then
				local asset = tryPath(cachePath)
				if asset then
					return asset
				end
			end
		end
	end
	return nil
end

local lockConn
local function stopLock()
	if lockConn then
		lockConn:Disconnect()
		lockConn = nil
	end
end

local function wipeOld()
	stopLock()
	eachGuiRoot(function(root)
		local old = root:FindFirstChild("TempHubHeadless")
		if old then
			old:Destroy()
		end
		-- Nested under RobloxGui from older builds
		for _, d in root:GetChildren() do
			if d.Name == "TempHubHeadless" then
				d:Destroy()
			end
		end
	end)
end

local function makeRow(parent, key, value, valueTone)
	local row = Instance.new("Frame")
	row.Name = "Row"
	row.BackgroundTransparency = 1
	row.BorderSizePixel = 0
	row.Size = UDim2.new(1, 0, 0, 18)
	row.Parent = parent
	local k = label(row, {
		Text = asText(key),
		Color = MUTED,
		Size = 12,
		H = 18,
		SizeDim = UDim2.new(0.52, 0, 1, 0),
	})
	k.Name = "Key"
	local v = label(row, {
		Text = asText(value),
		Color = toneColor(valueTone),
		Font = FONT_SEMI,
		Size = 12,
		H = 18,
		Align = Enum.TextXAlignment.Right,
		SizeDim = UDim2.new(0.48, 0, 1, 0),
		Pos = UDim2.new(0.52, 0, 0, 0),
	})
	v.Name = "Value"
	return row
end

local function makePairCell(parent, key, value, valueTone)
	local cell = Instance.new("Frame")
	cell.BackgroundTransparency = 1
	cell.BorderSizePixel = 0
	cell.Size = UDim2.new(0.5, -4, 0, 18)
	cell.Parent = parent
	label(cell, {
		Text = asText(key),
		Color = MUTED,
		Size = 11,
		H = 18,
		SizeDim = UDim2.new(1, -40, 1, 0),
	})
	label(cell, {
		Text = asText(value),
		Color = toneColor(valueTone),
		Font = FONT_SEMI,
		Size = 11,
		H = 18,
		Align = Enum.TextXAlignment.Right,
		SizeDim = UDim2.new(0, 36, 1, 0),
		Pos = UDim2.new(1, -36, 0, 0),
	})
	return cell
end

local function sectionTitle(parent, title)
	local wrap = Instance.new("Frame")
	wrap.Name = "SectionHead"
	wrap.BackgroundTransparency = 1
	wrap.Size = UDim2.new(1, 0, 0, 16)
	wrap.Parent = parent
	local lab = label(wrap, {
		Text = string.upper(asText(title)),
		Color = MUTED,
		Font = FONT_BOLD,
		Size = 10,
		H = 14,
	})
	return wrap, lab
end

local function makeDivider(parent, title)
	title = string.upper(asText(title))
	local wrap = Instance.new("Frame")
	wrap.Name = "Divider"
	wrap.BackgroundTransparency = 1
	wrap.BorderSizePixel = 0
	wrap.Size = UDim2.new(1, 0, 0, title ~= "" and 16 or 8)
	wrap.Parent = parent

	local line = Instance.new("Frame")
	line.Name = "Line"
	line.AnchorPoint = Vector2.new(0, 0.5)
	line.BackgroundColor3 = LINE
	line.BackgroundTransparency = 0.05
	line.BorderSizePixel = 0
	line.Position = UDim2.new(0, 0, 0.5, 0)
	line.Size = UDim2.new(1, 0, 0, 1)
	line.ZIndex = 2
	line.Parent = wrap

	if title ~= "" then
		local lab = label(wrap, {
			Text = title,
			Color = MUTED,
			Font = FONT_BOLD,
			Size = 10,
			H = 16,
			Auto = Enum.AutomaticSize.X,
			SizeDim = UDim2.fromOffset(0, 16),
		})
		lab.Name = "Title"
		lab.BackgroundColor3 = MAIN
		lab.BackgroundTransparency = 0
		lab.ZIndex = 3
		pad(lab, 0, 8, 0, 0)
	end
	return wrap
end

local function createLib()
	local lib = {}

	function lib:Create(cfg)
		cfg = type(cfg) == "table" and cfg or {}
		wipeOld()
		local width = math.max(240, tonumber(cfg.Width) or 312)
		local parent = cfg.Parent or guiParent()
		assert(parent, "TempHub Headless: no UI parent")

		local gui = Instance.new("ScreenGui")
		gui.Name = "TempHubHeadless"
		gui.IgnoreGuiInset = true
		gui.ResetOnSpawn = false
		gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		gui.DisplayOrder = 999999
		pcall(function()
			gui.ScreenInsets = Enum.ScreenInsets.None
		end)
		pcall(function()
			gui.ClipToDeviceSafeArea = false
		end)
		pcall(function()
			gui.SafeAreaCompatibility = Enum.SafeAreaCompatibility.None
		end)
		gui.Parent = parent

		-- CanvasGroup + explicit height (not AutomaticSize) so UICorner actually clips.
		local card = Instance.new("CanvasGroup")
		card.Name = "Board"
		card.Active = false
		card.AnchorPoint = Vector2.new(0.5, 0.5)
		card.BackgroundColor3 = MAIN
		card.BackgroundTransparency = 0.04
		card.BorderSizePixel = 0
		card.GroupColor3 = Color3.new(1, 1, 1)
		card.GroupTransparency = 0
		card.Position = UDim2.fromScale(0.5, 0.5)
		card.Size = UDim2.fromOffset(width, 54)
		card.ZIndex = 1
		card.Parent = gui
		local cardCorner = Instance.new("UICorner")
		cardCorner.Name = "TempHubCorner"
		cardCorner.CornerRadius = UDim.new(0, 16)
		cardCorner.Parent = card
		local HEADER_H = 48
		local IDENTITY_H = 56
		local FOOTER_H = 18
		local STACK_PAD = 8
		local BODY_PAD_Y = 20

		local CENTER = UDim2.fromScale(0.5, 0.5)
		local function lockCenter()
			if not card.Parent then
				return
			end
			card.AnchorPoint = Vector2.new(0.5, 0.5)
			if card.Position ~= CENTER then
				card.Position = CENTER
			end
		end
		lockCenter()
		card:GetPropertyChangedSignal("Position"):Connect(lockCenter)
		gui:GetPropertyChangedSignal("AbsolutePosition"):Connect(lockCenter)
		pcall(function()
			workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
				local cam = workspace.CurrentCamera
				if cam then
					cam:GetPropertyChangedSignal("ViewportSize"):Connect(lockCenter)
				end
				lockCenter()
			end)
			local cam = workspace.CurrentCamera
			if cam then
				cam:GetPropertyChangedSignal("ViewportSize"):Connect(lockCenter)
			end
		end)
		lockConn = RunService.Heartbeat:Connect(lockCenter)

		local header = Instance.new("Frame")
		header.Name = "Header"
		header.BackgroundTransparency = 1
		header.BorderSizePixel = 0
		header.Size = UDim2.new(1, 0, 0, HEADER_H)
		header.ZIndex = 2
		header.Parent = card

		local logoAsset = resolveLogo()
		local logo = Instance.new("ImageLabel")
		logo.Name = "Logo"
		logo.BackgroundTransparency = 1
		logo.Position = UDim2.fromOffset(14, 8)
		logo.Size = UDim2.fromOffset(32, 32)
		logo.ZIndex = 4
		logo.Parent = header
		corner(logo, 10)
		if logoAsset then
			logo.Image = logoAsset
		else
			logo.BackgroundColor3 = ACCENT
			logo.BackgroundTransparency = 0.15
			label(logo, {
				Text = "TH",
				Color = TEXT,
				Font = FONT_HEAVY,
				Size = 11,
				H = 32,
				Align = Enum.TextXAlignment.Center,
				SizeDim = UDim2.fromScale(1, 1),
			})
		end

		local brand = label(header, {
			Text = asText(cfg.Title) ~= "" and string.upper(asText(cfg.Title)) or "TEMPHUB",
			Color = ACCENT,
			Font = FONT_HEAVY,
			Size = 14,
			H = HEADER_H,
			SizeDim = UDim2.new(1, -88, 1, 0),
			Pos = UDim2.fromOffset(54, 0),
		})
		brand.Name = "Brand"
		brand.TextTruncate = Enum.TextTruncate.AtEnd

		-- Minimize: same ghost language as pager < > - thin bar glyph, no chunky tile.
		local hideBtn = Instance.new("TextButton")
		hideBtn.Name = "Hide"
		hideBtn.AutoButtonColor = false
		hideBtn.AnchorPoint = Vector2.new(1, 0.5)
		hideBtn.BackgroundTransparency = 1
		hideBtn.BorderSizePixel = 0
		hideBtn.Text = ""
		hideBtn.Position = UDim2.new(1, -8, 0.5, 0)
		hideBtn.Size = UDim2.fromOffset(22, 22)
		hideBtn.ZIndex = 8
		hideBtn.Parent = header

		local hideBar = Instance.new("Frame")
		hideBar.Name = "Bar"
		hideBar.AnchorPoint = Vector2.new(0.5, 0.5)
		hideBar.BackgroundColor3 = MUTED
		hideBar.BorderSizePixel = 0
		hideBar.Position = UDim2.fromScale(0.5, 0.52)
		hideBar.Size = UDim2.fromOffset(12, 2)
		hideBar.ZIndex = 9
		hideBar.Parent = hideBtn
		corner(hideBar, 1)

		local pager = Instance.new("Frame")
		pager.Name = "Pager"
		pager.AnchorPoint = Vector2.new(1, 0.5)
		pager.BackgroundTransparency = 1
		pager.Position = UDim2.new(1, -30, 0.5, 0)
		pager.Size = UDim2.fromOffset(78, 22)
		pager.Visible = false
		pager.ZIndex = 6
		pager.Parent = header
		local pagerList = Instance.new("UIListLayout")
		pagerList.FillDirection = Enum.FillDirection.Horizontal
		pagerList.HorizontalAlignment = Enum.HorizontalAlignment.Right
		pagerList.Padding = UDim.new(0, 2)
		pagerList.SortOrder = Enum.SortOrder.LayoutOrder
		pagerList.VerticalAlignment = Enum.VerticalAlignment.Center
		pagerList.Parent = pager

		local function navBtn(name, glyph, order)
			local btn = Instance.new("TextButton")
			btn.Name = name
			btn.AutoButtonColor = false
			btn.BackgroundTransparency = 1
			btn.FontFace = FONT
			btn.LayoutOrder = order
			btn.Size = UDim2.fromOffset(20, 22)
			btn.Text = glyph
			btn.TextColor3 = MUTED
			btn.TextSize = 16
			btn.ZIndex = 7
			btn.Parent = pager
			return btn
		end

		local prevBtn = navBtn("Prev", "<", 1)
		local pageLab = label(pager, {
			Text = "1/1",
			Color = MUTED,
			Font = FONT_SEMI,
			Size = 11,
			H = 22,
			Align = Enum.TextXAlignment.Center,
			Auto = Enum.AutomaticSize.X,
			SizeDim = UDim2.fromOffset(28, 22),
		})
		pageLab.Name = "Page"
		pageLab.LayoutOrder = 2
		pageLab.ZIndex = 7
		local nextBtn = navBtn("Next", ">", 3)

		local headLine = Instance.new("Frame")
		headLine.Name = "HeadLine"
		headLine.BackgroundColor3 = LINE
		headLine.BackgroundTransparency = 0.05
		headLine.BorderSizePixel = 0
		headLine.Position = UDim2.new(0, 14, 1, -1)
		headLine.Size = UDim2.new(1, -28, 0, 1)
		headLine.ZIndex = 3
		headLine.Parent = header

		local body = Instance.new("Frame")
		body.Name = "Body"
		body.AutomaticSize = Enum.AutomaticSize.Y
		body.BackgroundTransparency = 1
		body.BorderSizePixel = 0
		body.Position = UDim2.fromOffset(0, HEADER_H)
		body.Size = UDim2.new(1, 0, 0, 0)
		body.ZIndex = 2
		body.Parent = card
		pad(body, 10, 14, 10, 14)

		local stack = Instance.new("UIListLayout")
		stack.FillDirection = Enum.FillDirection.Vertical
		stack.Padding = UDim.new(0, 8)
		stack.SortOrder = Enum.SortOrder.LayoutOrder
		stack.Parent = body

		local extraOrder = 50
		local function takeOrder(spec)
			local n = type(spec) == "table" and tonumber(spec.LayoutOrder)
			if n then
				return n
			end
			local o = extraOrder
			extraOrder += 1
			return o
		end

		local statsBox = Instance.new("Frame")
		statsBox.Name = "Stats"
		statsBox.AutomaticSize = Enum.AutomaticSize.Y
		statsBox.BackgroundTransparency = 1
		statsBox.LayoutOrder = 10
		statsBox.Size = UDim2.new(1, 0, 0, 0)
		statsBox.Parent = body
		local statsList = Instance.new("UIListLayout")
		statsList.Padding = UDim.new(0, 2)
		statsList.SortOrder = Enum.SortOrder.LayoutOrder
		statsList.Parent = statsBox

		local progressBox = Instance.new("Frame")
		progressBox.Name = "Progress"
		progressBox.AutomaticSize = Enum.AutomaticSize.Y
		progressBox.BackgroundTransparency = 1
		progressBox.LayoutOrder = 20
		progressBox.Size = UDim2.new(1, 0, 0, 0)
		progressBox.Visible = false
		progressBox.Parent = body
		local progressList = Instance.new("UIListLayout")
		progressList.Padding = UDim.new(0, 8)
		progressList.SortOrder = Enum.SortOrder.LayoutOrder
		progressList.Parent = progressBox

		local footer = Instance.new("Frame")
		footer.Name = "Footer"
		footer.BackgroundTransparency = 1
		footer.LayoutOrder = 90
		footer.Size = UDim2.new(1, 0, 0, 18)
		footer.Parent = body

		local statusLab = label(footer, {
			Text = "idle",
			Color = TEXT,
			Size = 12,
			H = 18,
			SizeDim = UDim2.new(1, 0, 1, 0),
		})
		statusLab.Name = "Status"

		local identity = Instance.new("Frame")
		identity.Name = "Identity"
		identity.BackgroundTransparency = 1
		identity.BorderSizePixel = 0
		identity.Position = UDim2.fromOffset(0, HEADER_H)
		identity.Size = UDim2.new(1, 0, 0, IDENTITY_H)
		identity.ZIndex = 2
		identity.Parent = card

		local identLine = Instance.new("Frame")
		identLine.Name = "IdentLine"
		identLine.BackgroundColor3 = LINE
		identLine.BackgroundTransparency = 0.05
		identLine.BorderSizePixel = 0
		identLine.Position = UDim2.fromOffset(14, 0)
		identLine.Size = UDim2.new(1, -28, 0, 1)
		identLine.Parent = identity

		local avatar = Instance.new("ImageLabel")
		avatar.Name = "Avatar"
		avatar.BackgroundColor3 = SECOND
		avatar.BorderSizePixel = 0
		avatar.Position = UDim2.fromOffset(14, 12)
		avatar.ScaleType = Enum.ScaleType.Crop
		avatar.Size = UDim2.fromOffset(36, 36)
		avatar.ZIndex = 4
		avatar.Parent = identity
		circle(avatar)

		local initial = label(avatar, {
			Text = "",
			Color = MUTED,
			Font = FONT_BOLD,
			Size = 13,
			H = 36,
			Align = Enum.TextXAlignment.Center,
			SizeDim = UDim2.fromScale(1, 1),
		})
		initial.Name = "Initial"

		local nameLab = label(identity, {
			Text = "Player",
			Color = TEXT,
			Font = FONT_BOLD,
			Size = 14,
			H = 18,
			SizeDim = UDim2.new(1, -120, 0, 18),
			Pos = UDim2.fromOffset(58, 14),
		})
		nameLab.Name = "PlayerName"

		local metaLab = label(identity, {
			Text = "",
			Color = MUTED,
			Size = 11,
			H = 14,
			SizeDim = UDim2.new(1, -120, 0, 14),
			Pos = UDim2.fromOffset(58, 34),
		})
		metaLab.Name = "Meta"

		local tag = Instance.new("TextLabel")
		tag.Name = "Tag"
		tag.AnchorPoint = Vector2.new(1, 0)
		tag.AutomaticSize = Enum.AutomaticSize.X
		tag.BackgroundColor3 = Color3.fromRGB(28, 28, 32)
		tag.BackgroundTransparency = 0
		tag.BorderSizePixel = 0
		tag.FontFace = FONT_BOLD
		tag.Position = UDim2.new(1, -14, 0, 16)
		tag.Size = UDim2.fromOffset(0, 18)
		tag.Text = ""
		tag.TextColor3 = MUTED
		tag.TextSize = 10
		tag.Visible = false
		tag.ZIndex = 4
		tag.Parent = identity
		pad(tag, 0, 8, 0, 8)
		corner(tag, 6)

		local shown = true
		local currentPage = 1
		local pageCount = 1
		local allUnits = {}
		local unitPages = {}
		local heightCache = {}
		local reflowBusy = false
		local reflowAgain = false
		local vpGen = 0

		local restore = Instance.new("TextButton")
		restore.Name = "Restore"
		restore.AutoButtonColor = false
		restore.AnchorPoint = Vector2.new(0.5, 0)
		restore.BackgroundColor3 = MAIN
		restore.BorderSizePixel = 0
		restore.FontFace = FONT_HEAVY
		restore.Position = UDim2.new(0.5, 0, 0, 14)
		restore.Size = UDim2.fromOffset(118, 32)
		restore.Text = "TEMPHUB"
		restore.TextColor3 = ACCENT
		restore.TextSize = 12
		restore.Visible = false
		restore.ZIndex = 20
		restore.Parent = gui
		corner(restore, 10)
		pad(restore, 0, 12, 0, 12)

		local function maxCardHeight()
			local h = gui.AbsoluteSize.Y
			if h < 1 then
				local cam = workspace.CurrentCamera
				h = (cam and cam.ViewportSize.Y) or 1080
			end
			local cap = tonumber(cfg.MaxHeight)
			if cap then
				return math.clamp(math.floor(cap), 200, math.max(220, h - 16))
			end
			return math.clamp(math.floor(h * 0.56), 260, math.max(260, h - 16))
		end

		local function maxPageableHeight()
			return math.max(72, maxCardHeight() - HEADER_H - IDENTITY_H - FOOTER_H - BODY_PAD_Y - STACK_PAD)
		end

		local function layoutKids(parent)
			local t = {}
			for _, ch in parent:GetChildren() do
				if ch:IsA("GuiObject") then
					table.insert(t, ch)
				end
			end
			table.sort(t, function(a, b)
				if a.LayoutOrder == b.LayoutOrder then
					return a.Name < b.Name
				end
				return a.LayoutOrder < b.LayoutOrder
			end)
			return t
		end

		local function collectUnits()
			local units = {}
			for _, ch in ipairs(layoutKids(body)) do
				if ch.Name ~= "Footer" then
					if ch.Name == "Stats" or ch.Name == "Progress" then
						for _, row in ipairs(layoutKids(ch)) do
							table.insert(units, { kind = "row", box = ch, node = row })
						end
					else
						table.insert(units, { kind = "block", node = ch })
					end
				end
			end
			return units
		end

		local function estimateHeight(unit)
			local node = unit.node
			local cached = heightCache[node]
			if type(cached) == "number" and cached > 0 then
				return cached
			end
			if node.Visible then
				local abs = node.AbsoluteSize.Y
				if abs > 0 then
					heightCache[node] = abs
					return abs
				end
			end
			if unit.kind == "row" then
				if unit.box and unit.box.Name == "Progress" then
					return 28
				end
				return 18
			end
			if string.sub(node.Name, 1, 6) == "THDiv_" then
				local title = node:FindFirstChild("Title")
				if title and title:IsA("TextLabel") and title.Text ~= "" then
					return 16
				end
				return 8
			end
			local n = 0
			for _, ch in node:GetChildren() do
				if ch:IsA("GuiObject") then
					n += 1
				end
			end
			return math.max(20, n * 16)
		end

		local function cacheVisibleHeights()
			allUnits = collectUnits()
			local live = {}
			for _, unit in ipairs(allUnits) do
				live[unit.node] = true
				if unit.node.Visible then
					local abs = unit.node.AbsoluteSize.Y
					if abs > 0 then
						heightCache[unit.node] = abs
					elseif heightCache[unit.node] == nil then
						heightCache[unit.node] = estimateHeight(unit)
					end
				elseif heightCache[unit.node] == nil then
					heightCache[unit.node] = estimateHeight(unit)
				end
			end
			for node in pairs(heightCache) do
				if not live[node] then
					heightCache[node] = nil
				end
			end
		end

		local function fitBoard()
			local bodyH = math.max(0, body.AbsoluteSize.Y)
			identity.Position = UDim2.fromOffset(0, HEADER_H + bodyH)
			card.Size = UDim2.fromOffset(width, HEADER_H + bodyH + IDENTITY_H)
			lockCenter()
		end

		local function hasVisibleChild(box)
			for _, ch in box:GetChildren() do
				if ch:IsA("GuiObject") and ch.Visible then
					return true
				end
			end
			return false
		end

		local function applyPage()
			if pageCount < 1 then
				pageCount = 1
			end
			currentPage = math.clamp(currentPage, 1, pageCount)
			local want = {}
			local page = unitPages[currentPage]
			if type(page) == "table" then
				for _, unit in ipairs(page) do
					want[unit.node] = true
				end
			end
			for _, unit in ipairs(allUnits) do
				unit.node.Visible = want[unit.node] == true
			end
			statsBox.Visible = hasVisibleChild(statsBox)
			progressBox.Visible = hasVisibleChild(progressBox)
			footer.Visible = true
			local many = pageCount > 1
			pager.Visible = many
			pageLab.Text = string.format("%d/%d", currentPage, math.max(pageCount, 1))
			brand.Size = UDim2.new(1, many and -118 or -60, 1, 0)
			fitBoard()
		end

		local function packPages()
			allUnits = collectUnits()
			local budget = maxPageableHeight()
			unitPages = { {} }
			local used = 0
			for _, unit in ipairs(allUnits) do
				local uh = estimateHeight(unit)
				local page = unitPages[#unitPages]
				local extra = (#page > 0) and STACK_PAD or 0
				if #page > 0 and used + extra + uh > budget then
					table.insert(unitPages, { unit })
					used = uh
				else
					table.insert(page, unit)
					used += extra + uh
				end
			end
			if #unitPages[1] == 0 and #allUnits == 0 then
				unitPages = { {} }
			end
			pageCount = math.max(1, #unitPages)
			if currentPage > pageCount then
				currentPage = pageCount
			end
			applyPage()
		end

		local function requestReflow()
			if reflowBusy then
				reflowAgain = true
				return
			end
			reflowBusy = true
			task.defer(function()
				if not card.Parent then
					reflowBusy = false
					return
				end
				cacheVisibleHeights()
				packPages()
				reflowBusy = false
				if reflowAgain then
					reflowAgain = false
					requestReflow()
				end
			end)
		end

		prevBtn.Activated:Connect(function()
			if pageCount <= 1 then
				return
			end
			currentPage = currentPage <= 1 and pageCount or (currentPage - 1)
			applyPage()
		end)
		nextBtn.Activated:Connect(function()
			if pageCount <= 1 then
				return
			end
			currentPage = currentPage >= pageCount and 1 or (currentPage + 1)
			applyPage()
		end)

		body:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitBoard)
		pcall(function()
			local function bindCam(cam)
				if not cam then
					return
				end
				cam:GetPropertyChangedSignal("ViewportSize"):Connect(function()
					vpGen += 1
					local gen = vpGen
					task.delay(0.12, function()
						if gen ~= vpGen or not card.Parent then
							return
						end
						packPages()
						lockCenter()
					end)
				end)
			end
			workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
				bindCam(workspace.CurrentCamera)
				lockCenter()
			end)
			bindCam(workspace.CurrentCamera)
		end)
		task.defer(requestReflow)

		local board = {
			Gui = gui,
			Root = card,
			Type = "HeadlessBoard",
		}

		function board:SetHeader(info)
			info = type(info) == "table" and info or { Name = tostring(info) }
			local name = asText(info.Name) ~= "" and asText(info.Name) or "Player"
			nameLab.Text = name
			local tagText = asText(info.Tag)
			tag.Text = tagText
			tag.Visible = tagText ~= ""
			local meta = asText(info.Meta)
			metaLab.Text = meta
			metaLab.Visible = meta ~= ""
			nameLab.Position = UDim2.fromOffset(58, meta ~= "" and 14 or 21)
			if asText(info.Title) ~= "" then
				brand.Text = string.upper(asText(info.Title))
			end
			local img = asText(info.Image)
			if img ~= "" then
				avatar.Image = img
				initial.Text = ""
				initial.Visible = false
			else
				avatar.Image = ""
				initial.Text = string.upper(string.sub(name, 1, 1))
				initial.Visible = true
			end
			return board
		end

		function board:SetStats(rows)
			for _, ch in statsBox:GetChildren() do
				if ch:IsA("GuiObject") then
					ch:Destroy()
				end
			end
			if type(rows) ~= "table" then
				return board
			end
			for i, row in ipairs(rows) do
				if type(row) == "table" then
					local node = makeRow(statsBox, row.Key or row[1], row.Value or row[2], row.Tone or row[3])
					node.LayoutOrder = i
				end
			end
			requestReflow()
			return board
		end

		function board:SetRow(key, value, tone)
			local want = asText(key)
			for _, ch in statsBox:GetChildren() do
				if ch:IsA("Frame") then
					local k = ch:FindFirstChild("Key")
					if k and k:IsA("TextLabel") and k.Text == want then
						local v = ch:FindFirstChild("Value")
						if v and v:IsA("TextLabel") then
							v.Text = asText(value)
							v.TextColor3 = toneColor(tone)
						end
						return board
					end
				end
			end
			makeRow(statsBox, key, value, tone)
			requestReflow()
			return board
		end

		local function progressRatio(spec)
			if type(spec.Progress) == "number" then
				return math.clamp(spec.Progress, 0, 1)
			end
			local value = tonumber(spec.Value)
			local max = tonumber(spec.Max)
			if value and max and max > 0 then
				return math.clamp(value / max, 0, 1)
			end
			if value then
				if value > 1 then
					return math.clamp(value / 100, 0, 1)
				end
				return math.clamp(value, 0, 1)
			end
			return 0
		end

		local function progressCaption(spec, ratio)
			local text = asText(spec.Text)
			if text ~= "" then
				return text
			end
			local value = tonumber(spec.Value)
			local max = tonumber(spec.Max)
			if value and max then
				return string.format("%s / %s", tostring(value), tostring(max))
			end
			return string.format("%d%%", math.floor(ratio * 100 + 0.5))
		end

		function board:RemoveProgress(id)
			id = asText(id)
			if id == "" then
				id = "Progress"
			end
			local node = progressBox:FindFirstChild(id)
			if node then
				node:Destroy()
			end
			requestReflow()
			return board
		end

		function board:SetProgress(id, spec)
			id = asText(id)
			if id == "" then
				id = "Progress"
			end
			if spec == nil or spec == false then
				return board:RemoveProgress(id)
			end
			if type(spec) ~= "table" then
				spec = { Progress = tonumber(spec) or 0 }
			end
			local ratio = progressRatio(spec)
			local tone = toneColor(spec.Tone or "Success")
			local node = progressBox:FindFirstChild(id)
			local created = false
			if not node then
				created = true
				node = Instance.new("Frame")
				node.Name = id
				node.AutomaticSize = Enum.AutomaticSize.Y
				node.BackgroundTransparency = 1
				node.Size = UDim2.new(1, 0, 0, 0)
				node.Parent = progressBox
				local head = Instance.new("Frame")
				head.Name = "Head"
				head.BackgroundTransparency = 1
				head.Size = UDim2.new(1, 0, 0, 16)
				head.Parent = node
				local title = label(head, {
					Text = "",
					Color = MUTED,
					Font = FONT_BOLD,
					Size = 10,
					H = 16,
					SizeDim = UDim2.new(0.55, 0, 1, 0),
				})
				title.Name = "Title"
				local caption = label(head, {
					Text = "",
					Color = TEXT,
					Font = FONT_SEMI,
					Size = 11,
					H = 16,
					Align = Enum.TextXAlignment.Right,
					SizeDim = UDim2.new(0.45, 0, 1, 0),
					Pos = UDim2.new(0.55, 0, 0, 0),
				})
				caption.Name = "Caption"
				local track = Instance.new("Frame")
				track.Name = "Track"
				track.BackgroundColor3 = Color3.fromRGB(28, 28, 32)
				track.BorderSizePixel = 0
				track.Position = UDim2.fromOffset(0, 20)
				track.Size = UDim2.new(1, 0, 0, 8)
				track.Parent = node
				corner(track, 4)
				local fill = Instance.new("Frame")
				fill.Name = "Fill"
				fill.BackgroundColor3 = ACCENT
				fill.BorderSizePixel = 0
				fill.Size = UDim2.new(0, 0, 1, 0)
				fill.Parent = track
				corner(fill, 4)
				node.Size = UDim2.new(1, 0, 0, 28)
			end
			local title = node.Head:FindFirstChild("Title")
			local caption = node.Head:FindFirstChild("Caption")
			local fill = node.Track:FindFirstChild("Fill")
			if title then
				title.Text = asText(spec.Title) ~= "" and asText(spec.Title) or id
			end
			if caption then
				caption.Text = progressCaption(spec, ratio)
			end
			if fill then
				fill.BackgroundColor3 = tone
				tween(fill, 0.18, { Size = UDim2.new(ratio, 0, 1, 0) }, Enum.EasingStyle.Quad)
			end
			if created then
				requestReflow()
			end
			return board
		end

		local function groupFrame(id, order)
			local existing = body:FindFirstChild(id)
			if existing then
				existing:Destroy()
			end
			local box = Instance.new("Frame")
			box.Name = id
			box.AutomaticSize = Enum.AutomaticSize.Y
			box.BackgroundTransparency = 1
			box.LayoutOrder = order
			box.Size = UDim2.new(1, 0, 0, 0)
			box.Parent = body
			local lay = Instance.new("UIListLayout")
			lay.Padding = UDim.new(0, 4)
			lay.SortOrder = Enum.SortOrder.LayoutOrder
			lay.Parent = box
			return box
		end

		local function headingText(spec, id)
			if type(spec) ~= "table" then
				return id
			end
			if spec.Title == nil then
				return id
			end
			return asText(spec.Title)
		end

		function board:SetDivider(id, spec)
			if type(spec) ~= "table" then
				spec = { Title = spec }
			end
			id = asText(id)
			if id == "" then
				id = "Divider"
			end
			local name = "THDiv_" .. id
			local existing = body:FindFirstChild(name)
			if existing then
				existing:Destroy()
			end
			local node = makeDivider(body, spec.Title)
			node.Name = name
			node.LayoutOrder = takeOrder(spec)
			requestReflow()
			return board
		end

		function board:RemoveDivider(id)
			local node = body:FindFirstChild("THDiv_" .. asText(id))
			if node then
				node:Destroy()
			end
			requestReflow()
			return board
		end

		function board:SetGroup(id, spec)
			spec = type(spec) == "table" and spec or {}
			id = asText(id)
			if id == "" then
				id = "Group"
			end
			local box = groupFrame(id, takeOrder(spec))
			local heading = headingText(spec, id)
			if heading ~= "" then
				sectionTitle(box, heading)
			end
			local cols = tonumber(spec.Columns) or 1
			local items = spec.Items or spec
			if type(items) ~= "table" then
				requestReflow()
				return board
			end
			if cols >= 2 then
				local grid = Instance.new("Frame")
				grid.AutomaticSize = Enum.AutomaticSize.Y
				grid.BackgroundTransparency = 1
				grid.Size = UDim2.new(1, 0, 0, 0)
				grid.LayoutOrder = 2
				grid.Parent = box
				local wrap = Instance.new("UIListLayout")
				wrap.FillDirection = Enum.FillDirection.Horizontal
				wrap.Padding = UDim.new(0, 8)
				wrap.SortOrder = Enum.SortOrder.LayoutOrder
				wrap.Wraps = true
				wrap.Parent = grid
				for i, item in ipairs(items) do
					if type(item) == "table" then
						local cell = makePairCell(grid, item.Key or item[1], item.Value or item[2], item.Tone or item[3])
						cell.LayoutOrder = i
						cell.Size = UDim2.new(0.5, -4, 0, 18)
					end
				end
			else
				for i, item in ipairs(items) do
					if type(item) == "table" then
						local node = makeRow(box, item.Key or item[1], item.Value or item[2], item.Tone or item[3])
						node.LayoutOrder = 10 + i
					end
				end
			end
			requestReflow()
			return board
		end

		function board:SetChips(id, spec)
			spec = type(spec) == "table" and spec or {}
			id = asText(id)
			if id == "" then
				id = "Chips"
			end
			local box = groupFrame(id, takeOrder(spec))
			local heading = headingText(spec, id)
			if heading ~= "" then
				sectionTitle(box, heading)
			end
			local row = Instance.new("Frame")
			row.AutomaticSize = Enum.AutomaticSize.Y
			row.BackgroundTransparency = 1
			row.LayoutOrder = 2
			row.Size = UDim2.new(1, 0, 0, 0)
			row.Parent = box
			local wrap = Instance.new("UIListLayout")
			wrap.FillDirection = Enum.FillDirection.Horizontal
			wrap.Padding = UDim.new(0, 6)
			wrap.SortOrder = Enum.SortOrder.LayoutOrder
			wrap.Wraps = true
			wrap.Parent = row
			local items = spec.Items or spec
			if type(items) ~= "table" then
				requestReflow()
				return board
			end
			for i, item in ipairs(items) do
				local text, tone
				if type(item) == "table" then
					text = asText(item.Text or item[1])
					tone = item.Tone or item[2]
				else
					text = asText(item)
				end
				if text ~= "" then
					local chip = Instance.new("TextLabel")
					chip.AutomaticSize = Enum.AutomaticSize.X
					chip.BackgroundColor3 = SECOND
					chip.BackgroundTransparency = 0
					chip.BorderSizePixel = 0
					chip.FontFace = FONT_SEMI
					chip.LayoutOrder = i
					chip.Size = UDim2.fromOffset(0, 20)
					chip.Text = text
					chip.TextColor3 = toneColor(tone)
					chip.TextSize = 12
					chip.Parent = row
					pad(chip, 0, 8, 0, 8)
					corner(chip, 8)
				end
			end
			requestReflow()
			return board
		end

		function board:RemoveGroup(id)
			id = asText(id)
			if id == "" or id == "Stats" or id == "Progress" or id == "Footer" or id == "Identity" then
				return board
			end
			local box = body:FindFirstChild(id)
			if box then
				box:Destroy()
			end
			requestReflow()
			return board
		end

		function board:SetStatus(text, tone)
			statusLab.Text = asText(text)
			statusLab.TextColor3 = toneColor(tone)
			return board
		end

		local function applyVisible(on)
			shown = on ~= false
			card.Visible = shown
			restore.Visible = not shown
			-- Keep ScreenGui enabled so the restore chip stays clickable while hidden.
			gui.Enabled = true
			return shown
		end

		function board:SetVisible(on)
			return applyVisible(on)
		end

		function board:IsVisible()
			return shown
		end

		function board:ToggleVisible()
			return applyVisible(not shown)
		end

		hideBtn.MouseButton1Click:Connect(function()
			applyVisible(false)
		end)
		restore.MouseButton1Click:Connect(function()
			applyVisible(true)
		end)
		hideBtn.MouseEnter:Connect(function()
			hideBar.BackgroundColor3 = ACCENT
		end)
		hideBtn.MouseLeave:Connect(function()
			hideBar.BackgroundColor3 = MUTED
		end)

		function board:SetPage(n)
			local page = math.floor(tonumber(n) or currentPage)
			currentPage = page
			applyPage()
			return currentPage, pageCount
		end

		function board:GetPage()
			return currentPage, pageCount
		end

		function board:Destroy()
			stopLock()
			if gui then
				gui:Destroy()
			end
		end

		if type(cfg.Name) == "string" or type(cfg.Tag) == "string" or type(cfg.Meta) == "string" then
			board:SetHeader(cfg)
		end

		genv._THHeadlessBoard = board
		return board
	end

	function lib.Destroy()
		wipeOld()
		genv._THHeadlessBoard = nil
	end

	return lib
end

local Headless = createLib()
genv.TempHubHeadless = Headless
genv._THHeadlessBuild = BUILD
return Headless
