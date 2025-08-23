---@diagnostic disable: need-check-nil

local assert = require "luassert"
local stub = require "luassert.stub"
local python = require "runb.python"
local job = require "runb.job"
local environment = require "runb.environment"
local view = require "runb.view"

local job_run_stub = stub.new(job, "run")
local view_render_stub = stub.new(view, "render")

local schedule_stub = stub.new(vim, "schedule")
schedule_stub.invokes(function(callback)
    callback()
end)

describe("python.run", function()
    local path = "path/to/python/script"
    after_each(function()
        job_run_stub:clear()
        view_render_stub:clear()
    end)

    it("should run job", function()
        local callback = function(_) end
        environment.set("", { a = 1 }, true)

        python.run(path, callback)

        assert.stub(job_run_stub).was_called_with({
            command = "python",
            args = { path },
            env = environment.get(),
            on_output = nil,
            on_result = callback
        })
    end)

    it("should render calling text", function()
        local current_buf = vim.api.nvim_get_current_buf()

        python.run(path)

        assert.stub(view_render_stub).was_called_with("Running...", { source_buf = current_buf })
    end)

    it("should append data to view while in progress", function()
        local current_buf = vim.api.nvim_get_current_buf()

        python.run(path)
        job_run_stub.calls[1].vals[1].on_output("data")

        assert.stub(view_render_stub).was_called_with("data", { source_buf = current_buf, append = true })
    end)

    it("should render result", function()
        local current_buf = vim.api.nvim_get_current_buf()

        python.run(path)
        job_run_stub.calls[1].vals[1].on_result({ input = "python " .. path, output = "data" })

        assert.stub(view_render_stub).was_called_with("python " .. path, { source_buf = current_buf })
        assert.stub(view_render_stub).was_called_with("data", { source_buf = current_buf, append = true })
    end)
end)
