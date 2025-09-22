---@diagnostic disable: need-check-nil

local assert = require "luassert"
local view = require "runb.view"
local stub = require "luassert.stub"

local function setup()
    local source_buf = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_win_set_buf(0, source_buf)
end

local function clear()
    if vim.api.nvim_win_is_valid(view.state.win) then
        vim.api.nvim_win_close(view.state.win, true)
    end
    view.state.win = -1
    for _, view_state in pairs(view.views) do
        if vim.api.nvim_buf_is_valid(view_state.view_buf) then
            vim.api.nvim_buf_delete(view_state.view_buf, { force = true })
        end
    end
    view.views = {}
    view.sources = {}
end

---@param source_buf integer
---@param view_ View
---@param result? any
local function assert_view_state(source_buf, view_, result)
    local view_state = view.views[source_buf]
    assert.is.Not.Nil(view_state)
    assert.is.True(vim.api.nvim_buf_is_valid(view_state.view_buf))
    assert.are.same(result, view_state.result)
    assert.is.Nil(view_state.current_tab)
    assert.are.same(view_, view_state.view)
    assert.are.same(source_buf, view.sources[view_state.view_buf])
end

local function assert_view_win_opened(source_buf)
    assert.is.True(vim.api.nvim_win_is_valid(view.state.win), "win is valid")
    assert.are.same(view.views[source_buf].view_buf, vim.api.nvim_win_get_buf(view.state.win), "win buf")
    local ns_id = vim.api.nvim_get_namespaces()[view.hl_namespace]
    assert.are.same(vim.api.nvim_get_hl_ns({ winid = view.state.win }), ns_id, "highlight namespace")
    local view_buf = view.views[source_buf].view_buf
    assert.are.same(view.sources[view_buf], source_buf)
end

local function assert_view_win_hidden()
    assert.is.False(vim.api.nvim_win_is_valid(view.state.win))
end

---@param view_state ViewState
---@param tab string
---@param start_col integer
---@param end_col integer
local function assert_current_tab(view_state, tab, start_col, end_col)
    assert.are.same(tab, view_state.current_tab, "current tab")
    local ns_id = vim.api.nvim_get_namespaces()[view.hl_namespace]
    local current_mark = vim.api.nvim_buf_get_extmark_by_id(view_state.view_buf, ns_id, view.state.current_tab_mark,
        { details = true })
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
    local actual_content = vim.api.nvim_buf_get_lines(view.views[source_buf].view_buf, first_line,
        last_line, false)

    assert.are.same(content, actual_content)
end

---@param tab string
---@param content Result
---@return fun(result: Result, view_buf: integer, opts: ViewRenderingOptions)
local function get_render_if_tab(tab, content)
    return function(_, view_buf, opts) if tab == opts.tab then view.default.render(content, view_buf, opts) end end
end

describe("view.open_view", function()
    before_each(setup)
    after_each(clear)

    it("should create view state", function()
        local source_buf = vim.api.nvim_get_current_buf()

        view.open_view(source_buf)

        assert_view_state(source_buf, view.default)
    end)

    it("should create view win", function()
        local source_buf = vim.api.nvim_get_current_buf()

        view.open_view(source_buf)

        assert_view_win_opened(source_buf)
    end)

    it("should use existing view state", function()
        local source_buf = vim.api.nvim_get_current_buf()
        view.open_view(source_buf)
        local view_buf = view.views[source_buf].view_buf

        view.open_view(source_buf)

        assert.is.True(vim.api.nvim_win_is_valid(view.state.win))
        assert.is.True(vim.api.nvim_buf_is_valid(view_buf))
        assert.are.same(view_buf, vim.api.nvim_win_get_buf(view.state.win))
        assert.are.same(view.sources[view_buf], source_buf)
    end)
end)

describe("view.hide_view", function()
    before_each(setup)
    after_each(clear)

    it("should close win", function()
        local source_buf = vim.api.nvim_get_current_buf()
        view.open_view(source_buf)

        view.hide_view()

        assert_view_win_hidden()
    end)
end)

describe("view.toggle_view", function()
    before_each(setup)
    after_each(clear)

    it("should open win", function()
        local source_buf = vim.api.nvim_get_current_buf()

        view.toggle_view()

        assert_view_state(source_buf, view.default)
        assert_view_win_opened(source_buf)
    end)

    it("should close win", function()
        local source_buf = vim.api.nvim_get_current_buf()
        view.open_view(source_buf)

        view.toggle_view()

        assert_view_win_hidden()
    end)
end)

describe("view.auto open/close view", function()
    before_each(setup)
    after_each(clear)

    local initial_buf = vim.api.nvim_get_current_buf()
    local buf_one = vim.api.nvim_create_buf(false, true)
    view.open_view(buf_one)
    local buf_two = vim.api.nvim_create_buf(false, true)
    view.open_view(buf_two)
    local buf_without_view = vim.api.nvim_create_buf(false, true)
    view.hide_view()

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
            view.open_view(source_buf)
        else
            view.hide_view()
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

describe("view.use_view", function()
    before_each(setup)
    after_each(clear)

    it("should create view state", function()
        local source_buf = vim.api.nvim_get_current_buf()
        local view_ = { start = stub.new(), append = stub.new(), render = stub.new() }

        view.use_view(view_)

        assert_view_state(source_buf, view_)
    end)

    it("should not override existing view", function()
        local source_buf = vim.api.nvim_get_current_buf()
        local view_ = { start = stub.new(), append = stub.new(), render = stub.new() }
        view.open_view(source_buf)

        view.use_view(view_)

        assert_view_state(source_buf, view.default)
    end)

    it("should override existing view", function()
        local source_buf = vim.api.nvim_get_current_buf()
        local view_ = { start = stub.new(), append = stub.new(), render = stub.new() }
        view.open_view(source_buf)

        view.use_view(view_, true, source_buf)

        assert_view_state(source_buf, view_)
    end)
end)

describe("view.start", function()
    before_each(setup)
    after_each(clear)
    local result = { "result" }

    it("should create view state", function()
        local source_buf = vim.api.nvim_get_current_buf()

        view.start(result)

        assert_view_state(source_buf, view.default, result)
    end)

    it("should use passed view", function()
        local source_buf = vim.api.nvim_get_current_buf()
        local view_ = { start = function() end }

        view.start(result, { view = view_ })

        assert_view_state(source_buf, view_, result)
    end)

    for i, open_view in pairs({ nil, true, false }) do
        it("should open win " .. tostring(i), function()
            local source_buf = vim.api.nvim_get_current_buf()

            view.start(result, { open_view = open_view })

            if open_view == false then
                assert.is.False(vim.api.nvim_win_is_valid(view.state.win))
            else
                assert_view_win_opened(source_buf)
            end
        end)
    end

    local cases = {
        { tabs = { "one" },                 header_line = "| one |" },
        { tabs = { "one", "two" },          header_line = "| one | two |" },
        { tabs = { "one", "two", "three" }, header_line = "| one | two | three |" }
    }
    for i, case in pairs(cases) do
        it("should render header " .. tostring(i), function()
            local view_ = { tabs = case.tabs, start = function() end }
            local source_buf = vim.api.nvim_get_current_buf()

            view.start(result, { view = view_ })

            assert_current_tab(view.views[source_buf], "one", 1, #case.tabs[1] + 3)
            assert_content(source_buf, { case.header_line }, 0, 1)
        end)
    end

    cases = {
        { tabs = nil,                       tab = nil,     hl = {},         result = nil,                                 content = { "Running..." }, content_first_line = 0, },
        { tabs = nil,                       tab = nil,     hl = {},         result = { command = "ls" },                  content = { "ls" },         content_first_line = 0, },
        { tabs = {},                        tab = nil,     hl = {},         result = { command = "ls", args = { "-l" } }, content = { "ls -l" },      content_first_line = 0, },
        { tabs = { "one", "two", "three" }, tab = "one",   hl = { 1, 6 },   result = {},                                  content = { "Running..." }, content_first_line = 1, },
        { tabs = { "one", "two", "three" }, tab = "two",   hl = { 7, 12 },  result = { command = "ls" },                  content = { "ls" },         content_first_line = 1, },
        { tabs = { "one", "two", "three" }, tab = "three", hl = { 13, 20 }, result = { command = "ls", args = { "-l" } }, content = { "ls -l" },      content_first_line = 1, },
    }
    for i, case in pairs(cases) do
        it("should render command " .. tostring(i), function()
            local view_ = { tabs = case.tabs, start = view.default.start }
            local source_buf = vim.api.nvim_get_current_buf()

            view.start(case.result, { view = view_, tab = case.tab })

            if case.tabs ~= nil and #case.tabs > 0 then
                assert_current_tab(view.views[source_buf], case.tab, case.hl[1], case.hl[2])
            end
            assert_content(source_buf, case.content, case.content_first_line)
        end)
    end
end)

describe("view.append", function()
    before_each(setup)
    after_each(clear)
    local result = { "result" }

    it("should create view state", function()
        local source_buf = vim.api.nvim_get_current_buf()

        view.append("data", result)

        assert_view_state(source_buf, view.default, result)
    end)

    it("should use passed view", function()
        local source_buf = vim.api.nvim_get_current_buf()
        local view_ = { append = function() end }

        view.append("data", result, { view = view_ })

        assert_view_state(source_buf, view_, result)
    end)

    for i, open_view in pairs({ nil, true, false }) do
        it("should open win " .. tostring(i), function()
            local source_buf = vim.api.nvim_get_current_buf()

            view.append("data", result, { open_view = open_view })

            if open_view == false then
                assert.is.False(vim.api.nvim_win_is_valid(view.state.win))
            else
                assert_view_win_opened(source_buf)
            end
        end)
    end

    local cases = {
        { content = {},        data = "output",           result_content = { "", "output" } },
        { content = { "header" }, data = "output",           result_content = { "header", "output" } },
        { content = { "one" }, data = { "two", "three" }, result_content = { "one", "two", "three" } },
        { content = { "one", "two" }, data = { "three" },       result_content = { "one", "two", "three" } },
    }
    for i, case in pairs(cases) do
        it("should append data " .. tostring(i), function()
            local source_buf = vim.api.nvim_get_current_buf()
            view.open_view(source_buf)
            local view_state = view.views[source_buf]
            vim.api.nvim_buf_set_lines(view_state.view_buf, 0, -1, false, case.content)

            view.append(case.data, result)

            assert_content(source_buf, case.result_content, 0)
        end)
    end
end)

describe("view.render", function()
    before_each(setup)
    after_each(clear)
    local result = { "result" }

    it("should create view state", function()
        local source_buf = vim.api.nvim_get_current_buf()

        view.render(result)

        assert_view_state(source_buf, view.default, result)
    end)

    it("should use passed view", function()
        local source_buf = vim.api.nvim_get_current_buf()
        local view_ = { render = function() end }

        view.render(result, { view = view_ })

        assert_view_state(source_buf, view_, result)
    end)

    for _, open_view in pairs({ nil, true, false }) do
        it("should open win", function()
            local source_buf = vim.api.nvim_get_current_buf()

            view.render(result, { open_view = open_view })

            if open_view == false then
                assert.is.False(vim.api.nvim_win_is_valid(view.state.win))
            else
                assert_view_win_opened(source_buf)
            end
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

            view.render(result, { view = rendering })

            assert_current_tab(view.views[source_buf], "one", 1, #case.tabs[1] + 3)
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

            view.render(nil, { view = rendering, tab = case.tab })

            if case.tabs ~= nil and #case.tabs > 0 then
                assert_current_tab(view.views[source_buf], case.tab, case.hl[1], case.hl[2])
            end
            assert_content(source_buf, case.content, case.content_first_line)
        end)
    end

    cases = {
        { content = { "one" },                 cursor = { 1, 0 } },
        { content = { "one", "two" },          cursor = { 2, 0 } },
        { content = { "one", "two", "three" }, cursor = { 3, 0 } },
    }
    for i, case in pairs(cases) do
        it("should scroll to bottom " .. tostring(i), function()
            view.render(case.content, { scroll_to_end = true })

            local actual = vim.api.nvim_win_get_cursor(view.state.win)
            assert.are.same(case.cursor, actual)
        end)
    end
end)


describe("view.select_tab", function()
    before_each(setup)
    after_each(clear)
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
            view.render(result, { view = rendering })

            view.select_tab(case.tab)

            ---@cast tab_str string
            assert_current_tab(view.views[source_buf], tab_str, case.hl[1], case.hl[2])
            assert_content(source_buf, case.content, case.content_first_line)
        end)
    end
end)

describe("view.next_tab", function()
    before_each(setup)
    after_each(clear)
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
            view.render(result, { view = rendering, tab = case.tab })

            view.next_tab()

            assert_current_tab(view.views[source_buf], case.next_tab, case.hl[1], case.hl[2])
            assert_content(source_buf, case.content, case.content_first_line)
        end)
    end
end)

describe("view.next_tab", function()
    before_each(setup)
    after_each(clear)
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
            view.render(result, { view = rendering, tab = case.tab })

            view.previous_tab()


            assert_current_tab(view.views[source_buf], case.next_tab, case.hl[1], case.hl[2])
            assert_content(source_buf, case.content, case.content_first_line)
        end)
    end
end)
