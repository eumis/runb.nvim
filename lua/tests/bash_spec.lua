---@diagnostic disable: need-check-nil

local assert = require "luassert"
local stub = require "luassert.stub"
local bash = require "runb.bash"
local generic = require "runb.generic"

local generic_run_stub = stub.new(generic, "run")

describe("bash.run", function()
    local path = "path/to/bash/script"
    after_each(function()
        generic_run_stub:clear()
    end)

    for _, bash_path in ipairs { "bash", "/usr/bin/bash" } do
        it("should run job " .. bash_path, function()
            local callback = function(_) end
            bash.command = bash_path

            bash.run(path, callback)

            assert.stub(generic_run_stub).was_called_with(bash_path, { args = { path } }, callback)
        end)
    end
end)
