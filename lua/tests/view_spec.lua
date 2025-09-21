---@diagnostic disable: need-check-nil

local assert = require "luassert"
local reload = require "plenary.reload"
local M = {
    module = require "runb.view"
}

local function setup()
    reload.reload_module("runb.view")
    M.module = require "runb.view"
end

local function assert_view_win_opened(source_buf)
    assert.is.True(vim.api.nvim_win_is_valid(M.module.state.win), "win is valid")
    assert.are.same(M.module.views[source_buf].view_buf, vim.api.nvim_win_get_buf(M.module.state.win), "win buf")
    local ns_id = vim.api.nvim_get_hl_id_by_name(M.module.hl_namespace)
    assert.are.same(vim.api.nvim_get_hl_ns({ winid = M.module.state.win }), ns_id, "highlight namespace")
    local view_buf = M.module.views[source_buf].view_buf
    assert.are.same(M.module.sources[view_buf], source_buf)
end

local function assert_view_win_hidden()
    assert.is.False(vim.api.nvim_win_is_valid(M.module.state.win))
end

---@param view ViewState
---@param tab string
---@param start_col integer
---@param end_col integer
local function assert_current_tab(view, tab, start_col, end_col)
    assert.are.same(tab, view.current_tab, "current tab")
    local ns_id = vim.api.nvim_get_hl_id_by_name(M.module.hl_namespace)
    local current_mark = vim.api.nvim_buf_get_extmark_by_id(view.view_buf, ns_id, M.module.state.current_tab_mark, { details = true })
    assert.are.same(0, current_mark[1], "start row")
    assert.are.same(start_col, current_mark[2], "start col")
    assert.are.same(0, current_mark[3].end_row, "end row")
    assert.are.same(end_col, current_mark[3].end_col, "end col")
    assert.are.same("current_tab", current_mark[3].hl_group, "hl_group")
end

---@param source_buf integer
---@param content string[]
---@param first_line integer
---@param last_line? integer
local function assert_content(source_buf, content, first_line, last_line)
    if last_line == nil then
        last_line = -1
    end
    local actual_content = vim.api.nvim_buf_get_lines(M.module.views[source_buf].view_buf, first_line,
        last_line, false)

    assert.are.same(content, actual_content)
end

---@param tab string
---@param content Result
---@return fun(result: Result, view_buf: integer, opts: ViewRenderingOptions)
local function get_render_if_tab(tab, content)
    return function(_, view_buf, opts) if tab == opts.tab then M.module.default.render(content, view_buf, opts) end end
end

describe("view.open_view", function()
    before_each(setup)

    it("should create view", function()
        local source_buf = vim.api.nvim_get_current_buf()

        M.module.open_view(source_buf)

        assert.is.Not.Nil(M.module.views[source_buf])
    end)

    it("should create view buffer", function()
        local source_buf = vim.api.nvim_get_current_buf()

        M.module.open_view(source_buf)
        local actual = M.module.views[source_buf].view_buf

        assert.is.True(vim.api.nvim_buf_is_valid(actual))
        assert.are.same(M.module.sources[actual], source_buf)
    end)

    it("should create view win", function()
        local source_buf = vim.api.nvim_get_current_buf()

        M.module.open_view(source_buf)

        assert_view_win_opened(source_buf)
    end)

    it("should use existing view buf", function()
        local source_buf = vim.api.nvim_get_current_buf()
        M.module.open_view(source_buf)
        local view_buf = M.module.views[source_buf].view_buf

        M.module.open_view(source_buf)

        assert.is.True(vim.api.nvim_win_is_valid(M.module.state.win))
        assert.is.True(vim.api.nvim_buf_is_valid(view_buf))
        assert.are.same(view_buf, vim.api.nvim_win_get_buf(M.module.state.win))
    end)
end)

describe("view.auto open/close view", function()
    local initial_buf = vim.api.nvim_get_current_buf()
    local buf_one = vim.api.nvim_create_buf(false, true)
    M.module.open_view(buf_one)
    local buf_two = vim.api.nvim_create_buf(false, true)
    M.module.open_view(buf_two)
    local buf_without_view = vim.api.nvim_create_buf(false, true)
    M.module.hide_view()

    ---@param ms integer
    local function async_wait(ms)
        local co = coroutine.running()
        vim.defer_fn(function()
            coroutine.resume(co)
        end, ms)
        coroutine.yield()
    end
    local wait_ms = 50

    ---@param source_buf integer
    ---@param open_view boolean
    local function set_current_buffer(source_buf, open_view)
        vim.api.nvim_set_current_buf(source_buf)
        if open_view then
            M.module.open_view(source_buf)
        else
            M.module.hide_view()
        end
        async_wait(wait_ms)
    end

    set_current_buffer(initial_buf, false)

    after_each(function()
        set_current_buffer(initial_buf, false)
    end)

    it("should open view when entering buffer with view", function()
        set_current_buffer(buf_without_view, false)

        vim.api.nvim_set_current_buf(buf_one)
        async_wait(wait_ms)

        assert_view_win_opened(buf_one)
    end)

    it("should change view when entering buffer with view", function()
        set_current_buffer(buf_one, true)

        vim.api.nvim_set_current_buf(buf_two)
        async_wait(wait_ms)

        assert_view_win_opened(buf_two)
    end)

    it("should close view when entering buffer without view", function()
        set_current_buffer(buf_one, true)

        vim.api.nvim_set_current_buf(buf_without_view)
        async_wait(wait_ms)

        assert_view_win_hidden()
    end)
end)

describe("view.hide_view", function()
    before_each(setup)

    it("should close win", function()
        local source_buf = vim.api.nvim_get_current_buf()
        M.module.open_view(source_buf)

        M.module.hide_view()

        assert_view_win_hidden()
    end)
end)

describe("view.toggle_view", function()
    before_each(setup)

    it("should open win", function()
        local source_buf = vim.api.nvim_get_current_buf()

        M.module.toggle_view()

        assert_view_win_opened(source_buf)
    end)
end)

describe("view.render", function()
    before_each(setup)
    local result = { "result" }

    for _, open_view in ipairs({ nil, true, false }) do
        it("should manage view win", function()
            local source_buf = vim.api.nvim_get_current_buf()

            M.module.render(result, { open_view = open_view })

            if open_view == false then
                assert.is.False(vim.api.nvim_win_is_valid(M.module.state.win))
            else
                assert_view_win_opened(source_buf)
            end
        end)

        it("should create view", function()
            local source_buf = vim.api.nvim_get_current_buf()

            M.module.render(result, { open_view = open_view })

            assert.is.Not.Nil(M.module.views[source_buf])
        end)

        it("should create view content", function()
            local source_buf = vim.api.nvim_get_current_buf()

            M.module.render(result, { open_view = open_view })

            assert.is.Not.Nil(M.module.views[source_buf].view)
        end)

        it("should use passed view content", function()
            local source_buf = vim.api.nvim_get_current_buf()
            local view_content = { render = function() end }

            M.module.render(result, { open_view = open_view, view = view_content })

            assert.are.same(view_content, M.module.views[source_buf].view)
        end)
    end

    local cases = {
        { tabs = { "one" },                 header_line = "| one |" },
        { tabs = { "one", "two" },          header_line = "| one | two |" },
        { tabs = { "one", "two", "three" }, header_line = "| one | two | three |" }
    }
    for i, case in pairs(cases) do
        it("should render header " .. tostring(i), function()
            local rendering = { tabs = case.tabs, render = function() end }
            local source_buf = vim.api.nvim_get_current_buf()

            M.module.render(result, { view = rendering })

            assert_current_tab(M.module.views[source_buf], "one", 1, #case.tabs[1] + 3)
            assert_content(source_buf, { case.header_line }, 0, 1)
        end)
    end

    cases = {
        { tabs = nil,                       tab = nil,     hl = {},         content = { "no content" },                                  content_first_line = 0, },
        { tabs = {},                        tab = nil,     hl = {},         content = { "no content" },                                  content_first_line = 0, },
        { tabs = { "one", "two", "three" }, tab = "one",   hl = { 1, 6 },   content = { "one content" },                                 content_first_line = 1, },
        { tabs = { "one", "two", "three" }, tab = "two",   hl = { 7, 12 },  content = { "one content", "two content" },                  content_first_line = 1, },
        { tabs = { "one", "two", "three" }, tab = "three", hl = { 13, 20 }, content = { "one content", "two content", "three content" }, content_first_line = 1, },
    }
    for i, case in pairs(cases) do
        it("should render content " .. tostring(i), function()
            local rendering = { tabs = case.tabs, render = get_render_if_tab(case.tab, case.content) }
            local source_buf = vim.api.nvim_get_current_buf()

            M.module.render(result, { view = rendering, tab = case.tab })

            if case.tabs ~= nil and #case.tabs > 0 then
                assert_current_tab(M.module.views[source_buf], case.tab, case.hl[1], case.hl[2])
            end
            assert_content(source_buf, case.content, case.content_first_line)
        end)
    end

    cases = {
        { content = { "one" },        append_content = { "two" },   full_content = { "Running...", "one", "two" } },
        { content = { "one", "two" }, append_content = { "three" }, full_content = { "Running...", "one", "two", "three" } },
    }
    for i, case in pairs(cases) do
        it("should append content " .. tostring(i), function()
            local source_buf = vim.api.nvim_get_current_buf()

            M.module.start({})
            M.module.append(case.content, {})
            M.module.append(case.append_content, {})

            assert_content(source_buf, case.full_content, 0)
        end)
    end

    cases = {
        { content = { "one" },                 cursor = { 1, 0 } },
        { content = { "one", "two" },          cursor = { 2, 0 } },
        { content = { "one", "two", "three" }, cursor = { 3, 0 } },
    }
    for i, case in pairs(cases) do
        it("should scroll to bottom " .. tostring(i), function()
            M.module.render(case.content, { scroll_to_end = true })

            local actual = vim.api.nvim_win_get_cursor(M.module.state.win)
            assert.are.same(case.cursor, actual)
        end)
    end
end)


describe("view.select_tab", function()
    before_each(setup)
    local result = { "result" }

    local cases = {
        { tabs = { "one", "two", "three" }, tab = "one",   hl = { 1, 6 },   content = { "one content" },                                 content_first_line = 1, },
        { tabs = { "one", "two", "three" }, tab = 1,       hl = { 1, 6 },   content = { "one content" },                                 content_first_line = 1, },
        { tabs = { "one", "two", "three" }, tab = "two",   hl = { 7, 12 },  content = { "one content", "two content" },                  content_first_line = 1, },
        { tabs = { "one", "two", "three" }, tab = 2,       hl = { 7, 12 },  content = { "one content", "two content" },                  content_first_line = 1, },
        { tabs = { "one", "two", "three" }, tab = "three", hl = { 13, 20 }, content = { "one content", "two content", "three content" }, content_first_line = 1, },
        { tabs = { "one", "two", "three" }, tab = 3,       hl = { 13, 20 }, content = { "one content", "two content", "three content" }, content_first_line = 1, },
    }
    for i, case in pairs(cases) do
        it("should render tab content " .. tostring(i), function()
            local tab_str = type(case.tab) == "number" and case.tabs[case.tab] or case.tab
            ---@cast tab_str string
            local rendering = { tabs = case.tabs, render = get_render_if_tab(tab_str, case.content) }
            local source_buf = vim.api.nvim_get_current_buf()
            M.module.render(result, { view = rendering })

            M.module.select_tab(case.tab)

            ---@cast tab_str string
            assert_current_tab(M.module.views[source_buf], tab_str, case.hl[1], case.hl[2])
            assert_content(source_buf, case.content, case.content_first_line)
        end)
    end
end)

describe("view.next_tab", function()
    before_each(setup)
    local result = { "result" }

    local cases = {
        { tabs = { "one", "two", "three" }, tab = "three", next_tab = "one",   hl = { 1, 6 },   content = { "one content" },                                 content_first_line = 1, },
        { tabs = { "one", "two", "three" }, tab = "one",   next_tab = "two",   hl = { 7, 12 },  content = { "one content", "two content" },                  content_first_line = 1, },
        { tabs = { "one", "two", "three" }, tab = "two",   next_tab = "three", hl = { 13, 20 }, content = { "one content", "two content", "three content" }, content_first_line = 1, },
    }
    for i, case in pairs(cases) do
        it("should render next tab content " .. tostring(i), function()
            local rendering = { tabs = case.tabs, render = get_render_if_tab(case.next_tab, case.content) }
            local source_buf = vim.api.nvim_get_current_buf()
            M.module.render(result, { view = rendering, tab = case.tab })

            M.module.next_tab()

            assert_current_tab(M.module.views[source_buf], case.next_tab, case.hl[1], case.hl[2])
            assert_content(source_buf, case.content, case.content_first_line)
        end)
    end
end)

describe("view.next_tab", function()
    before_each(setup)
    local result = { "result" }

    local cases = {
        { tabs = { "one", "two", "three" }, tab = "two",   next_tab = "one",   hl = { 1, 6 },   content = { "one content" },                                 content_first_line = 1, },
        { tabs = { "one", "two", "three" }, tab = "three", next_tab = "two",   hl = { 7, 12 },  content = { "one content", "two content" },                  content_first_line = 1, },
        { tabs = { "one", "two", "three" }, tab = "one",   next_tab = "three", hl = { 13, 20 }, content = { "one content", "two content", "three content" }, content_first_line = 1, },
    }
    for i, case in pairs(cases) do
        it("should render next tab content " .. tostring(i), function()
            local rendering = { tabs = case.tabs, render = get_render_if_tab(case.next_tab, case.content) }
            local source_buf = vim.api.nvim_get_current_buf()
            M.module.render(result, { view = rendering, tab = case.tab })

            M.module.previous_tab()


            assert_current_tab(M.module.views[source_buf], case.next_tab, case.hl[1], case.hl[2])
            assert_content(source_buf, case.content, case.content_first_line)
        end)
    end
end)
