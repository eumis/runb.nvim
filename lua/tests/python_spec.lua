---@diagnostic disable: need-check-nil

local assert = require "luassert"
local stub = require "luassert.stub"
local python = require "runb.python"
local generic = require "runb.generic"

local generic_run_stub = stub.new(generic, "run")

describe("python.run", function()
    local path = "path/to/python/script"
    after_each(function()
        generic_run_stub:clear()
    end)

    for _, python_path in ipairs { "python", "python3.12", "/usr/bin/python" } do
        it("should run job " .. python_path, function()
            local callback = function(_) end
            python.command = python_path

            python.run(path, callback)

            assert.stub(generic_run_stub).was_called_with(python_path, { command_args = { path } }, callback)
        end)
    end
end)
