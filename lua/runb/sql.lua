local generic = require "runb.generic"

local M = {
    command = "usql",
    connection = ""
}

---@param args string | string[]
---@param callback? fun(result: any)
---@return Job
function M.run(args, callback)
    if type(args) == "string" then args = { args } end
    return generic.run(M.command, { command_args = args }, callback)
end

return M
