---@diagnostic disable: need-check-nil

local assert = require "luassert"
local environment = require "runb.environment"

describe("environment.set", function()
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
    it("should set current env", function()
        local env = { a = 1, b = "value" }
        environment.set("test", env)

        local actual = environment.set_current("test")

        assert.are.same("test", environment.current)
        assert.are.same(env, environment.get())
        assert.are.same(env, actual)
    end)

    it("should send event", function()
        local env = { a = 1, b = "value" }
        environment.set("test", env)
        local actual_data = nil
        vim.api.nvim_create_autocmd("User", {
            pattern = "RunbEnvChanged",
            callback = function(args)
                actual_data = args.data
            end
        })

        environment.set_current("test")

        assert.are.same({ name = "test" }, actual_data)
    end)
end)

describe("environment.get", function()
    it("should return env", function()
        local env = { a = 1, b = "value" }
        environment.set("test", env)

        environment.set_current("test")

        assert.are.same(env, environment.get("test"))
    end)
end)

describe("environment.add_system_env", function()
    it("should add system env vars to env", function()
        local env = {}
        environment.add_system_vars(env)

        for k, v in pairs(vim.uv.os_environ()) do
            assert.are.same(v, env[k])
        end
    end)
end)
