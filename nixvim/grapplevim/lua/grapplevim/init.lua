-- grapplevim: A gravity and grappling hook plugin for Neovim
-- Author: You! (and Gemini)
-- Date: June 25, 2025 (Anisotropic Physics and Symbol Grapple)

local M = {}

-- ====================================================================
-- 1. State and Configuration
-- ====================================================================

local State = {
	is_active = false,
	timer = nil,
	bufnr = 0,
	winid = 0,
	original_virtualedit = "",
	maps_set = {},
	pos = { x = 0.0, y = 0.0 },
	vel = { x = 0.0, y = 0.0 },
	grapple = { active = false, anchor = { x = 0, y = 0 }, rope_length = 0, extmark_id = nil },
	input = { j = false, k = false, h = false, l = false, timers = {} },
}

local Config = {
	step_rate = 33,
	key_release_timeout = 60,
	gravity = 0.02,
	grapple_tension = 0.03,
	grapple_friction = 0.98,
	j_force = 0.05,
	k_force = 0.05,
	hl_force = 0.05,
	-- NEW: Anisotropic distance weighting. Vertical distance counts for more.
	vertical_distance_weight = 2.0,
	anchor_sign_text = "⚓",
	anchor_sign_highlight = "WarningMsg",
	anchor_overlay_text = "⁜",
	anchor_overlay_highlight = "healthError",
	map_leader = "<Enter>",
	map_grapple = "<Space>",
	-- REMOVED: Treesitter nodes are no longer used.
}

-- ====================================================================
-- 2. Visuals and Physics
-- ====================================================================

local function hide_grapple_anchor()
	if State.grapple.extmark_id then
		pcall(vim.api.nvim_buf_del_extmark, State.bufnr, M.namespace_id, State.grapple.extmark_id)
		State.grapple.extmark_id = nil
	end
end
local function show_grapple_anchor()
	hide_grapple_anchor()
	if State.grapple.anchor then
		State.grapple.extmark_id = vim.api.nvim_buf_set_extmark(
			State.bufnr,
			M.namespace_id,
			State.grapple.anchor.y - 1,
			State.grapple.anchor.x - 1,
			{
				sign_text = Config.anchor_sign_text,
				sign_hl_group = Config.anchor_sign_highlight,
				virt_text = { { Config.anchor_overlay_text, Config.anchor_overlay_highlight } },
				virt_text_pos = "overlay",
			}
		)
	end
end

--- NEW: Anchor finding logic completely replaced. No longer uses Treesitter.
-- Grapples onto any non-alphabetic, non-whitespace character.
local function find_nearest_anchor()
	-- CHANGED: Use the visual floating-point position from State for accuracy.
	local cursor_row, cursor_col = State.pos.y, State.pos.x

	local best_pos = nil
	local min_dist_sq = math.huge
	local max_lines = vim.api.nvim_buf_line_count(State.bufnr)

	-- Scan a reasonable radius of lines around the cursor for efficiency
	local search_radius = 50
	local start_scan = math.max(1, math.floor(cursor_row) - search_radius)
	local end_scan = math.min(max_lines, math.floor(cursor_row) + search_radius)

	for r = start_scan, end_scan do
		local line_content = vim.api.nvim_buf_get_lines(State.bufnr, r - 1, r, false)[1] or ""
		-- Iterate through characters using a pattern that finds non-alpha, non-space chars
		for c, char in line_content:gmatch("()([^a-zA-Z%s])") do
			-- Calculate precise, weighted distance
			local dx = (c - 1) - cursor_col -- c is 1-based, cursor_col is 0-based
			local dy = (r - 1) - (cursor_row - 1)
			local dist_sq = (dx * dx) + ((dy * Config.vertical_distance_weight) ^ 2)

			if dist_sq > 0 and dist_sq < min_dist_sq then
				min_dist_sq = dist_sq
				best_pos = { y = r, x = c } -- Store 1-based position
			end
		end
	end
	return best_pos
end

local function process_movement_input()
	if State.input.j then
		State.vel.y = State.vel.y + Config.j_force
	end
	if State.input.k then
		State.vel.y = State.vel.y - Config.k_force
	end
	if State.input.l then
		State.vel.x = State.vel.x + Config.hl_force
	end
	if State.input.h then
		State.vel.x = State.vel.x - Config.hl_force
	end
end
local function apply_gravity()
	State.vel.y = State.vel.y + Config.gravity
end

-- CHANGED: Grapple physics now use weighted distance
local function apply_grapple_physics()
	local dx = (State.grapple.anchor.x - 1) - State.pos.x
	local dy = (State.grapple.anchor.y - 1) - (State.pos.y - 1)

	-- We check the weighted distance to see if the rope is taut
	local weighted_dist = math.sqrt((dx * dx) + ((dy * Config.vertical_distance_weight) ^ 2))

	if weighted_dist > State.grapple.rope_length then
		-- But we apply the force along the real, unweighted vector for correct direction
		local real_dist = math.sqrt(dx * dx + dy * dy)
		if real_dist > 0 then
			local tension_dx = dx / real_dist * (weighted_dist - State.grapple.rope_length)
			local tension_dy = dy / real_dist * (weighted_dist - State.grapple.rope_length)
			State.vel.x = State.vel.x + tension_dx * Config.grapple_tension
			State.vel.y = State.vel.y + tension_dy * Config.grapple_tension
		end
	end
	State.vel.x = State.vel.x * Config.grapple_friction
	State.vel.y = State.vel.y * Config.grapple_friction
end

local function update()
	if not State.is_active or not vim.api.nvim_win_is_valid(State.winid) then
		M.stop()
		return
	end
	process_movement_input()
	apply_gravity()
	if State.grapple.active then
		apply_grapple_physics()
	end
	State.pos.x = State.pos.x + State.vel.x
	State.pos.y = State.pos.y + State.vel.y
	local max_lines = vim.api.nvim_buf_line_count(State.bufnr)
	if State.pos.y > max_lines then
		State.pos.y = max_lines
		State.vel.y = 0
	end
	if State.pos.y < 1 then
		State.pos.y = 1
		State.vel.y = 0
	end
	local win_width = vim.api.nvim_win_get_width(State.winid)
	if State.pos.x > win_width - 1 then
		State.pos.x = win_width - 1
		State.vel.x = -State.vel.x * 0.5
	end
	if State.pos.x < 0 then
		State.pos.x = 0
		State.vel.x = -State.vel.x * 0.5
	end
	vim.api.nvim_win_set_cursor(State.winid, { math.floor(State.pos.y), math.floor(State.pos.x) })
end
local function handle_keyup(key)
	State.input[key] = false
	State.input.timers[key] = nil
end
local function handle_keydown(key)
	State.input[key] = true
	if State.input.timers[key] then
		vim.fn.timer_stop(State.input.timers[key])
	end
	State.input.timers[key] = vim.fn.timer_start(Config.key_release_timeout, function()
		handle_keyup(key)
	end)
end
local function toggle_grapple()
	if not State.is_active then
		return
	end
	if State.grapple.active then
		State.grapple.active = false
		hide_grapple_anchor()
	else
		local anchor_pos = find_nearest_anchor()
		if anchor_pos then
			State.grapple.active = true
			State.grapple.anchor = anchor_pos
			-- CHANGED: Calculate rope length with the new weighted distance
			local dx = (State.grapple.anchor.x - 1) - State.pos.x
			local dy = (State.grapple.anchor.y - 1) - (State.pos.y - 1)
			State.grapple.rope_length = math.sqrt((dx * dx) + ((dy * Config.vertical_distance_weight) ^ 2))
			show_grapple_anchor()
		end
	end
end
local function set_map(mode, key, rhs, desc)
	local map_opts = { buffer = State.bufnr, nowait = true, desc = "[Grapple] " .. desc }
	vim.keymap.set(mode, key, rhs, map_opts)
	table.insert(State.maps_set, { mode, key })
end
local function setup_gravity_maps()
	State.maps_set = {}
	set_map("n", Config.map_leader, M.stop, "Stop Gravity")
	set_map("n", "<Esc>", M.stop, "Stop Gravity")
	set_map("n", "j", function()
		handle_keydown("j")
	end, "Hold Down")
	set_map("n", "k", function()
		handle_keydown("k")
	end, "Hold Up")
	set_map("n", "h", function()
		handle_keydown("h")
	end, "Hold Left")
	set_map("n", "l", function()
		handle_keydown("l")
	end, "Hold Right")
	set_map("n", Config.map_grapple, toggle_grapple, "Toggle Grapple")
end
local function clear_gravity_maps()
	for _, map_info in ipairs(State.maps_set) do
		pcall(vim.keymap.del, map_info[1], map_info[2], { buffer = State.bufnr })
	end
	State.maps_set = {}
end
local function stop_input_timers()
	for key, timer_id in pairs(State.input.timers) do
		if timer_id then
			vim.fn.timer_stop(timer_id)
		end
		State.input[key] = false
	end
	State.input.timers = {}
end
function M.start()
	if State.is_active then
		return
	end
	State.is_active = true
	State.winid = vim.api.nvim_get_current_win()
	State.bufnr = vim.api.nvim_get_current_buf()
	State.original_virtualedit = vim.o.virtualedit
	vim.o.virtualedit = "all"
	local cursor_pos = vim.api.nvim_win_get_cursor(State.winid)
	State.pos = { y = cursor_pos[1], x = cursor_pos[2] }
	State.vel = { x = 0, y = 0 }
	State.grapple.active = false
	setup_gravity_maps()
	State.timer = vim.fn.timer_start(Config.step_rate, update, { ["repeat"] = -1 })
	vim.notify("Gravity ON", vim.log.levels.INFO)
	vim.wo[State.winid].cursorline = true
end
function M.stop()
	if not State.is_active then
		return
	end
	if State.timer then
		vim.fn.timer_stop(State.timer)
		State.timer = nil
	end
	stop_input_timers()
	vim.o.virtualedit = State.original_virtualedit
	vim.wo[State.winid].cursorline = false
	hide_grapple_anchor()
	clear_gravity_maps()
	local final_pos = vim.api.nvim_win_get_cursor(State.winid)
	vim.cmd.stopinsert()
	vim.fn.col(".")
	State.is_active = false
	vim.notify("Gravity OFF. Landed at " .. final_pos[1] .. ":" .. final_pos[2], vim.log.levels.INFO)
end

function M.setup(user_config)
	Config = vim.tbl_deep_extend("force", Config, user_config or {})
	M.namespace_id = vim.api.nvim_create_namespace("grapplevim")
	-- REMOVED: Treesitter lookup is no longer needed
	vim.keymap.set("n", Config.map_leader, M.start, { desc = "Start Grapplevim" })
end
return M
