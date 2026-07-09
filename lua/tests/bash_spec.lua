---@diagnostic disable: need-check-nil

local assert = require "luassert"
local stub = require "luassert.stub"
local bash = require "runb.bash"
local generic = require "runb.generic"
local view = require "runb.view"

local generic_run_stub = stub.new(generic, "run")
---@type JobParams
local rendered_params = { cwd = "rendered" }
local with_auto_render_stub = stub.new(view, "with_auto_render", function() return rendered_params end)

describe("bash.run", function()
    local path = "path/to/bash/script"
    after_each(function()
        generic_run_stub:clear()
        with_auto_render_stub:clear()
        bash.setup({ command = "bash" })
    end)

    for _, bash_path in pairs { "bash", "/usr/bin/bash" } do
        it("should run job " .. bash_path, function()
            local callback = function(_) end
            bash.settings.command = bash_path

            bash.run(path, callback)

            assert.stub(with_auto_render_stub).was_called_with({})
            assert.stub(generic_run_stub).was_called_with(bash_path, { path }, rendered_params, callback)
        end)

        it("should run job with args " .. bash_path, function()
            local callback = function(_) end
            bash.setup({
                command = bash_path,
                args = { "--init-file", "/path/to/init/file.sh" }
            })

            bash.run(path, callback)

            assert.stub(generic_run_stub).was_called_with(bash_path, { path, "--init-file", "/path/to/init/file.sh" },
                rendered_params, callback)
        end)
    end

    describe("argument resolution", function()
        it("should run with args only", function()
            bash.run(path)

            assert.stub(with_auto_render_stub).was_called_with({})
            assert.stub(generic_run_stub).was_called_with("bash", { path }, rendered_params, nil)
        end)

        it("should run with args and params", function()
            local params = { cwd = "/some/dir" }

            bash.run(path, params)

            assert.stub(with_auto_render_stub).was_called_with(params)
            assert.stub(generic_run_stub).was_called_with("bash", { path }, rendered_params, nil)
        end)

        it("should run with args and await_callback", function()
            local callback = function(_) end

            bash.run(path, callback)

            assert.stub(with_auto_render_stub).was_called_with({})
            assert.stub(generic_run_stub).was_called_with("bash", { path }, rendered_params, callback)
        end)

        it("should run with args, params and await_callback", function()
            local params = { cwd = "/some/dir" }
            local callback = function(_) end

            bash.run(path, params, callback)

            assert.stub(with_auto_render_stub).was_called_with(params)
            assert.stub(generic_run_stub).was_called_with("bash", { path }, rendered_params, callback)
        end)
    end)
end)
