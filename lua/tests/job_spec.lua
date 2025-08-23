---@diagnostic disable: need-check-nil

local assert = require "luassert"
local Job = require "plenary.job"
local job = require "runb.job"
local stub = require "luassert.stub"

local schedule_stub = stub.new(vim, "schedule")
schedule_stub.invokes(function(callback)
    callback()
end)

describe("job.run", function()
    local cases = {
        {
            params = { command = "ls" },
            expected = { command = "ls", args = {}, cwd = vim.fn.getcwd() },
        },
        {
            params = { command = "echo", args = { "hello" } },
            expected = { command = "echo", args = { "hello" }, cwd = vim.fn.getcwd() },
        },
        {
            params = { command = "echo", args = { "hello" }, cwd = "~" },
            expected = { command = "echo", args = { "hello" }, cwd = "~" },
        },
    }

    for i, case in ipairs(cases) do
        it("should return a job " .. tostring(i), function()
            local actual = job.run(case.params)

            assert.is.Not.Nil(actual)
            assert.is.True(Job.is_job(actual))
            assert.are.same(case.expected.command, actual.command)
            assert.are.same(case.expected.args, actual.args)
            assert.are.same(case.expected.cwd, actual._raw_cwd)
        end)
    end

    cases = {
        {
            params = { command = "echo", args = { "hello" } },
            expected = { "hello" },
        },
        {
            params = { command = "echo", args = { "test" } },
            expected = { "test" },
        },
    }
    for i, case in ipairs(cases) do
        it("should run a job " .. tostring(i), function()
            local actual_job = job.run(case.params)
            actual_job:wait()
            local actual = actual_job:result()

            assert.are.same(case.expected, actual)
        end)
    end

    cases = {
        {
            params = { command = "echo", args = { "hello" } },
            expected = { cmd_code = 0, input = { "echo hello" }, output = { "hello" } },
        },
        {
            params = { command = "echo", args = { "some test" } },
            expected = { cmd_code = 0, input = { "echo some test" }, output = { "some test" } },
        }
    }
    for i, case in ipairs(cases) do
        it("should call a on_result " .. tostring(i), function()
            local result = nil
            case.params.on_result = function(rs)
                result = rs
            end

            local actual_job = job.run(case.params)
            actual_job:wait()

            assert.is.Not.Nil(result)
            assert.are.same(case.expected.cmd_code, result.cmd_code)
            assert.are.same(case.expected.input, result.input)
            assert.are.same(case.expected.output, result.output)
        end)
    end
    cases = {
        {
            params = { command = "echo", args = { "hello" } },
            expected = { cmd_code = 0, input = { "echo hello" }, output = { "hello" } },
        },
        {
            params = { command = "echo", args = { "some test" } },
            expected = { cmd_code = 0, input = { "echo some test" }, output = { "some test" } },
        }
    }
    for i, case in ipairs(cases) do
        it("should call a on_output " .. tostring(i), function()
            local output = {}
            case.params.on_output = function(data)
                table.insert(output, data)
            end

            local actual_job = job.run(case.params)
            actual_job:wait()

            assert.are.same(case.expected.output, output)
        end)
    end
end)
