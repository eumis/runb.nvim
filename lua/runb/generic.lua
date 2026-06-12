local Job = require "plenary.job"
local environment = require "runb.environment"

---@class JobResult
---@field cmd_code number
---@field command string
---@field args string[]
---@field output string[]

---@class JobParams
---@field args? string[]
---@field cwd? string
---@field env? table
---@field render? boolean
---@field on_start? fun(result: JobResult)
---@field on_output? fun(output: string, result: JobResult)
---@field on_result? fun(result: JobResult)

local M = {}

---@param command string
---@param params JobParams
---@return Job
M.run = function(command, params)
    local args = params.args or {}
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
                params.on_result(result)
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

local state = {
    ---@type JobParams?
    params = nil
}

---@param params? JobParams
M.use_run_params = function(params)
    state.params = params
end

---@return JobParams?
M.pop_run_params = function()
    local params = state.params
    state.params = nil
    return params
end

---@param params? JobParams
---@param callback? fun(result: JobResult)
---@return JobParams
M.get_run_params = function(params, callback)
    if callback == nil and type(params) == "function" then
        callback = params
        params = nil
    end
    params = params or state.params or {}
    params.args = params.args or {}
    if callback ~= nil then
        local merged_callback = callback
        local on_result = params.on_result
        if on_result ~= nil then
            merged_callback = function(result)
                on_result(result)
                callback(result)
            end
        end
        params.on_result = merged_callback
    end
    return vim.deepcopy(params, true)
end

return M
