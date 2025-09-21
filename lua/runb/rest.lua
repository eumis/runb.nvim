local util = require "runb.util"
local generic = require "runb.generic"

---@class RestSettings
---@field command string
---@field args? string[]

local M = {
    ---@type RestSettings
    settings = {
        command = "curl"
    }
}

---@param settings SqlSettings
M.setup = function(settings)
    M.settings = settings
end

---@param values table
---@return string[]
function M.H(values)
    local result = {}
    for key, value in pairs(values) do
        table.insert(result, '-H')
        table.insert(result, key .. ':' .. value)
    end
    return result
end

---@param values string[]
---@return table
function M.form(values)
    local inputs = {}
    for key, value in pairs(values) do
        table.insert(inputs, key .. '=' .. value)
    end
    return {
        "-H", "Content-Type:application/x-www-form-urlencoded",
        "-d", table.concat(inputs, "&")
    }
end

---@param values string[]
---@return table
function M.form_url_encoded(values)
    local result = {
        "-H", "Content-Type:application/x-www-form-urlencoded"
    }
    for key, value in pairs(values) do
        table.insert(result, "--data-urlencode")
        table.insert(result, key .. '=' .. value)
    end
    return result
end

---@param values table
---@return table
function M.json(values)
    return {
        "-H", "Content-Type:application/json",
        "-d", vim.json.encode(values)
    }
end

---@param values table
---@return table
function M.query(values)
    local result = { "-G" }
    for key, value in pairs(values) do
        table.insert(result, "--data-urlencode")
        table.insert(result, key .. '=' .. value)
    end
    return result
end

---@param method string
---@param args table
---@param callback? fun(result: any)
---@return Job
function M.curl(method, args, callback)
    local curl_args = { "-X", method }
    util.append(curl_args, util.flatten(args))
    if M.settings.args ~= nil then
        util.append(curl_args, M.settings.args)
    end
    return generic.run(M.settings.command, { args = curl_args, on_result = callback })
end

---@param args table
---@param callback? fun()
function M.get(args, callback)
    M.curl('GET', args, callback)
end

---@param args table
---@param callback? fun(result: any)
function M.post(args, callback)
    M.curl('POST', args, callback)
end

---@param args table
---@param callback? fun(result: any)
function M.put(args, callback)
    M.curl('PUT', args, callback)
end

---@param args table
---@param callback? fun(result: any)
function M.delete(args, callback)
    M.curl('DELETE', args, callback)
end

---@param args table
---@param callback? fun(result: any)
function M.patch(args, callback)
    M.curl('PATCH', args, callback)
end

return M
