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

---@param params? JobParams
---@return Job
function M.curl(params)
    params = generic.get_run_params(params)
    params.args = util.flatten(params.args)
    if M.settings.args ~= nil then
        util.append(params.args, M.settings.args)
    end
    return generic.run(M.settings.command, params)
end

---@param method string
---@param args table
---@param params? JobParams
---@return JobParams
local function get_curl_params(method, args, params)
    print("curl " .. vim.inspect(params))
    params = generic.get_run_params(params)
    util.append(args, { "-X", method })
    util.append(args, params.args)
    params.args = args
    return params
end

---@param args table
---@param params? JobParams
function M.get(args, params)
    print("get " .. vim.inspect(params))
    params = get_curl_params("GET", args, params)
    M.curl(params)
end

---@param args table
---@param params? JobParams
function M.post(args, params)
    M.curl(get_curl_params("POST", args, params))
end

---@param args table
---@param params? JobParams
function M.put(args, params)
    M.curl(get_curl_params("PUT", args, params))
end

---@param args table
---@param params? JobParams
function M.delete(args, params)
    M.curl(get_curl_params("DELETE", args, params))
end

---@param args table
---@param params? JobParams
function M.patch(args, params)
    M.curl(get_curl_params("PATCH", args, params))
end

return M
