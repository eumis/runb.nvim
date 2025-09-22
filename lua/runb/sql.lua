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

---@param args string | string[]
---@param callback? fun(result: any)
---@return Job
function M.run(args, callback)
    if type(args) == "string" then args = { args } end
    if M.settings.args ~= nil then
        util.append(args, M.settings.args)
    end
    return generic.run(M.settings.command, { args = args, on_result = callback })
end

return M
