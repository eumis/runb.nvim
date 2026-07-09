---@diagnostic disable: need-check-nil

local assert = require "luassert"
local view = require "runb.view"

local function setup()
    local source_buf = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_win_set_buf(0, source_buf)
end

local function clear()
    if vim.api.nvim_win_is_valid(view.state.win) then
        vim.api.nvim_win_close(view.state.win, true)
    end
    view.state.win = -1
    for _, v in pairs(view.views) do
        if vim.api.nvim_buf_is_valid(v.view_buf) then
            vim.api.nvim_buf_delete(v.view_buf, { force = true })
        end
    end
    view.views = {}
    view.sources = {}
end

---@param source_buf integer
---@return View
local function assert_view_registered(source_buf)
    local v = view.views[source_buf]
    assert.is.Not.Nil(v)
    assert.are.same(source_buf, v.source_buf)
    assert.is.True(vim.api.nvim_buf_is_valid(v.view_buf))
    assert.are.same(source_buf, view.sources[v.view_buf])
    return v
end

---@param source_buf integer
local function assert_win_open(source_buf)
    assert.is.True(vim.api.nvim_win_is_valid(view.state.win), "win is valid")
    assert.are.same(view.views[source_buf].view_buf, vim.api.nvim_win_get_buf(view.state.win), "win buf")
end

local function assert_win_hidden()
    assert.is.False(vim.api.nvim_win_is_valid(view.state.win))
end

---@param source_buf integer
---@return string[]
local function content(source_buf)
    return vim.api.nvim_buf_get_lines(view.views[source_buf].view_buf, 0, -1, false)
end

describe("view.DefaultView:new", function()
    before_each(setup)
    after_each(clear)

    it("should register view state", function()
        local source_buf = vim.api.nvim_get_current_buf()

        view.DefaultView:new({ source_buf = source_buf })

        assert_view_registered(source_buf)
    end)

    it("should default auto_render to true", function()
        local v = view.DefaultView:new({})

        assert.is.True(v.auto_render)
    end)

    it("should disable auto_render when requested", function()
        local v = view.DefaultView:new({ auto_render = false })

        assert.is.False(v.auto_render)
    end)

    it("should not register auto open autocmds by default", function()
        local v = view.DefaultView:new({})

        assert.is.Nil(v.open_autocmd_id)
    end)

    it("should register auto open autocmds when auto_open is set", function()
        local v = view.DefaultView:new({ auto_open = true })

        assert.is.Not.Nil(v.open_autocmd_id)
        assert.is.Not.Nil(v.close_autocmd_id)
    end)
end)

describe("view.get_view", function()
    before_each(setup)
    after_each(clear)

    it("should create a default view", function()
        local source_buf = vim.api.nvim_get_current_buf()

        local v = view.get_view(source_buf)

        assert.are.same(v, view.views[source_buf])
        assert_view_registered(source_buf)
    end)

    it("should create the view with auto open", function()
        local source_buf = vim.api.nvim_get_current_buf()

        local v = view.get_view(source_buf)

        assert.is.Not.Nil(v.open_autocmd_id)
    end)

    it("should return the existing view", function()
        local source_buf = vim.api.nvim_get_current_buf()
        local existing = view.get_view(source_buf)

        local v = view.get_view(source_buf)

        assert.are.same(existing, v)
    end)

    it("should not create a view when create is false", function()
        local source_buf = vim.api.nvim_get_current_buf()

        local v = view.get_view(source_buf, false)

        assert.is.Nil(v)
    end)
end)

describe("view.open_view", function()
    before_each(setup)
    after_each(clear)

    it("should register view state", function()
        local source_buf = vim.api.nvim_get_current_buf()

        view.open_view(source_buf)

        assert_view_registered(source_buf)
    end)

    it("should open the window", function()
        local source_buf = vim.api.nvim_get_current_buf()

        view.open_view(source_buf)

        assert_win_open(source_buf)
    end)

    it("should reuse the window for the same view", function()
        local source_buf = vim.api.nvim_get_current_buf()
        view.open_view(source_buf)
        local win = view.state.win
        local view_buf = view.views[source_buf].view_buf

        view.open_view(source_buf)

        assert.are.same(win, view.state.win)
        assert.are.same(view_buf, vim.api.nvim_win_get_buf(view.state.win))
    end)

    it("should switch the window buffer for another view", function()
        local first = vim.api.nvim_get_current_buf()
        view.open_view(first)
        local win = view.state.win
        local second = vim.api.nvim_create_buf(false, true)

        view.open_view(second)

        assert.are.same(win, view.state.win)
        assert.are.same(view.views[second].view_buf, vim.api.nvim_win_get_buf(view.state.win))
    end)
end)

describe("view.hide_view", function()
    before_each(setup)
    after_each(clear)

    it("should hide the window", function()
        local source_buf = vim.api.nvim_get_current_buf()
        view.open_view(source_buf)

        view.hide_view()

        assert_win_hidden()
    end)
end)

describe("view.toggle_view", function()
    before_each(setup)
    after_each(clear)

    it("should open the window", function()
        local source_buf = vim.api.nvim_get_current_buf()

        view.toggle_view()

        assert_win_open(source_buf)
    end)

    it("should hide the window", function()
        local source_buf = vim.api.nvim_get_current_buf()
        view.open_view(source_buf)

        view.toggle_view()

        assert_win_hidden()
    end)
end)

describe("view.DefaultView:render", function()
    before_each(setup)
    after_each(clear)

    local cases = {
        { name = "nil result",    result = nil,                      expected = { "nil" } },
        { name = "string result", result = "single line",            expected = { "single line" } },
        { name = "string list",   result = { "line 1", "line 2" },   expected = { "line 1", "line 2" } },
        { name = "job result",    result = { output = { "a", "b" } }, expected = { "a", "b" } },
    }
    for _, case in pairs(cases) do
        it("should render " .. case.name, function()
            local source_buf = vim.api.nvim_get_current_buf()
            local v = view.open_view(source_buf)

            v:render(case.result)

            assert.are.same(case.expected, content(source_buf))
        end)
    end

    it("should render at the given line range", function()
        local source_buf = vim.api.nvim_get_current_buf()
        local v = view.open_view(source_buf)
        v:render({ "one", "two", "three" })

        v:render({ "REPLACED" }, { start_line = 1, end_line = 2 })

        assert.are.same({ "one", "REPLACED", "three" }, content(source_buf))
    end)
end)

describe("view.DefaultView:set_type", function()
    before_each(setup)
    after_each(clear)

    it("should set the view buffer filetype", function()
        local source_buf = vim.api.nvim_get_current_buf()
        local v = view.open_view(source_buf)

        v:set_type("json")

        assert.are.same("json", vim.bo[v.view_buf].filetype)
    end)
end)

describe("view.get_cmd_output", function()
    local cases = {
        { result = { command = "ls" },                           expected = { "ls", "" } },
        { result = { command = "ls", args = { "-l" } },          expected = { "ls", "-l", "" } },
        { result = { command = "curl", args = { "-X", "GET" } }, expected = { "curl", "-X GET", "" } },
    }
    for i, case in pairs(cases) do
        it("should build the command output " .. i, function()
            assert.are.same(case.expected, view.get_cmd_output(case.result))
        end)
    end
end)

describe("view.get_full_output", function()
    it("should append the output to the command", function()
        local result = { command = "ls", args = { "-l" }, output = { "file1", "file2" } }

        local actual = view.get_full_output(result)

        assert.are.same({ "ls", "-l", "", "file1", "file2" }, actual)
    end)
end)

describe("view.with_auto_render", function()
    before_each(setup)
    after_each(clear)

    it("should open the window and set on_result", function()
        local source_buf = vim.api.nvim_get_current_buf()

        local params = view.with_auto_render({})

        assert_win_open(source_buf)
        assert.are.same("function", type(params.on_result))
    end)

    it("should render the result through on_result", function()
        local source_buf = vim.api.nvim_get_current_buf()
        local params = view.with_auto_render({})

        params.on_result({ "rendered line" })

        assert.are.same({ "rendered line" }, content(source_buf))
    end)

    it("should return the result from on_result", function()
        local params = view.with_auto_render({})
        local result = { "line" }

        local actual = params.on_result(result)

        assert.are.same(result, actual)
    end)

    it("should wrap an existing on_result", function()
        local source_buf = vim.api.nvim_get_current_buf()
        local received
        local original = function(result)
            received = result
            return result
        end

        local params = view.with_auto_render({ on_result = original })
        params.on_result({ "line" })

        assert.are.same({ "line" }, received)
        assert.are.same({ "line" }, content(source_buf))
    end)

    it("should not touch params when auto_render is disabled", function()
        local source_buf = vim.api.nvim_get_current_buf()
        view.DefaultView:new({ source_buf = source_buf, auto_render = false })

        local params = view.with_auto_render({ on_result = "sentinel" })

        assert_win_hidden()
        assert.are.same("sentinel", params.on_result)
    end)
end)

describe("view.auto open/close", function()
    before_each(setup)
    after_each(clear)

    ---@param ms integer
    local function async_wait(ms)
        local co = coroutine.running()
        vim.defer_fn(function()
            coroutine.resume(co)
        end, ms)
        coroutine.yield()
    end
    local wait_ms = 50

    it("should open the view when entering a buffer with a view", function()
        local buf_with_view = vim.api.nvim_get_current_buf()
        view.open_view(buf_with_view)
        local buf_without_view = vim.api.nvim_create_buf(true, false)

        vim.api.nvim_set_current_buf(buf_without_view)
        async_wait(wait_ms)
        vim.api.nvim_set_current_buf(buf_with_view)
        async_wait(wait_ms)

        assert_win_open(buf_with_view)
    end)

    it("should switch the view when entering another buffer with a view", function()
        local buf_one = vim.api.nvim_get_current_buf()
        view.open_view(buf_one)
        local buf_two = vim.api.nvim_create_buf(true, false)
        vim.api.nvim_set_current_buf(buf_two)
        view.open_view(buf_two)
        async_wait(wait_ms)

        vim.api.nvim_set_current_buf(buf_one)
        async_wait(wait_ms)

        assert_win_open(buf_one)
    end)

    it("should hide the view when entering a buffer without a view", function()
        local buf_with_view = vim.api.nvim_get_current_buf()
        view.open_view(buf_with_view)
        local buf_without_view = vim.api.nvim_create_buf(true, false)

        vim.api.nvim_set_current_buf(buf_without_view)
        async_wait(wait_ms)

        assert_win_hidden()
    end)
end)
