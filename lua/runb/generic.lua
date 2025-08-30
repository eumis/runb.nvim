local view = require "runb.view"
local job = require "runb.job"
local environment = require "runb.environment"

local M = {}

---@class GenericParams
---@field command_args? string[]

---@param command string
---@param params GenericParams
---@param callback? fun(result: any)
---@return Job
function M.run(command, params, callback)
    local on_output = nil
    local on_result = callback
    if callback == nil then
        local source_buf = vim.api.nvim_get_current_buf()
        view.render("Running...", { source_buf = source_buf })
        on_output = function(data)
            view.render(data, { source_buf = source_buf, append = true })
        end
        on_result = function(result)
            view.render(result.input, { source_buf = source_buf })
            view.render(result.output, { source_buf = source_buf, append = true })
        end
    end
    return job.run({
        command = command,
        args = params.command_args,
        env = environment.get(),
        on_output = on_output,
        on_result = on_result
    })
end

return M
