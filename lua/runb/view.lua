local util = require "runb.util"

---@alias Result any

---@class ViewRenderingOptions
---@field tab? string
---@field start_line? integer

---@class ViewRendering
---@field tabs? string[]
---@field render fun(result: Result, view_buf: integer, opts: ViewRenderingOptions)

---@class View
---@field source_buf integer
---@field view_buf integer
---@field result any
---@field current_tab? string
---@field content? ViewRendering
---@field open_autocmd? integer
---@field close_autocmd? integer

---@class State
---@field win integer
---@field source_buf integer
---@field highlight_namespace integer
---@field current_tab_mark integer
---@field au_group integer

---@class RenderOptions
---@field source_buf? integer
---@field tab? string
---@field rendering? ViewRendering
---@field open_view? boolean
---@field scroll_to_end? boolean
---@field append? boolean

local highlight_namespace = vim.api.nvim_create_namespace('auto_header')
local highligh_groups = {
    current_tab = { bg = "#264f78", fg = "#FFFFFF", bold = true }
}
for name, value in pairs(highligh_groups) do
    vim.api.nvim_set_hl(highlight_namespace, name, value)
end

local au_group = vim.api.nvim_create_augroup('auto_group', { clear = false })

local M = {
    ---@type State
    state = {
        win = -1,
        source_buf = -1,
        highlight_namespace = highlight_namespace,
        current_tab_mark = -1,
        au_group = au_group
    },
    ---@type {[integer]: View}
    views = {},
    ---@type ViewRendering
    view_rendering = {
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
            vim.api.nvim_buf_set_lines(view_buf, opts.start_line, -1, false,
                content or { "Error. Result should be string or string[]. Result: " .. print(vim.inspect(result)) })
        end
    }
}

---@param  tabs string[]
---@return string
local function get_header_line(tabs)
    local start = 1
    local header_line = '|'
    for _, name in ipairs(tabs) do
        start = start + #name + 3
        header_line = header_line .. ' ' .. name .. ' |'
    end
    return header_line
end

---@param source_buf integer
---@return View
local function ensure_view(source_buf)
    local view = M.views[source_buf]
    if view == nil then
        view = {
            source_buf = source_buf,
            view_buf = -1,
            result = nil,
            current_tab = nil,
            content = nil
        }
        M.views[source_buf] = view
    end
    return view
end

---@param view View
---@return integer
local function ensure_view_buf(view)
    if not vim.api.nvim_buf_is_valid(view.view_buf) then
        view.view_buf = vim.api.nvim_create_buf(false, true)
        return view.view_buf
    end
    return view.view_buf
end

---@param win integer
---@param buf integer
---@return integer
local function ensure_win(win, buf)
    if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_set_buf(win, buf)
    else
        win = vim.api.nvim_open_win(buf, false, { split = "right" })
        vim.api.nvim_win_set_hl_ns(win, M.state.highlight_namespace)
    end
    return win
end

---@return integer?
local function get_current_view_buf()
    local current_view = M.views[M.state.source_buf]
    if current_view ~= nil then
        return current_view.view_buf
    end
    return nil
end

---@param source_buf integer
local function auto_open_view(source_buf)
    local view = M.views[source_buf]
    if view.open_autocmd == nil then
        view.open_autocmd = vim.api.nvim_create_autocmd("BufEnter", {
            group = M.state.au_group,
            buffer = source_buf,
            callback = function(opts)
                vim.schedule(function()
                    M.open_view(opts.buf)
                end)
            end
        })
        view.close_autocmd = vim.api.nvim_create_autocmd("BufLeave", {
            group = M.state.au_group,
            buffer = source_buf,
            callback = function()
                vim.schedule(function()
                    local current_buf = vim.api.nvim_get_current_buf()
                    if M.views[current_buf] == nil and get_current_view_buf() ~= current_buf then
                        M.hide_view()
                    end
                end)
            end
        })
    end
end

---@param source_buf integer
function M.open_view(source_buf)
    M.state.source_buf = source_buf
    local view = ensure_view(source_buf)
    ensure_view_buf(view)
    M.state.win = ensure_win(M.state.win, view.view_buf)
    auto_open_view(source_buf)
end

function M.hide_view()
    if vim.api.nvim_win_is_valid(M.state.win) then
        M.state.source_buf = nil
        vim.api.nvim_win_hide(M.state.win)
    end
end

function M.toggle_view()
    if vim.api.nvim_win_is_valid(M.state.win) then
        M.hide_view()
    else
        M.open_view(vim.api.nvim_get_current_buf())
    end
end

---@param view View
---@param content? ViewRendering
---@return ViewRendering
local function ensure_view_content(view, content)
    view.content = content or view.content
    if view.content == nil then
        view.content = M.view_rendering
    end
    return view.content
end

---@param tabs string[]
---@param tab string
---@param view_buf? integer
local function higihlight_tab(tabs, tab, view_buf)
    local start_col = 1
    for _, t in ipairs(tabs) do
        if t == tab then break end
        start_col = start_col + #t + 3
    end
    local opts = {
        end_row = 0,
        end_col = start_col + #tab + 2,
        hl_group = "current_tab",
        hl_mode = "replace"
    }
    if view_buf == nil then
        view_buf = M.views[M.state.source_buf].view_buf
    end
    if M.state.current_tab_mark ~= -1 then
        opts.id = M.state.current_tab_mark
    end
    M.state.current_tab_mark = vim.api.nvim_buf_set_extmark(view_buf, M.state.highlight_namespace, 0, start_col, opts)
end

---@param result Result
---@param opts? RenderOptions
function M.render(result, opts)
    opts = opts or {}
    opts.source_buf = opts.source_buf == nil and vim.api.nvim_get_current_buf() or opts.source_buf
    if opts.open_view or opts.open_view == nil then
        M.open_view(opts.source_buf)
    end
    local view = ensure_view(opts.source_buf)
    ensure_view_content(view, opts.rendering)
    view.result = result

    local start_line = -1
    if opts.append == nil or opts.append == false then
        start_line = 0
        if view.content.tabs ~= nil and #view.content.tabs > 0 then
            vim.api.nvim_buf_set_lines(view.view_buf, start_line, -1, false, { get_header_line(view.content.tabs) })
            start_line = start_line + 1
            view.current_tab = opts.tab or view.content.tabs[1]
            higihlight_tab(view.content.tabs, view.current_tab, view.view_buf)
        end
    end
    view.content.render(result, view.view_buf, { tab = opts.tab, start_line = start_line })
    if opts.scroll_to_end then
        local count = vim.api.nvim_buf_line_count(view.view_buf)
        vim.api.nvim_win_set_cursor(M.state.win, { count, 0 })
    end
end

---@param view View
local function can_switch_tab(view)
    return view ~= nil
        and view.result ~= nil
        and view.content ~= nil
        and view.content.tabs ~= nil
        and #view.content.tabs > 0
        and vim.api.nvim_buf_is_valid(view.view_buf)
end

---@param tab string | integer
function M.select_tab(tab)
    local view = M.views[M.state.source_buf]
    if not can_switch_tab(view) then
        return
    end
    if type(tab) == "number" then
        tab = view.content.tabs[tab]
    end
    ---@cast tab string
    M.render(view.result, { tab = tab })
end

function M.next_tab()
    local view = M.views[M.state.source_buf]
    if not can_switch_tab(view) then
        return
    end
    local tab_index = util.index(view.content.tabs, view.current_tab) + 1
    if tab_index > #view.content.tabs then
        tab_index = 1
    end
    M.render(view.result, { tab = view.content.tabs[tab_index] })
end

function M.previous_tab()
    local view = M.views[M.state.source_buf]
    if not can_switch_tab(view) then
        return
    end
    local tab_index = util.index(view.content.tabs, view.current_tab) - 1
    if tab_index < 1 then
        tab_index = #view.content.tabs
    end
    M.render(view.result, { tab = view.content.tabs[tab_index] })
end

return M
