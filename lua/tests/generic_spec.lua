---@diagnostic disable: need-check-nil

local assert = require "luassert"
local stub = require "luassert.stub"
local match = require "luassert.match"
local generic = require "runb.generic"
local environment = require "runb.environment"

local Job = require "plenary.job"
local job_start_stub = stub.new()
local job_new_stub = stub.new(Job, "new", function() return { start = job_start_stub } end)

local schedule_stub = stub.new(vim, "schedule")

assert:register("matcher", "job_params", function(_, arguments)
    local expected = arguments[1]
    return function(actual)
        return actual.command == expected.command
            and pcall(function() assert.are.same(actual.args, expected.args) end)
            and actual.cwd == expected.cwd
            and pcall(function() assert.are.same(actual.env, expected.env) end)
    end
end)

---run the last scheduled callback captured by the schedule stub
local function run_scheduled()
    schedule_stub.calls[#schedule_stub.calls].vals[1]()
end

describe("generic.run", function()
    local path = "path/to/script"
    after_each(function()
        job_new_stub:clear()
        job_start_stub:clear()
        schedule_stub:clear()
    end)

    for _, cmd in pairs { "bash", "python", "usql" } do
        it("should run job " .. cmd, function()
            environment.set("", { a = 1 }, true)

            generic.run(cmd, { path }, {})

            assert.stub(job_new_stub).was.called_with(match._, match.is_job_params({
                command = cmd,
                args = { path },
                cwd = vim.fn.getcwd(),
                env = environment.get_job_env(),
            }))
            assert.stub(job_start_stub).was.called()
        end)

        it("should call on_start " .. cmd, function()
            local on_start = stub.new()
            local args = { path }
            local result = { cmd_code = -1, command = cmd, args = args, output = {} }

            generic.run(cmd, args, { on_start = on_start })

            assert.stub(on_start).was.called_with(result)
        end)

        it("should call on_output for stdout " .. cmd, function()
            local on_output = stub.new()
            local args = { path }
            local stdout = "new output line"
            local result = { cmd_code = -1, command = cmd, args = args, output = { stdout } }

            generic.run(cmd, args, { on_output = on_output })
            job_new_stub.calls[1].vals[2].on_stdout(nil, stdout)
            run_scheduled()

            assert.stub(on_output).was.called_with(stdout, result)
        end)

        it("should call on_output for stderr " .. cmd, function()
            local on_output = stub.new()
            local args = { path }
            local stderr = "error output"
            local result = { cmd_code = -1, command = cmd, args = args, output = { stderr } }

            generic.run(cmd, args, { on_output = on_output })
            job_new_stub.calls[1].vals[2].on_stderr(nil, stderr)
            run_scheduled()

            assert.stub(on_output).was.called_with(stderr, result)
        end)

        it("should call on_result with the collected result " .. cmd, function()
            local on_result = stub.new()
            local args = { path }
            local result = { cmd_code = 1, command = cmd, args = args, output = { "line 1", "line 2" } }

            generic.run(cmd, args, { on_result = on_result })
            for _, stdout in ipairs(result.output) do
                job_new_stub.calls[1].vals[2].on_stdout(nil, stdout)
            end
            job_new_stub.calls[1].vals[2].on_exit(nil, result.cmd_code)
            run_scheduled()

            assert.stub(on_result).was.called_with(result)
        end)

        it("should call await_callback with the result " .. cmd, function()
            local await_callback = stub.new()
            local args = { path }
            local result = { cmd_code = 0, command = cmd, args = args, output = { "line" } }

            generic.run(cmd, args, {}, await_callback)
            job_new_stub.calls[1].vals[2].on_stdout(nil, "line")
            job_new_stub.calls[1].vals[2].on_exit(nil, result.cmd_code)
            run_scheduled()

            assert.stub(await_callback).was.called_with(result)
        end)

        it("should pass the on_result return value to await_callback " .. cmd, function()
            local mapped = { mapped = true }
            local await_callback = stub.new()
            local on_result = function() return mapped end

            generic.run(cmd, { path }, { on_result = on_result }, await_callback)
            job_new_stub.calls[1].vals[2].on_exit(nil, 0)
            run_scheduled()

            assert.stub(await_callback).was.called_with(mapped)
        end)
    end
end)
