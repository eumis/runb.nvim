local Job = require "plenary.job"

---@class JobResult
---@field cmd_code number
---@field input string[]
---@field output string[]

---@class JobParams
---@field command string
---@field args? string[]
---@field cwd? string
---@field env? table
---@field on_output? fun(output: string)
---@field on_result? fun(result: JobResult)

local M = {
    Job = Job
}

---@param params JobParams
---@return Job
function M.run(params)
    local args = params.args or {}
    ---@type JobResult
    local result = {
        cmd_code = -1,
        input = { params.command .. " " .. table.concat(args, " ") },
        output = {}
    }
    local on_output = function(_, data)
        vim.schedule(function()
            table.insert(result.output, data)
        end)
    end
    if params.on_output ~= nil then
        on_output = function(_, data)
            vim.schedule(function()
                table.insert(result.output, data)
                params.on_output(data)
            end)
        end
    end
    local job = Job:new({
        command = params.command,
        args = args,
        cwd = params.cwd or vim.fn.getcwd(),
        env = params.env or {},
        on_stderr = on_output,
        on_stdout = on_output,
        ---@param _ Job
        ---@param exit_code number
        on_exit = function(_, exit_code)
            result.cmd_code = exit_code
            if params.on_result ~= nil then
                vim.schedule(function()
                    params.on_result(result)
                end)
            end
        end,
    })
    job:start()

    return job
end

return M
