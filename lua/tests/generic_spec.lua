---@diagnostic disable: need-check-nil

local assert = require "luassert"
local stub = require "luassert.stub"
local match = require "luassert.match"
local generic = require "runb.generic"
local environment = require "runb.environment"

local Job = require "plenary.job"
local job_run_stub = stub.new()
local job_new_stub = stub.new(Job, "new", function() return { start = job_run_stub } end)

local view = require "runb.view"
local view_start_stub = stub.new(view, "start")
local view_append_stub = stub.new(view, "append")
local view_render_stub = stub.new(view, "render")

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

describe("generic.run", function()
    local path = "path/to/script"
    after_each(function()
        job_new_stub:clear()
        job_run_stub:clear()
        view_start_stub:clear()
        view_append_stub:clear()
        view_render_stub:clear()
        schedule_stub:clear()
    end)

    for _, cmd in ipairs { "bash", "python", "usql" } do
        it("should run job " .. cmd, function()
            environment.set("", { a = 1 }, true)

            generic.run(cmd, { args = { path } })

            assert.stub(job_new_stub).was.called_with(match._, match.is_job_params({
                command = cmd,
                args = { path },
                cwd = vim.fn.getcwd(),
                env = environment.get(),
            }))
            assert.stub(job_run_stub).was.called()
        end)

        it("should start view " .. cmd, function()
            local on_start = stub.new()
            local current_buf = vim.api.nvim_get_current_buf()
            local args = { path }
            local result = { cmd_code = -1, command = cmd, args = args, output = {} }

            ---@diagnostic disable-next-line: assign-type-mismatch
            generic.run(cmd, { args = args, on_start = on_start })

            assert.stub(view_start_stub).was_called_with(
                result,
                { source_buf = current_buf }
            )
            assert.stub(on_start).was.called_with(result)
        end)

        it("should append stdout " .. cmd, function()
            local on_output = stub.new()
            local current_buf = vim.api.nvim_get_current_buf()
            local args = { path }
            local stdout = "new output line"
            local result = { cmd_code = -1, command = cmd, args = args, output = { stdout } }

            ---@diagnostic disable-next-line: assign-type-mismatch
            generic.run(cmd, { args = args, on_output = on_output })
            job_new_stub.calls[1].vals[2].on_stdout(nil, stdout)
            schedule_stub.calls[#schedule_stub.calls].vals[1]()

            assert.stub(view_append_stub).was_called_with(
                stdout,
                result,
                { source_buf = current_buf, scroll_to_end = true }
            )
            assert.stub(on_output).was.called_with(stdout, result)
        end)

        it("should append stderr " .. cmd, function()
            local on_output = stub.new()
            local current_buf = vim.api.nvim_get_current_buf()
            local args = { path }
            local stderr = "error output"
            local result = { cmd_code = -1, command = cmd, args = args, output = { stderr } }

            ---@diagnostic disable-next-line: assign-type-mismatch
            generic.run(cmd, { args = args, on_output = on_output })
            job_new_stub.calls[1].vals[2].on_stderr(nil, stderr)
            schedule_stub.calls[#schedule_stub.calls].vals[1]()

            assert.stub(view_append_stub).was_called_with(
                stderr,
                result,
                { source_buf = current_buf, scroll_to_end = true }
            )
            assert.stub(on_output).was.called_with(stderr, result)
        end)

        it("should render result " .. cmd, function()
            local on_result = stub.new()
            local current_buf = vim.api.nvim_get_current_buf()
            local args = { path }
            local result = { cmd_code = 1, command = cmd, args = args, output = { "line 1", "line 2" } }

            ---@diagnostic disable-next-line: assign-type-mismatch
            generic.run(cmd, { args = args, on_result = on_result })
            for _, stdout in ipairs(result.output) do
                job_new_stub.calls[1].vals[2].on_stdout(nil, stdout)
            end
            job_new_stub.calls[1].vals[2].on_exit(nil, result.cmd_code)
            schedule_stub.calls[#schedule_stub.calls].vals[1]()

            assert.stub(view_render_stub).was_called_with(
                result,
                { source_buf = current_buf }
            )
            assert.stub(on_result).was.called_with(result)
        end)
    end
end)
