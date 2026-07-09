---@diagnostic disable: need-check-nil

local assert = require "luassert"
local stub = require "luassert.stub"
local python = require "runb.python"
local generic = require "runb.generic"
local view = require "runb.view"

local generic_run_stub = stub.new(generic, "run")
---@type JobParams
local rendered_params = { cwd = "rendered" }
local with_auto_render_stub = stub.new(view, "with_auto_render", function() return rendered_params end)

describe("python.run", function()
    local path = "path/to/python/script"
    after_each(function()
        generic_run_stub:clear()
        with_auto_render_stub:clear()
        python.setup({ command = "default" })
    end)

    for _, python_path in pairs { "python", "python3.12", "/usr/bin/python" } do
        it("should run job " .. python_path, function()
            local callback = function(_) end
            python.settings.command = python_path

            python.run(path, callback)

            assert.stub(with_auto_render_stub).was_called_with({})
            assert.stub(generic_run_stub).was_called_with(python_path, { path }, rendered_params, callback)
        end)

        it("should run job with args " .. python_path, function()
            local callback = function(_) end
            python.setup({
                command = python_path,
                args = { "-param", "value" }
            })

            python.run(path, callback)

            assert.stub(generic_run_stub).was_called_with(python_path,
                { path, "-param", "value" }, rendered_params, callback)
        end)
    end

    describe("argument resolution", function()
        it("should run with args only", function()
            python.run(path)

            assert.stub(with_auto_render_stub).was_called_with({})
            assert.stub(generic_run_stub).was_called_with("default", { path }, rendered_params, nil)
        end)

        it("should run with args and params", function()
            local params = { cwd = "/some/dir" }

            python.run(path, params)

            assert.stub(with_auto_render_stub).was_called_with(params)
            assert.stub(generic_run_stub).was_called_with("default", { path }, rendered_params, nil)
        end)

        it("should run with args and await_callback", function()
            local callback = function(_) end

            python.run(path, callback)

            assert.stub(with_auto_render_stub).was_called_with({})
            assert.stub(generic_run_stub).was_called_with("default", { path }, rendered_params, callback)
        end)

        it("should run with args, params and await_callback", function()
            local params = { cwd = "/some/dir" }
            local callback = function(_) end

            python.run(path, params, callback)

            assert.stub(with_auto_render_stub).was_called_with(params)
            assert.stub(generic_run_stub).was_called_with("default", { path }, rendered_params, callback)
        end)
    end)
end)
