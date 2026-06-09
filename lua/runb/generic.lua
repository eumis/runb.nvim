local Job = require "plenary.job"
local niew = require "runb.niew"
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
function M.run(command, params)
    local render = params.render == nil and true or params.render
    local args = params.args or {}
    ---@type JobResult
    local result = {
        cmd_code = -1,
        command = command,
        args = args,
        output = {}
    }
    local source_buf = vim.api.nvim_get_current_buf()

    if render then
        local view = niew.open_view(source_buf)
        local content = { command }
        if result.args ~= nil then
            table.insert(content, table.concat(result.args, " "))
        end
        table.insert(content, "")
        table.insert(content, "Running...")
        view:render(content)
    end
    if params.on_start ~= nil then
        params.on_start(result)
    end

    ---@param data string
    local on_stdout = function(_, data)
        table.insert(result.output, data)
        vim.schedule(function()
            if render then
                niew.get_view(source_buf, true):render({ data, "", "Running..." }, { start_line = -2 })
            end
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
            if render then
                niew.get_view(source_buf, true):render(result.output)
            end
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

return M
