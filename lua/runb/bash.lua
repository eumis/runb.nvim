local generic = require "runb.generic"
local util = require "runb.util"

---@class BashSettings
---@field command string
---@field args? string[]

local M = {
    ---@type BashSettings
    settings = {
        command = "bash"
    }
}

---@param settings BashSettings
M.setup = function(settings)
    M.settings = settings
end

---@param params? JobParams
---@param callback? fun(result: JobResult)
---@return Job
M.run = function(params, callback)
    params = generic.get_run_params(params, callback)
    if M.settings.args ~= nil then
        util.append(params.args, M.settings.args)
    end
    return generic.run(M.settings.command, params)
end

return M
