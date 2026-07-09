---@diagnostic disable: need-check-nil

local assert = require "luassert"
local util = require "runb.util"
local stub = require "luassert.stub"
local rest = require "runb.rest"
local generic = require "runb.generic"
local view = require "runb.view"

local generic_run_stub = stub.new(generic, "run")
local with_auto_render_stub = stub.new(view, "with_auto_render", function(params) return params end)

local function cleanup()
    rest.settings.args = nil
    generic_run_stub:clear()
    with_auto_render_stub:clear()
end

---@param expected string[]
---@param actual string[]
local function assert_same_values(expected, actual)
    table.sort(expected)
    table.sort(actual)
    assert.are.same(expected, actual)
end

local function odd(i, _) return i % 2 ~= 0 end

local function assert_odds(list, value)
    util.for_each(list, odd, function(_, v)
        assert.are.same(value, v)
    end)
end

describe("rest.H", function()
    it("should return a list of header params", function()
        local actual = rest.H({ a = 1, b = "value" })

        assert_odds(actual, "-H")
        assert_same_values({ "-H", "a:1", "-H", "b:value" }, actual)
    end)
end)

describe("rest.form", function()
    it("should return a table with form data", function()
        local actual = rest.form({ a = 1, b = "value" })

        assert.are.same({ "-H", "Content-Type:application/x-www-form-urlencoded", "-d" }, util.take(actual, 3))
        assert_same_values({ "a=1", "b=value" }, util.split(actual[4], "&"))
    end)
end)

describe("rest.form_url_encoded", function()
    it("should return a table with form urlencoded data", function()
        local actual = rest.form_url_encoded({ a = 1, b = "value" })

        assert.are.same({ "-H", "Content-Type:application/x-www-form-urlencoded" }, util.take(actual, 2))
        assert_same_values({ "--data-urlencode", "a=1", "--data-urlencode", "b=value" }, util.skip(actual, 2))
    end)
end)

describe("rest.json", function()
    it("should return a table with json data", function()
        local data = { a = 1, b = "value", c = { 1, 2, 3 } }
        local actual = rest.json(data)

        assert.are.same({ "-H", "Content-Type:application/json", "-d" }, util.take(actual, 3))
        assert_same_values(data, vim.json.decode(actual[4]))
    end)
end)

describe("rest.query", function()
    it("should return a table with query data", function()
        local actual = rest.query({ a = 1, b = "value" })

        assert.are.same("-G", actual[1])
        assert_same_values({ "--data-urlencode", "a=1", "--data-urlencode", "b=value" }, util.skip(actual, 1))
    end)
end)

---@param expected string[]
---@param params table
---@param callback fun(result: JobResult)
local function assert_curl(expected, params, callback)
    assert.stub(generic_run_stub).was_called_with("curl", expected, params, callback)
end

describe("rest.curl", function()
    after_each(cleanup)

    local cases = {
        {
            args = { { "-H", "a:1" }, { "-G", "--data-urlencode", "b=value" } },
            use_args = { "-i" },
            expected = { "-H", "a:1", "-G", "--data-urlencode", "b=value", "-i" }
        },
        {
            args = { { "-H", "b:value" }, { "-H", "Content-Type:application/json", "-d", '{"a":1}' } },
            use_args = { "-i" },
            expected = { "-H", "b:value", "-H", "Content-Type:application/json", "-d", '{"a":1}', "-i" }
        },
    }
    for i, case in pairs(cases) do
        it("should flatten args and append settings args " .. i, function()
            local callback = function(_) end
            rest.settings.args = case.use_args

            rest.curl(case.args, callback)

            assert.stub(with_auto_render_stub).was_called()
            assert_curl(case.expected, {}, callback)
        end)
    end

    describe("argument resolution", function()
        local args = { "-H", "a:1" }

        it("should run with args only", function()
            rest.curl(args)

            assert.stub(with_auto_render_stub).was_called_with({})
            assert_curl(args, {}, nil)
        end)

        it("should run with args and params", function()
            local params = { cwd = "/some/dir" }

            rest.curl(args, params)

            assert.stub(with_auto_render_stub).was_called_with(params)
            assert_curl(args, params, nil)
        end)

        it("should run with args and await_callback", function()
            local callback = function(_) end

            rest.curl(args, callback)

            assert.stub(with_auto_render_stub).was_called_with({})
            assert_curl(args, {}, callback)
        end)

        it("should run with args, params and await_callback", function()
            local params = { cwd = "/some/dir" }
            local callback = function(_) end

            rest.curl(args, params, callback)

            assert.stub(with_auto_render_stub).was_called_with(params)
            assert_curl(args, params, callback)
        end)
    end)
end)

describe("rest.get", function()
    after_each(cleanup)

    it("should curl GET", function()
        local callback = function(_) end

        rest.get({ "-H", "a:1" }, callback)

        assert_curl({ "-H", "a:1", "-X", "GET" }, {}, callback)
    end)
end)

describe("rest.post", function()
    after_each(cleanup)

    it("should curl POST", function()
        local callback = function(_) end

        rest.post({ "-H", "a:1" }, callback)

        assert_curl({ "-H", "a:1", "-X", "POST" }, {}, callback)
    end)
end)

describe("rest.put", function()
    after_each(cleanup)

    it("should curl PUT", function()
        local callback = function(_) end

        rest.put({ "-H", "a:1" }, callback)

        assert_curl({ "-H", "a:1", "-X", "PUT" }, {}, callback)
    end)
end)

describe("rest.delete", function()
    after_each(cleanup)

    it("should curl DELETE", function()
        local callback = function(_) end

        rest.delete({ "-H", "a:1" }, callback)

        assert_curl({ "-H", "a:1", "-X", "DELETE" }, {}, callback)
    end)
end)

describe("rest.patch", function()
    after_each(cleanup)

    it("should curl PATCH", function()
        local callback = function(_) end

        rest.patch({ "-H", "a:1" }, callback)

        assert_curl({ "-H", "a:1", "-X", "PATCH" }, {}, callback)
    end)
end)
