---@diagnostic disable: need-check-nil

local assert = require "luassert"
local stub = require "luassert.stub"
local sql = require "runb.sql"
local generic = require "runb.generic"

local generic_run_stub = stub.new(generic, "run")

describe("sql.run", function()
    local path = "path/to/sql/script"
    after_each(function()
        generic_run_stub:clear()
        sql.setup({ command = "default" })
    end)

    for _, sql_path in ipairs { "usql", "/usr/bin/usql" } do
        it("should run job " .. sql_path, function()
            local callback = function(_) end
            sql.settings.command = sql_path

            sql.run(path, callback)

            assert.stub(generic_run_stub).was_called_with(sql_path, { args = { path }, on_result = callback })
        end)

        it("should run job with args " .. sql_path, function()
            local callback = function(_) end
            local args = { "connection" }
            sql.setup({
                command = sql_path,
                args = args
            })

            sql.run(path, callback)

            assert.stub(generic_run_stub).was_called_with(sql_path,
                { args = { path, "connection" }, on_result = callback })
        end)
    end
end)
