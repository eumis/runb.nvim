local util = require "runb.util"
local view = require "runb.view"
local job = require "runb.job"

local M = {
    type = "rest"
}

local settings = {
    args = nil
}

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

---@param args? table
function M.use_args(args)
    settings.args = args
end

---@param method string
---@param args table
---@param callback? fun(result: any)
---@return Job
function M.curl(method, args, callback)
    local curl_args = { "-X", method }
    util.append(curl_args, util.flatten(args))
    if settings.args ~= nil then
        util.append(curl_args, settings.args)
    end
    local on_output = nil
    local on_result = callback
    if callback == nil then
        local source_buf = vim.api.nvim_get_current_buf()
        view.render("Running...", { source_buf = source_buf })
        on_output = function(data)
            view.render(data, { source_buf = source_buf, append = true })
        end
        on_result = function(result)
            view.render(result.input, { source_buf = source_buf, rendering = M.view_rendering })
            view.render(result.output, { source_buf = source_buf, rendering = M.view_rendering, append = true })
        end
    end
    return job.run({
        command = "curl",
        args = curl_args,
        on_output = on_output,
        on_result = on_result
    })
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

---@type ViewRendering
M.view_rendering = {
    render = function(result, view_buf, opts)
        view.view_rendering.render(result, view_buf, opts)
    end
}

return M
