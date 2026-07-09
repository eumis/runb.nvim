local util = require "runb.util"
local generic = require "runb.generic"
local niew = require "runb.view"

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
---@param await_callback? fun(result: JobResult)
---@return Job
local function run_curl(args, params, await_callback)
    args = util.flatten(args)
    args = util.resolve_args(args, M.settings.args)
    params = niew.with_auto_render(params)
    return generic.run(M.settings.command, args, params, await_callback)
end

---@param args? string | string[]
---@param params? JobParams
---@param await_callback? fun(result: JobResult)
function M.curl(args, params, await_callback)
    args = util.resolve_args(args)
    params, await_callback = util.resolve_params(params, await_callback)
    run_curl(args, params, await_callback)
end

---@param args? string | string[]
---@param params? JobParams
---@param await_callback? fun(result: JobResult)
function M.get(args, params, await_callback)
    args = util.resolve_args(args, { "-X", "GET" })
    params, await_callback = util.resolve_params(params, await_callback)
    run_curl(args, params, await_callback)
end

---@param args? string | string[]
---@param params? JobParams
---@param await_callback? fun(result: JobResult)
function M.post(args, params, await_callback)
    args = util.resolve_args(args, { "-X", "POST" })
    params, await_callback = util.resolve_params(params, await_callback)
    run_curl(args, params, await_callback)
end

---@param args? string | string[]
---@param params? JobParams
---@param await_callback? fun(result: JobResult)
function M.put(args, params, await_callback)
    args = util.resolve_args(args, { "-X", "PUT" })
    params, await_callback = util.resolve_params(params, await_callback)
    run_curl(args, params, await_callback)
end

---@param args? string | string[]
---@param params? JobParams
---@param await_callback? fun(result: JobResult)
function M.delete(args, params, await_callback)
    args = util.resolve_args(args, { "-X", "DELETE" })
    params, await_callback = util.resolve_params(params, await_callback)
    run_curl(args, params, await_callback)
end

---@param args? string | string[]
---@param params? JobParams
---@param await_callback? fun(result: JobResult)
function M.patch(args, params, await_callback)
    args = util.resolve_args(args, { "-X", "PATCH" })
    params, await_callback = util.resolve_params(params, await_callback)
    run_curl(args, params, await_callback)
end

return M
