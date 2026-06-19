local Job = require "plenary.job"
local environment = require "runb.environment"

---@class JobResult
---@field cmd_code number
---@field command string
---@field args string[]
---@field output string[]

---@class JobParams
---@field cwd? string
---@field env? table
---@field on_start? fun(result: JobResult)
---@field on_output? fun(output: string, result: JobResult)
---@field on_result? fun(result: JobResult):JobResult?

local M = {}

---@param command string
---@param args string[]
---@param params JobParams
---@param await_callback? fun(result: JobResult)
---@return Job
M.run = function(command, args, params, await_callback)
    ---@type JobResult
    local result = {
        cmd_code = -1,
        command = command,
        args = args,
        output = {}
    }
    if params.on_start ~= nil then
        params.on_start(result)
    end

    ---@param data string
    local on_stdout = function(_, data)
        table.insert(result.output, data)
        vim.schedule(function()
            if params.on_output ~= nil then
                params.on_output(data, result)
            end
        end)
    end

    ---@param _ Job
    ---@param exit_code number
    local on_exit = function(_, exit_code)
        result.cmd_code = exit_code
        vim.schedule(function()
            if params.on_result ~= nil then
                result = params.on_result(result) or result
            end
            if await_callback ~= nil then
                await_callback(result)
            end
        end)
    end

    local job = Job:new({
        command = command,
        args = args,
        cwd = params.cwd or vim.fn.getcwd(),
        env = params.env or environment.get_job_env(),
        on_stderr = on_stdout,
        on_stdout = on_stdout,
        on_exit = on_exit,
    })
    job:start()

    return job
end

return M
