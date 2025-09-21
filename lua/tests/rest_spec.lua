---@diagnostic disable: need-check-nil

local assert = require "luassert"
local util = require "runb.util"
local stub = require "luassert.stub"
local rest = require "runb.rest"
local generic = require "runb.generic"

local generic_run_stub = stub.new(generic, "run")

local function cleanup()
    rest.settings.args = nil
    generic_run_stub:clear()
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

describe("rest.curl", function()
    after_each(cleanup)

    local cases = {
        {
            method = "GET",
            args = { { "-H", "a:1" }, { "-G", "--data-urlencode", "b=value" } },
            use_args = { "-i" },
            expected = { "-X", "GET", "-H", "a:1", "-G", "--data-urlencode", "b=value", "-i" }
        },
        {
            method = "POST",
            args = { { "-H", "b:value" }, { "-H", "Content-Type:application/json", "-d", '{"a":1}' } },
            use_args = { "-i" },
            expected = { "-X", "POST", "-H", "b:value", "-H", "Content-Type:application/json", "-d", '{"a":1}', "-i" }
        },
    }
    for i, case in ipairs(cases) do
        it("should run curl job " .. i, function()
            local callback = function(_) end
            rest.settings.args = case.use_args

            rest.curl(case.method, case.args, callback)

            assert.stub(generic_run_stub).was_called_with("curl", { args = case.expected, on_result = callback })
        end)
    end
end)

local args = { a = 1, b = "value" }
local callback = function() end

local function assert_method(method)
    local method_args = { "-X", method }
    util.append(method_args, args)
    assert.stub(generic_run_stub).was_called_with("curl", { args = method_args, on_result = callback })
end

describe("rest.get", function()
    after_each(cleanup)

    it("should curl GET", function()
        rest.get(args, callback)

        assert_method("GET")
    end)
end)

describe("rest.post", function()
    after_each(cleanup)

    it("should curl POST", function()
        rest.post(args, callback)

        assert_method("POST")
    end)
end)

describe("rest.put", function()
    after_each(cleanup)

    it("should curl PUT", function()
        rest.put(args, callback)

        assert_method("PUT")
    end)
end)

describe("rest.delete", function()
    after_each(cleanup)

    it("should curl DELETE", function()
        rest.delete(args, callback)

        assert_method("DELETE")
    end)
end)

describe("rest.patch", function()
    after_each(cleanup)

    it("should curl PATCH", function()
        rest.patch(args, callback)

        assert_method("PATCH")
    end)
end)
