---@diagnostic disable: need-check-nil

local assert = require "luassert"
local stub = require "luassert.stub"
local runb = require "runb"
local bash = require "runb.bash"
local python = require "runb.python"

local dofile_stub = stub.new(_G, "dofile")
local bash_run_stub = stub.new(bash, "run")
local python_run_stub = stub.new(python, "run")

describe("runb.run", function()
    it("should run lua file", function()
        vim.bo.filetype = "lua"

        runb.run()

        assert.stub(dofile_stub).was_called_with(vim.fn.expand("%"))
    end)

    it("should run bash", function()
        vim.bo.filetype = "sh"

        runb.run()

        assert.stub(bash_run_stub).was_called_with(vim.fn.expand("%:p"))
    end)

    it("should run python", function()
        vim.bo.filetype = "python"

        runb.run()

        assert.stub(python_run_stub).was_called_with(vim.fn.expand("%:p"))
    end)
end)

describe("runb.await", function()
    local fun = function(arg, callback)
        callback(arg)
    end

    it("should resume coroutine in callback", function()
        local arg = { 1, 2, 3 }

        runb.async(function()
            local actual = runb.await(fun, arg)

            assert.are.same(arg, actual)
        end)
    end)
end)
