local util = require "runb.util"

---@class NiewRenderOptions
---@field start_line? integer

local M = {
    ---@type {[integer]: Niew}
    views = {},
    ---@type {[integer]: integer}
    sources = {},
    ---@type {win: integer}
    state = {
        win = -1,
    }
}

---@param buf? integer
---@return integer
local function get_source_buf(buf)
    if buf == nil then
        buf = vim.api.nvim_get_current_buf()
    end
    if M.sources[buf] ~= nil then
        return M.sources[buf]
    end
    return buf
end

---@return Niew?
local function get_current_view()
    local source_buf = get_source_buf()
    return M.views[source_buf]
end

local function buf_enter_callback(opts)
    vim.schedule(function()
        M.open_view(opts.buf)
    end)
end

local function buf_leave_callback()
    return
        vim.schedule(function()
            if get_current_view() == nil then
                M.hide_view()
            end
        end)
end

---@class Niew
---@field source_buf integer
---@field view_buf integer
---@field filetype string
---@field open_autocmd_id integer?
---@field close_autocmd_id integer?
---@field render fun(self, result: Result?, opts: NiewRenderOptions?)
local DefaultView = {}
M.DefaultView = DefaultView;

---@param opt? {source_buf: integer?}
---@return Niew
DefaultView.new = function(_, opt)
    opt = opt or {}
    local ent = {
        source_buf = get_source_buf(opt.source_buf),
        view_buf = vim.api.nvim_create_buf(false, true)
    }
    M.views[ent.source_buf] = ent;
    M.sources[ent.view_buf] = ent.source_buf;
    ent = setmetatable(ent, { __index = DefaultView })
    ent:auto_open()

    return ent
end

local au_group = vim.api.nvim_create_augroup('runb_group', { clear = false })
---@param self Niew
DefaultView.auto_open = function(self)
    if self.open_autocmd_id == nil then
        self.open_autocmd_id = vim.api.nvim_create_autocmd("BufEnter", {
            group = au_group,
            buffer = self.source_buf,
            callback = buf_enter_callback
        })
        self.close_autocmd_id = vim.api.nvim_create_autocmd("BufLeave", {
            group = au_group,
            buffer = self.source_buf,
            callback = buf_leave_callback
        })
    end
end

---@param self Niew
---@param filetype string
DefaultView.set_type = function(self, filetype)
    vim.bo[self.view_buf].filetype = filetype
end

---@param self Niew
---@param result? Result
---@param opts? NiewRenderOptions
DefaultView.render = function(self, result, opts)
    opts = opts or {}

    local content = { "nil" };
    if result == nil then
        content = { "nil" }
    elseif type(result) == "string" then
        content = { result }
    elseif type(result[1]) == "string" then
        content = result
    elseif result.output ~= nil then
        content = result.output
    end

    local start_line = opts.start_line ~= nil and opts.start_line or 0;
    vim.api.nvim_buf_set_lines(self.view_buf, start_line, -1, false, content)
end

---@param self Niew
---@param result JobResult
---@param opts? NiewRenderOptions
DefaultView.render_start = function(self, result, opts)
    local content = { result.command }
    if result.args ~= nil then
        content[1] = content[1] .. " " .. table.concat(result.args, " ")
    end
    table.insert(content, "")
    table.insert(content, "Running...")
    self:render(content, opts)
end

---@param self Niew
---@param data string
---@param result JobResult
---@param opts? NiewRenderOptions
DefaultView.render_progress = function(self, data, result, opts)
    opts = opts or {
        start_line = -2
    }
    self:render({ data, "", "Running..." }, opts)
end

---@param self Niew
---@param result JobResult
---@param opts? NiewRenderOptions
DefaultView.render_result = function(self, result, opts)
    opts = opts or {}
    opts.start_line = opts.start_line == nil and 0 or opts.start_line
    self:render(result.output, opts)
end

---@param source_buf? integer
---@param create? boolean
---@return Niew
M.get_view = function(source_buf, create)
    source_buf = get_source_buf(source_buf)
    create = create == nil or create;
    local view = M.views[source_buf]
    if view == nil and create then
        view = M.DefaultView:new({ source_buf = source_buf });
    end
    return view
end

---@param source_buf? integer
---@param config? vim.api.keyset.win_config
---@return Niew
M.open_view = function(source_buf, config)
    config = config or { split = "right" }
    local view = M.get_view(source_buf)
    if vim.api.nvim_win_is_valid(M.state.win) then
        vim.api.nvim_win_set_buf(M.state.win, view.view_buf)
    else
        M.state.win = vim.api.nvim_open_win(view.view_buf, false, config)
    end
    return view
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
        M.open_view()
    end
end

---@param result JobResult
---@return string[]
M.get_cmd_output = function(result)
    local content = { result.command }
    if result.args ~= nil then
        table.insert(content, table.concat(result.args, " "))
    end
    table.insert(content, "")
    return content
end

---@param result JobResult
---@return string[]
M.get_full_output = function(result)
    local content = M.get_cmd_output(result)
    util.append(content, result.output)
    return content
end

---@param params? JobParams
---@return JobParams
M.with_render = function(params)
    params = params or {}
    M.open_view()
    local callback = function(result)
        M.get_view():render_result(result, { start_line = 0 })
        return result
    end
    local on_result = params.on_result
    if on_result ~= nil then
        callback = function(result)
            result = on_result(result) or result
            M.get_view():render_result(result, { start_line = 0 })
            return result
        end
    end
    params.on_result = callback
    return params
end

return M
