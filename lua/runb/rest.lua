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

---@param args string[]
---@param params JobParams
---@return Job
local function run_curl(args, params)
    if M.settings.args ~= nil then
        util.append(args, M.settings.args)
    end
    args = util.flatten(args)
    if M.settings.args ~= nil then
        util.append(args, M.settings.args)
    end
    return generic.run(M.settings.command, args, params)
end

---@param method string
---@param args? string | string[]
---@return JobParams
local function get_method_args(method, args)
    args = generic.resolve_args(args)
    util.append(args, { "-X", method })
    return args
end

---@param args? string | string[]
---@param params? JobParams
---@param callback? fun(result: JobResult)
function M.curl(args, params, callback)
    args = generic.resolve_args(args)
    params = generic.resolve_params(params, callback)
    run_curl(args, params)
end

---@param args? string | string[]
---@param params? JobParams
---@param callback? fun(result: JobResult)
function M.get(args, params, callback)
    args = get_method_args("GET", args)
    params = generic.resolve_params(params, callback)
    run_curl(args, params)
end

---@param args? string | string[]
---@param callback? fun(result: JobResult)
---@param params? JobParams
function M.post(args, params, callback)
    args = get_method_args("POST", args)
    params = generic.resolve_params(params, callback)
    run_curl(args, params)
end

---@param args? string | string[]
---@param callback? fun(result: JobResult)
---@param params? JobParams
function M.put(args, params, callback)
    args = get_method_args("PUT", args)
    params = generic.resolve_params(params, callback)
    run_curl(args, params)
end

---@param args? string | string[]
---@param callback? fun(result: JobResult)
---@param params? JobParams
function M.delete(args, params, callback)
    args = get_method_args("DELETE", args)
    params = generic.resolve_params(params, callback)
    run_curl(args, params)
end

---@param args? string | string[]
---@param callback? fun(result: JobResult)
---@param params? JobParams
function M.patch(args, params, callback)
    args = get_method_args("PATCH", args)
    params = generic.resolve_params(params, callback)
    run_curl(args, params)
end

return M
