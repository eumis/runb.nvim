---@diagnostic disable: need-check-nil

local assert = require "luassert"
local stub = require "luassert.stub"
local sql = require "runb.sql"
local generic = require "runb.generic"
local view = require "runb.view"

local generic_run_stub = stub.new(generic, "run")
---@type JobParams
local rendered_params = { cwd = "rendered" }
local with_auto_render_stub = stub.new(view, "with_auto_render", function() return rendered_params end)

describe("sql.run", function()
    local path = "path/to/sql/script"
    after_each(function()
        generic_run_stub:clear()
        with_auto_render_stub:clear()
        sql.setup({ command = "default" })
    end)

    for _, sql_path in pairs { "usql", "/usr/bin/usql" } do
        it("should run job " .. sql_path, function()
            local callback = function(_) end
            sql.settings.command = sql_path

            sql.run(path, callback)

            assert.stub(with_auto_render_stub).was_called_with({})
            assert.stub(generic_run_stub).was_called_with(sql_path, { path }, rendered_params, callback)
        end)

        it("should run job with args " .. sql_path, function()
            local callback = function(_) end
            sql.setup({
                command = sql_path,
                args = { "connection" }
            })

            sql.run(path, callback)

            assert.stub(generic_run_stub).was_called_with(sql_path,
                { path, "connection" }, rendered_params, callback)
        end)
    end

    describe("argument resolution", function()
        it("should run with args only", function()
            sql.run(path)

            assert.stub(with_auto_render_stub).was_called_with({})
            assert.stub(generic_run_stub).was_called_with("default", { path }, rendered_params, nil)
        end)

        it("should run with args and params", function()
            local params = { cwd = "/some/dir" }

            sql.run(path, params)

            assert.stub(with_auto_render_stub).was_called_with(params)
            assert.stub(generic_run_stub).was_called_with("default", { path }, rendered_params, nil)
        end)

        it("should run with args and await_callback", function()
            local callback = function(_) end

            sql.run(path, callback)

            assert.stub(with_auto_render_stub).was_called_with({})
            assert.stub(generic_run_stub).was_called_with("default", { path }, rendered_params, callback)
        end)

        it("should run with args, params and await_callback", function()
            local params = { cwd = "/some/dir" }
            local callback = function(_) end

            sql.run(path, params, callback)

            assert.stub(with_auto_render_stub).was_called_with(params)
            assert.stub(generic_run_stub).was_called_with("default", { path }, rendered_params, callback)
        end)
    end)
end)
