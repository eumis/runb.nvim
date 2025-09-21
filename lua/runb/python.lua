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

---@param args string | string[]
---@param callback? fun(result: JobResult)
---@return Job
M.run = function(args, callback)
    if type(args) == "string" then args = { args } end
    if M.settings.args ~= nil then
        util.append(args, M.settings.args)
    end
    return generic.run(M.settings.command, { args = args, on_result = callback })
end

return M
