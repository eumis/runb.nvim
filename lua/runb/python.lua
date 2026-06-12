local generic = require "runb.generic"
local util = require "runb.util"

---@class PythonSettings
---@field command string
---@field args? string[]

local M = {
    ---@type PythonSettings
    settings = {
        command = "python"
    }
}

---@param settings PythonSettings
M.setup = function(settings)
    M.settings = settings
end

---@param args? string | string[]
---@param params? JobParams
---@param callback? fun(result: JobResult)
---@return Job
M.run = function(args, params, callback)
    args = generic.resolve_args(args)
    if M.settings.args ~= nil then
        util.append(args, M.settings.args)
    end
    params = generic.resolve_params(params, callback)
    return generic.run(M.settings.command, args, params)
end

return M
