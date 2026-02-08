local wezterm = require("wezterm")

return {
	-- Font
	font = wezterm.font("IosevkaTerm Nerd Font"),

	-- Disable the tab bar completely
	hide_tab_bar_if_only_one_tab = true,

	-- Cursor
	default_cursor_style = "SteadyBlock",

	-- Optional: cleaner look
	window_decorations = "RESIZE",
	adjust_window_size_when_changing_font_size = false,
	enable_csi_u_key_encoding = true,
}
