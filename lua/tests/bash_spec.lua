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
        bash.setup({ command = "bash" })
    end)

    for _, bash_path in ipairs { "bash", "/usr/bin/bash" } do
        it("should run job " .. bash_path, function()
            local callback = function(_) end
            bash.settings.command = bash_path

            bash.run(path, callback)

            assert.stub(generic_run_stub).was_called_with(bash_path, { args = { path }, on_result = callback })
        end)

        it("should run job with args " .. bash_path, function()
            local callback = function(_) end
            local args = { "--init-file", "/path/to/init/file.sh" }
            bash.setup({
                command = bash_path,
                args = args
            })

            bash.run(path, callback)

            assert.stub(generic_run_stub).was_called_with(bash_path,
                { args = { path, "--init-file", "/path/to/init/file.sh" }, on_result = callback })
        end)
    end
end)
