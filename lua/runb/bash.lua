local generic = require "runb.generic"
local util = require "runb.util"
local niew = require "runb.view"

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

---@param args? string | string[]
---@param params? JobParams
---@param await_callback? fun(result: JobResult)
---@return Job
M.run = function(args, params, await_callback)
    args = util.resolve_args(args, M.settings.args)
    params, await_callback = util.resolve_params(params, await_callback)
    params = niew.with_auto_render(params)
    return generic.run(M.settings.command, args, params, await_callback)
end

return M
