---@diagnostic disable: need-check-nil

local assert = require "luassert"
local environment = require "runb.environment"

local function cleanup()
end

describe("environment.set", function()
    after_each(cleanup)

    it("should set env", function()
        local env = { a = 1, b = "value" }

        local actual = environment.set("test", env)

        assert.are.same(env, environment.get("test"))
        assert.are.same(env, actual)
    end)

    it("should set env current", function()
        local env = { a = 1, b = "value" }

        local actual = environment.set("test", env, true)

        assert.are.same(env, environment.get())
        assert.are.same(env, actual)
    end)
end)

describe("environment.set_current", function()
    after_each(cleanup)

    it("should set current env", function()
        local env = { a = 1, b = "value" }
        environment.set("test", env)

        local actual = environment.set_current("test")

        assert.are.same("test", environment.current)
        assert.are.same(env, environment.get())
        assert.are.same(env, actual)
    end)
end)

describe("environment.get", function()
    after_each(cleanup)

    it("should return env", function()
        local env = { a = 1, b = "value" }
        environment.set("test", env)

        environment.set_current("test")

        assert.are.same(env, environment.get("test"))
    end)
end)
