local util = require "runb.util"

---@alias Result any

---@class ViewRenderingOptions
---@field tab? string
---@field start_line? integer

---@class View
---@field tabs? string[]
---@field start fun(result: Result?, view_buf: integer, opts: ViewRenderingOptions)
---@field append fun(data: string | string[], result: Result?, view_buf: integer, opts: ViewRenderingOptions)
---@field render fun(result: Result, view_buf: integer, opts: ViewRenderingOptions)

---@class ViewState
---@field source_buf integer
---@field view_buf integer
---@field result any
---@field current_tab? string
---@field view? View
---@field open_autocmd? integer
---@field close_autocmd? integer

---@class State
---@field win integer
---@field current_tab_mark integer

---@class RenderOptions
---@field source_buf? integer
---@field tab? string
---@field view? View
---@field open_view? boolean
---@field scroll_to_end? boolean
---@field append? boolean

local M = {
    hl_namespace = "runb_output",
    hl_groups = {
        current_tab = { bg = "#264f78", fg = "#FFFFFF", bold = true }
    },
    ---@type State
    state = {
        win = -1,
        current_tab_mark = -1,
    },
    ---@type {[integer]: ViewState}
    views = {},
    ---@type {[integer]: integer}
    sources = {}
}

-- Highlighting

local hl_id = vim.api.nvim_create_namespace(M.hl_namespace)
for name, value in pairs(M.hl_groups) do
    vim.api.nvim_set_hl(hl_id, name, value)
end

---@param view_state ViewState
local function higihlight_current_tab(view_state)
    local start_col = 1
    for _, t in ipairs(view_state.view.tabs) do
        if t == view_state.current_tab then break end
        start_col = start_col + #t + 3
    end
    local opts = {
        end_row = 0,
        end_col = start_col + #view_state.current_tab + 2,
        hl_group = "current_tab",
        hl_mode = "replace"
    }
    if M.state.current_tab_mark ~= -1 then
        opts.id = M.state.current_tab_mark
    end
    M.state.current_tab_mark = vim.api.nvim_buf_set_extmark(view_state.view_buf, hl_id, 0, start_col, opts)
end

-- View

---@type View?
M.default = {
    start = function(result, view_buf, opts)
        local text = "Running..."
        if result ~= nil then
            if result.command ~= nil then
                text = result.command
            end
            if result.args ~= nil then
                text = text .. " " .. table.concat(result.args, " ")
            end
        end
        vim.api.nvim_buf_set_lines(view_buf, opts.start_line, -1, false, { text })
    end,

    append = function(data, _, view_buf, opts)
        if data == nil then return end
        if type(data) == "string" then
            data = { data }
        end
        vim.api.nvim_buf_set_lines(view_buf, opts.start_line, -1, false, data)
    end,

    render = function(result, view_buf, opts)
        local content = nil
        if result == nil then
            content = { "nil" }
        elseif type(result) == "string" then
            content = { result }
        elseif type(result[1]) == "string" then
            content = result
        elseif result.output ~= nil then
            content = result.output
        end
        vim.api.nvim_buf_set_lines(view_buf, opts.start_line, -1, false, content or { "nil" })
    end
}

---@return ViewState
local function get_current_view()
    local current_buf = vim.api.nvim_get_current_buf()
    local view = M.views[current_buf]
    if view == nil then
        view = M.views[M.sources[current_buf]]
    end
    return view
end

local function buf_enter_callback(opts)
    vim.schedule(function()
        M.open_view(opts.buf)
    end)
end

local function buf_leave_callback()
    vim.schedule(function()
        if get_current_view() == nil then
            M.hide_view()
        end
    end)
end

local au_group = vim.api.nvim_create_augroup('runb_group', { clear = false })
---@param source_buf integer
local function auto_open_view(source_buf)
    local view = M.views[source_buf]
    if view.open_autocmd == nil then
        view.open_autocmd = vim.api.nvim_create_autocmd("BufEnter", {
            group = au_group,
            buffer = source_buf,
            callback = buf_enter_callback
        })
        view.close_autocmd = vim.api.nvim_create_autocmd("BufLeave", {
            group = au_group,
            buffer = source_buf,
            callback = buf_leave_callback
        })
    end
end

---@param source_buf integer
---@param view? View
---@param override_view? boolean
---@return ViewState
local function ensure_view_state(source_buf, view, override_view)
    local view_state = M.views[source_buf]
    if view_state == nil then
        view_state = {
            source_buf = source_buf,
            view_buf = -1,
            result = nil,
            current_tab = nil,
            view = view or M.default
        }
        M.views[source_buf] = view_state
        auto_open_view(source_buf)
    end

    if view ~= nil and (override_view or view_state.view == nil) then
        view_state.view = view
    end

    if not vim.api.nvim_buf_is_valid(view_state.view_buf) then
        if M.sources[view_state.view_buf] ~= nil then
            M.sources[view_state.view_buf] = nil
        end
        view_state.view_buf = vim.api.nvim_create_buf(false, true)
        M.sources[view_state.view_buf] = source_buf
    end

    return view_state
end

---@param source_buf integer
M.open_view = function(source_buf)
    local view = ensure_view_state(source_buf)
    if vim.api.nvim_win_is_valid(M.state.win) then
        vim.api.nvim_win_set_buf(M.state.win, view.view_buf)
    else
        M.state.win = vim.api.nvim_open_win(view.view_buf, false, { split = "right" })
        vim.api.nvim_win_set_hl_ns(M.state.win, hl_id)
    end
end

M.hide_view = function()
    if vim.api.nvim_win_is_valid(M.state.win) then
        vim.api.nvim_win_hide(M.state.win)
    end
end

M.toggle_view = function()
    if vim.api.nvim_win_is_valid(M.state.win) then
        M.hide_view()
    else
        M.open_view(vim.api.nvim_get_current_buf())
    end
end

-- Rendering

---@param opts? RenderOptions
---@return RenderOptions
local function ensure_opts(opts)
    opts = opts or {}
    opts.source_buf = opts.source_buf == nil and vim.api.nvim_get_current_buf() or opts.source_buf
    return opts
end

---@param view_state ViewState
---@param opts RenderOptions
---@return integer
local function render_tab_line(view_state, opts)
    local start_line = 0
    if view_state.view.tabs ~= nil and #view_state.view.tabs > 0 then
        local pos = 1
        local header_line = '|'
        for _, name in ipairs(view_state.view.tabs) do
            pos = pos + #name + 3
            header_line = header_line .. ' ' .. name .. ' |'
        end
        vim.api.nvim_buf_set_lines(view_state.view_buf, start_line, -1, false, { header_line })
        start_line = start_line + 1
        view_state.current_tab = opts.tab or view_state.view.tabs[1]
        higihlight_current_tab(view_state)
    end
    return start_line
end

---@param view_state ViewState
---@param opts RenderOptions
local function scroll_to_end(view_state, opts)
    if opts.scroll_to_end then
        local count = vim.api.nvim_buf_line_count(view_state.view_buf)
        vim.api.nvim_win_set_cursor(M.state.win, { count, 0 })
    end
end

---@param view View
---@param override_view? boolean
---@param source_buf? integer
M.use_view = function(view, override_view, source_buf)
    if source_buf == nil then
        source_buf = vim.api.nvim_get_current_buf()
    end
    ensure_view_state(source_buf, view, override_view)
end

---@param result? Result
---@param opts? RenderOptions
M.start = function(result, opts)
    opts = ensure_opts(opts)
    local view_state = ensure_view_state(opts.source_buf, opts.view)
    view_state.result = result

    if util.bool(opts.open_view) then
        M.open_view(opts.source_buf)
    end

    if view_state.view ~= nil then
        local start_line = render_tab_line(view_state, opts)
        view_state.view.start(result, view_state.view_buf, { tab = opts.tab, start_line = start_line })
        scroll_to_end(view_state, opts)
    end
end

---@param data string | string[]
---@param result Result?
---@param opts? RenderOptions
M.append = function(data, result, opts)
    opts = ensure_opts(opts)
    local view_state = ensure_view_state(opts.source_buf, opts.view)
    view_state.result = result

    if util.bool(opts.open_view) then
        M.open_view(opts.source_buf)
    end

    if view_state.view ~= nil then
        view_state.view.append(data, result, view_state.view_buf, { tab = opts.tab, start_line = -1 })
        scroll_to_end(view_state, opts)
    end
end

---@param result Result
---@param opts? RenderOptions
M.render = function(result, opts)
    opts = ensure_opts(opts)
    local view_state = ensure_view_state(opts.source_buf, opts.view)
    view_state.result = result

    if util.bool(opts.open_view) then
        M.open_view(opts.source_buf)
    end

    if view_state.view ~= nil then
        local start_line = render_tab_line(view_state, opts)
        view_state.view.render(result, view_state.view_buf, { tab = opts.tab, start_line = start_line })
        scroll_to_end(view_state, opts)
    end
end

-- Tabs

---@param view ViewState
local function can_switch_tab(view)
    return view ~= nil
        and view.result ~= nil
        and view.view ~= nil
        and view.view.tabs ~= nil
        and #view.view.tabs > 0
        and vim.api.nvim_buf_is_valid(view.view_buf)
end

---@param tab string | integer
M.select_tab = function(tab)
    local view = get_current_view()
    if not can_switch_tab(view) then
        return
    end
    if type(tab) == "number" then
        tab = view.view.tabs[tab]
    end
    ---@cast tab string
    M.render(view.result, { source_buf = view.source_buf, tab = tab })
end

M.next_tab = function()
    local view = get_current_view()
    if not can_switch_tab(view) then
        return
    end
    local tab_index = util.index(view.view.tabs, view.current_tab) + 1
    if tab_index > #view.view.tabs then
        tab_index = 1
    end
    M.render(view.result, { source_buf = view.source_buf, tab = view.view.tabs[tab_index] })
end

M.previous_tab = function()
    local view = get_current_view()
    if not can_switch_tab(view) then
        return
    end
    local tab_index = util.index(view.view.tabs, view.current_tab) - 1
    if tab_index < 1 then
        tab_index = #view.view.tabs
    end
    M.render(view.result, { source_buf = view.source_buf, tab = view.view.tabs[tab_index] })
end

return M
