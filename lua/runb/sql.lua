local generic = require "runb.generic"
local util = require "runb.util"

---@class SqlSettings
---@field command string
---@field args? string[]

local M = {
    ---@type SqlSettings
    settings = {
        command = "usql"
    }
}

---@param settings SqlSettings
M.setup = function(settings)
    M.settings = settings
end

---@param params? JobParams
---@return Job
function M.run(params)
    params = generic.get_run_params(params)
    if M.settings.args ~= nil then
        util.append(params.args, M.settings.args)
    end
    return generic.run(M.settings.command, params)
end

return M
