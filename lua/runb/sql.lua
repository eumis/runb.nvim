local generic = require "runb.generic"
local util = require "runb.util"
local niew = require "runb.view"

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

---@param args? string | string[]
---@param params? JobParams
---@param await_callback? fun(result: JobResult)
---@return Job
function M.run(args, params, await_callback)
    args = util.resolve_args(args, M.settings.args)
    params, await_callback = util.resolve_params(params, await_callback)
    params = niew.with_auto_render(params)
    return generic.run(M.settings.command, args, params, await_callback)
end

return M
