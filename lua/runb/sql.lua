local generic = require "runb.generic"

local M = {
    command = "usql",
    connection = nil
}

---@param args string | string[]
---@param callback? fun(result: any)
---@return Job
function M.run(args, callback)
    if type(args) == "string" then
        args = { args }
    elseif args == nil then
        args = {}
    end
    if M.connection ~= nil then
        table.insert(args, 1, M.connection)
    end
    return generic.run(M.command, { args = args }, callback)
end

return M
