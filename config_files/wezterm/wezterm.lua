-- For advanced split configuration silimar to neovim
-- refer to : https://github.com/tommynurwantoro/kidwezterm/tree/main
-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration.
local config = {}
-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
	config = wezterm.config_builder()
	config:set_strict_mode(true)
end
---local config = wezterm.config_builder()

-- Opacity
-- config.window_background_opacity = 1.0
-- This is where you actually apply your config choices
config.scrollback_lines = 5000
config.enable_scroll_bar = true
config.audible_bell = "Disabled"
config.initial_cols = 162
config.initial_rows = 45
-- Weight: `"Thin, ExtraLight,Light,DemiLight,Book,Regular,Medium,DemiBold,Bold,ExtraBold,Black,ExtraBlack"
-- stretch:
-- "UltraCondensed,ExtraCondensed, Condensed,SemiCondensed, Normal, SemiExpanded, Expanded,ExtraExpanded"`
--  UltraExpanded"`
--  style: Normal,Italic,Qbluque
-- config.font = '~/.fonts/v/VictorMonoNerdFontMono_Regular'
--config.font = wezterm.font("Fira Code", { weight = 450, stretch = "Normal", style = "Normal" }) -- weight : Regular, Bold, Thin, ExtraLight, Light, Medium, DemiBold
--config.font = wezterm.font("Fira Code", { weight = "Medium", stretch = "Normal" }) -- weight : Regular, Bold, Thin, ExtraLight, Light, Medium, DemiBold
-- config.font = wezterm.font("VictorMonoNerdFont", { weight = "Medium" }) -- weight : Regular, Bold, Thin, ExtraLight, Light, Medium, DemiBold
-- config.font = wezterm.font("VictorMonoNerdFont", { weight = "Regular", italic = true })
-- config.font = wezterm.font("VictorMono Nerd Font Propo", { weight = "Bold", italic = false, style = "oblique" })
---config.font = wezterm.font("VictorMono Nerd Font", { weight = "Medium", stretch = "Normal", style = "Normal" })
-- config.font = wezterm.font("VictorMono Nerd Font", { weight = 504, stretch = "Normal", style = "Normal" })
-- config.font = wezterm.font("VictorMonoNerdFont", { weight = "Medium", stretch = "Normal", style = "Normal" })
--config.font = wezterm.font("VictorMono Nerd Font", { weight = "Medium", stretch = "Normal", style = "Normal" })
-- config.font = wezterm.font("LiberationMono", { weight = "Regular" })
-- config.font = wezterm.font("UbuntuMono NFM", { weight = "Regular", stretch = "Normal", style = "Normal" })
--config.font = wezterm.font("JetBrains Mono", { weight = "DemiBold", stretch = "Normal", style = "Normal" })
config.font = wezterm.font("JetBrains Mono", { weight = 549, stretch = "Normal", style = "Normal" })
-- config.font = wezterm.font("JetBrains Mono", { weight = 450, stretch = "Normal", style = "Normal" })
-- config.font = wezterm.font("JetBrains Mono", { weight = 549, stretch = "SemiCondensed", style = "Normal" }) -- (AKA: JetBrains Mono Medium) <built-in>, BuiltIn
--config.font = wezterm.font("IBM Plex Mono", { weight = 450, stretch = "Normal", style = "Normal" })
--config.font = wezterm.font("FiraCode Nerd Font Mono", { weight = "Regular", stretch = "Normal", style = "Normal" })
-- config.font = wezterm.font("Fira Code", { weight = 450, stretch = "Normal", style = "Normal" })
--config.font = wezterm.font("FiraCode NF", { weight = "Regular", stretch = "Normal", style = "Normal" })
-- config.font = wezterm.font("Go Mono", { weight = "Regular", stretch = "Normal", style = "Normal" })
-- config.font = wezterm.font("Noto Sans Mono", { weight = "Regular", stretch = "Normal", style = "Normal" })
-- config.font = wezterm.font("Roboto Mono", { weight = "Regular", stretch = "Normal", style = "Normal" })
-- config.font = wezterm.font("VictorMono Nerd Font Propo", { weight = 549, stretch = "Normal", style = "Normal" })
-- config.font = wezterm.font("VictorMono Nerd Font Propo", { weight = "Medium", stretch = "Normal", style = "Normal" })
-- config.font = wezterm.font("VictorMono Nerd Font Mono", { weight = "Medium", stretch = "Normal", style = "Normal" })
-- config.font = wezterm.font("Source Code Pro", { weight = "Medium", stretch = "Normal", style = "Normal" })
-- config.font = wezterm.font("Noto Color Emoji", { weight = "Regular", stretch = "Normal", style = "Normal" })
-- config.font = wezterm.font("FuraMono Nerd Font", { weight = 450, stretch = "Normal", style = "Oblique" })
-- config.font = wezterm.font("FuraMono Nerd Font", { weight = 450, stretch = "Normal", style = "Normal" })
--config.font = wezterm.font("DaddyTimeMono Nerd Font", { weight = "Regular", stretch = "Condensed", style = "Normal" })
--config.font =wezterm.font("DaddyTimeMono Nerd Font Mono",{weight="Regular",stretch="Condensed",style="Normal"})
--config.font =wezterm.font("DaddyTimeMono Nerd Font Propo", { weight = "Regular", stretch = "Condensed", style = "Normal" })
--config.font=wezterm.font("ComicShannsMono Nerd Font Propo", { weight = "Regular", stretch = "Normal", style = "Normal" })
-- config.font = wezterm.font("SpaceMono Nerd Font", { weight = "Regular", stretch = "Normal", style = "Normal" })
-- config.font = wezterm.font("SpaceMono Nerd Font Mono", { weight = "Regular", stretch = "Condensed", style = "Normal" })
-- config.font = wezterm.font("CodeNewRoman Nerd Font", { weight = "Regular", stretch = "Normal", style = "Normal" })
-- config.font = wezterm.font("CodeNewRoman Nerd Font", { weight = 549, stretch = "Normal", style = "Normal" })
-- config.font = wezterm.font("DejaVu Sans Mono", { weight = "Book", stretch = "SemiCondensed", style = "Normal" })

config.font_size = 11.7
config.line_height = 1.0
config.use_fancy_tab_bar = true
-- config.use_fancy_tab_bar = false
font_shaper = "Harfbuzz" --- Harfbuzz, AllSorts
font_antialias = "Subpixel" --- `None`, `Greyscale`, `Subpixel`.
--config.freetype_load_target = "Light"
config.freetype_load_target = "Light"
config.freetype_load_flags = "NO_HINTING"
config.freetype_render_target = "HorizontalLcd"
front_end = "WebGpu" -- OpenGL , WebGpu, Software

--- Select Colur schemes for terminal:
-- For example, changing the color scheme:
-- config.color_scheme = "AdventureTime"
-- config.color_scheme = "Gruber (base16)"
-- config.color_scheme = "Gruvbox Dark (Gogh)"
----config.color_scheme = "Gruvbox dark, hard (base16)"
-- config.color_scheme = 'Gruvbox dark, soft (base16)'
-- config.color_scheme = "GruvboxDark"
config.color_scheme = "GruvboxDarkHard"
-- config.color_scheme = "Guezwhoz"
-- config.color_scheme = 'dayfox'
-- config.color_scheme = "Dotshare (terminal.sexy)"
-- config.color_scheme = "Kasugano (terminal.sexy)"
-- config.color_scheme = "Kanagawa Dragon (Gogh)"
-- config.color_scheme = "Kanagawa (Gogh)"
-- config.color_scheme = "Kanagawa Dragon (Gogh)"
-- config.color_scheme = "Kolorit"
-- config.color_scheme = "One Half Black (Gogh)"
-- config.color_scheme = "VisiBone (terminal.sexy)"
-- config.color_scheme = "Derp (terminal.sexy)"
-- config.color_scheme = "Bamboo Multiplex"
-- config.color_scheme = "Night Owl (Gogh)"
-- config.color_scheme = "Terminix Dark (Gogh)"
-- config.color_scheme = "thwump (terminal.sexy)"
-- config.color_scheme = "tokyonight_moon"
-- config.color_scheme = "Tomorrow Night Bright"
-- config.color_scheme = "zenburn (terminal.sexy)"
-- config.color_scheme = "matrix"
-- config.color_scheme = "Green Screen (base16)"
-- config.color_scheme = "Greenscreen (dark) (terminal.sexy)"
-- config.color_scheme = "Grey-green"
-- config.color_scheme = "Mona Lisa (Gogh)"

-- local key_tables = {
-- 	resize_font = {
-- 		{ key = "k", action = wezterm.action.IncreaseFontSize },
-- 		{ key = "j", action = wezterm.action.DecreaseFontSize },
-- 		{ key = "r", action = wezterm.action.ResetFontSize },
-- 		{ key = "Escape", action = "PopKeyTable" },
-- 		{ key = "q", action = "PopKeyTable" },
-- 	},
-- resize_pane = { ---
-- 	{ key = "K", action = wezterm.action.AdjustPaneSize({ "Up", 1 }) },
-- 	{ key = "J", action = wezterm.action.AdjustPaneSize({ "Down", 1 }) },
-- 	{ key = "H", action = wezterm.action.AdjustPaneSize({ "Left", 1 }) },
-- 	{ key = "L", action = wezterm.action.AdjustPaneSize({ "Right", 1 }) },
-- 	{ key = "Escape", action = "PopKeyTable" },
-- 	{ key = "q", action = "PopKeyTable" },
-- },
-- }
-- NOTE:Leader is the same as my old tmux prefix
---config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 1000 }
-- mapping the leader + b similar to tmux
---config.leader = { key = "b", mods = "CTRL", timeout_milliseconds = 1000 }
config.leader = { key = ",", mods = "CTRL", timeout_milliseconds = 1000 }
config.keys = {
	-- copy/paste --
	{ key = "c", mods = "CTRL|SHIFT", action = wezterm.action.CopyTo("Clipboard") },
	{ key = "v", mods = "CTRL|SHIFT", action = wezterm.action.PasteFrom("Clipboard") },
	-- splitting ( mapping keybind similar to Konsole )
	{
		-- mods = "LEADER",
		mods = "CTRL|SHIFT",
		key = ")",
		action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }),
	},
	{
		-- mods = "LEADER",
		mods = "CTRL|SHIFT",
		key = "(",
		action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }),
	},
	-- {
	-- 	mods = "LEADER",
	-- 	key = "m",
	-- 	action = wezterm.action.TogglePaneZoomState,
	-- },
	{
		--key = "UpArrow",
		key = "k",
		mods = "LEADER",
		action = wezterm.action.ActivatePaneDirection("Up"),
	},
	{
		--key = "DownArrow",
		key = "j",
		mods = "LEADER",
		action = wezterm.action.ActivatePaneDirection("Down"),
	},
	{
		--key = "LeftArrow",
		key = "h",
		mods = "LEADER",
		action = wezterm.action.ActivatePaneDirection("Left"),
	},
	{
		--key = "RightArrow",
		key = "l",
		mods = "LEADER",
		action = wezterm.action.ActivatePaneDirection("Right"),
	},
	-- resizes fonts
	{
		key = "f",
		mods = "LEADER",
		action = wezterm.action.ActivateKeyTable({
			name = "resize_font",
			one_shot = false,
			timemout_miliseconds = 1000,
		}),
	},
	{ key = "=", mods = "ALT|CTRL", action = wezterm.action.IncreaseFontSize },
	{ key = "-", mods = "ALT|CTRL", action = wezterm.action.DecreaseFontSize },
	{ key = "r", mods = "ALT|CTRL", action = wezterm.action.ResetFontSize },
	-- resize panes
	-- {
	-- 	key = "p",
	-- 	mods = "LEADER",
	-- 	action = wezterm.action.ActivateKeyTable({
	-- 		name = "resize_pane",
	-- 		one_shot = false,
	-- 		timemout_miliseconds = 1000,
	-- 	}),
	-- },
	{ key = "H", mods = "ALT|CTRL", action = wezterm.action.AdjustPaneSize({ "Left", 1 }) },
	{ key = "J", mods = "ALT|CTRL", action = wezterm.action.AdjustPaneSize({ "Down", 1 }) },
	{ key = "K", mods = "ALT|CTRL", action = wezterm.action.AdjustPaneSize({ "Up", 1 }) },
	{ key = "L", mods = "ALT|CTRL", action = wezterm.action.AdjustPaneSize({ "Right", 1 }) },
	-- {
	-- 	key = "H",
	-- 	--mode = "LEADER",
	-- 	mode = "CMD",
	-- 	action = wezterm.action.AdjustPaneSize({ "Left", 1 }),
	-- 	timemout_miliseconds = 1000,
	-- },
	-- {
	-- 	key = "J",
	-- 	-- mode = "LEADER",
	-- 	mode = "ALT",
	-- 	action = wezterm.action.AdjustPaneSize({ "Down", 1 }),
	-- 	timemout_miliseconds = 1000,
	-- },
	-- {
	-- 	key = "K",
	-- 	-- mode = "LEADER",
	-- 	mode = "ALT",
	-- 	action = wezterm.action.AdjustPaneSize({ "Up", 1 }),
	-- 	timemout_miliseconds = 1000,
	-- },
	-- {
	-- 	key = "L",
	-- 	-- mode = "LEADER",
	-- 	mode = "ALT",
	-- 	action = wezterm.action.AdjustPaneSize({ "Right", 1 }),
	-- 	timemout_miliseconds = 1000,
	-- },
	-- Close current tab:
	{ key = "w", mods = "CTRL|CMD", action = wezterm.action.CloseCurrentTab({ confirm = true }) },
	{ key = "Z", mods = "CTRL", action = wezterm.action.TogglePaneZoomState },
}
-- Tab bar styling on zoomed pane ( Indicator: Color the tab if Zoom is enabled on split window)
wezterm.on("format-tab-title", function(tab)
	local title = tab.active_pane.title
	local is_zoomed = tab.active_pane.is_zoomed
	local is_active_tab = tab.is_active
	--local act_title = string.format("** ▶ %d", tab_index) -- or "* %d", or "[%d]", or "**%d**"
	local act_title = is_active_tab and string.format("  ▶  ") or ""

	local zoomed_fg = "#ffffff"
	local zoomed_bg = "#d75f5f"
	local normal_fg = "#c0c0c0"
	local normal_bg = "#1d1d1d"

	local fg = is_zoomed and zoomed_fg or normal_fg
	local bg = is_zoomed and zoomed_bg or normal_bg
	--local prefix = is_zoomed and "🔍 " or ""
	local prefix = is_zoomed and "🔍 " or ""

	return {
		{ Background = { Color = bg } },
		{ Foreground = { Color = fg } },
		-- { Text = " " .. prefix .. title .. " " },
		-- { Text = string.format("Tab %d", tab.tab_index + 1) },
		--{ Text = string.format("✨ %d ❯❯ ", tab.tab_index + 1) },
		-- { Text = string.format("%d   %s", tab.tab_index + 1, prefix) },
		{ Text = string.format(" %s : %s : %d", prefix, act_title, tab.tab_index + 1) },
		-- { Text = string.format("⎇ %d: %s", tab.tab_index + 1, pane.title) },
	}
end)
--- Slit windows navigation

-- tab navigation change from CTRL+ALT+<number> to ALT+<number>
for i = 1, 9 do
	-- ALT + number to activate that tab
	table.insert(config.keys, {
		key = tostring(i),
		mods = "ALT",
		action = wezterm.action.ActivateTab(i - 1),
	})
	-- F1 through F8 to activage that tab
	-- table.insert(config.keys, {
	-- 	key = "F" .. tostring(1),
	-- 	action = wezterm.action.ActivateTab(i - 1),
	-- })
end
-- fancy tab bar
-- Display time @ right of tab bar
-- wezterm.on("update-right-status", function(window, pane)
-- 	local date = wezterm.strftime("[    %Y-%m-%d %H:%M:%S    ]")
--
-- 	-- Make it italic and underlined
-- 	window:set_right_status(wezterm.format({
-- 		{ Attribute = { Underline = "Single" } },
-- 		{ Attribute = { Italic = true } },
-- 		{ Text = "" .. date },
-- 	}))
-- end)
wezterm.on("update-right-status", function(window, pane)
	-- Each element holds the text for a cell in a "powerline" style << fade
	local cells = {}

	-- Figure out the cwd and host of the current pane.
	-- This will pick up the hostname for the remote host if your
	-- shell is using OSC 7 on the remote host.
	local cwd_uri = pane:get_current_working_dir()
	if cwd_uri then
		local cwd = ""
		local hostname = ""
		--local S_L_A = utf8.char(0xe0b2)

		if type(cwd_uri) == "userdata" then
			-- Running on a newer version of wezterm and we have
			-- a URL object here, making this simple!

			cwd = cwd_uri.file_path
			hostname = cwd_uri.host or wezterm.hostname()
		else
			-- an older version of wezterm, 20230712-072601-f4abf8fd or earlier,
			-- which doesn't have the Url object
			cwd_uri = cwd_uri:sub(8)
			local slash = cwd_uri:find("/")
			if slash then
				hostname = cwd_uri:sub(1, slash - 1)
				-- and extract the cwd from the uri, decoding %-encoding
				cwd = cwd_uri:sub(slash):gsub("%%(%x%x)", function(hex)
					return string.char(tonumber(hex, 16))
				end)
			end
		end

		-- Remove the domain name portion of the hostname
		local dot = hostname:find("[.]")
		if dot then
			hostname = hostname:sub(1, dot - 1)
		end
		if hostname == "" then
			hostname = wezterm.hostname()
		end

		--table.insert(cells, S_L_A)
		table.insert(cells, cwd)
		table.insert(cells, hostname)
	end

	-- I like my date/time in this style: "Wed Mar 3 08:14"
	local date = wezterm.strftime("%a %b %-d %H:%M ")
	table.insert(cells, date)

	-- An entry for each battery (typically 0 or 1 battery)
	-- for _, b in ipairs(wezterm.battery_info()) do
	-- 	table.insert(cells, string.format("%.0f%%", b.state_of_charge * 100))
	-- end

	-- The powerline < symbol
	----local LEFT_ARROW = utf8.char(0xe0b3)
	-- The filled in variant of the < symbol
	local SOLID_LEFT_ARROW = utf8.char(0xe0b2)

	-- Color palette for the backgrounds of each cell
	local colors = {
		"#666666",
		"#1d1d1d",
		"#5b5b5b",
		"#000000",
		"#b491c8",
	}

	-- Foreground color for the text across the fade
	local text_fg = "#c0c0c0"

	-- The elements to be formatted
	local elements = {}
	-- How many cells have been formatted
	local num_cells = 0

	-- Translate a cell into elements
	function push(text, is_last)
		local cell_no = num_cells + 1
		table.insert(elements, { Foreground = { Color = text_fg } })
		table.insert(elements, { Background = { Color = colors[cell_no] } })
		table.insert(elements, { Text = " " .. text .. " " })
		if not is_last then
			table.insert(elements, { Foreground = { Color = colors[cell_no + 1] } })
			table.insert(elements, { Text = SOLID_LEFT_ARROW })
		end
		num_cells = num_cells + 1
	end

	while #cells > 0 do
		local cell = table.remove(cells, 1)
		push(cell, #cells == 0)
	end

	window:set_right_status(wezterm.format(elements))
end)

-- and finally, return the configuration to wezterm
--
-- A connection to remote wezterm Multiplexer made via ssh connection is refered to as an SSH Domain.
-- config remote ssh domain
config.ssh_domains = {
	{
		-- Name identifier of the domain :
		name = "my.buildserver",
		-- hostname or address to connect to. will be used to match settings for our ssh configuration file
		remote_address = "172.21.177.105",
		username = "pulumati",
	},
}
-- tab bar possition at bottom:
config.window_decorations = "TITLE|RESIZE" -- "INTEGRATED_BUTTONS|RESIZE"
config.tab_bar_at_bottom = true
config.hide_tab_bar_if_only_one_tab = true

-- fix window size with change the font
config.adjust_window_size_when_changing_font_size = false

return config

-- My Notes: https://www.florianbellmann.com/blog/switch-from-tmux-to-wezterm#introduction
-- If switching from tmux to wezterm:
-- -
--   Tmux         WezTerm             Meaning
-------------------------------------------
--1  Pane        Pane                A Single shell. Also called Split sometimes
--2. Window      Tab                 A collection of shells in the same view ( like a tab )
--3. Session     Domain              Distinct set of windows as panes.
