local generic = require "runb.generic"

local M = {
    command = "python"
}

---@param args string | string[]
---@param callback? fun(result: any)
---@return Job
function M.run(args, callback)
    if type(args) == "string" then args = { args } end
    return generic.run(M.command, { args = args }, callback)
end

return M
