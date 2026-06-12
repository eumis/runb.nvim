local async = require "plenary.async"
local nview = require "runb.niew"
local generic = require "runb.generic"

local M = {
    ---@type {[string]: fun(params: JobParams)}
    runs = {
        lua = function(params)
            params.args = {}
            generic.use_run_params(params)
            dofile(vim.fn.expand("%"))
        end,
        sh = function(params)
            require("runb.bash").run(params)
        end,
        python = function(params)
            require("runb.python").run(params)
        end,
        sql = function(params)
            table.insert(params.args, 1, "-f")
            require("runb.sql").run(params)
        end
    }
}

M.run = function()
    local run_fn = M.runs[vim.bo.filetype]
    if run_fn ~= nil then
        local view = nview.open_view()
        local params = {
            args = { vim.fn.expand("%:p") },
            on_start = function(result)
                view:render_start(result)
            end,
            on_output = function(output, result)
                view:render_progress(output, result)
            end,
            on_result = function(result)
                view:render_start(result)
                view:render_result(result, { start_line = -1 })
            end
        }
        run_fn(params)
    end
end

M.async = function(fun, callback)
    local params = generic.pop_run_params()
    async.run(fun, function() callback(params) end)
end

M.await = function(fun, ...)
    local argc = select("#", ...) + 1
    local wrapped = async.wrap(fun, argc)
    return wrapped(...)
end

vim.api.nvim_create_user_command("Runb", function(_)
    require("runb").run()
end, { nargs = 0 })

vim.api.nvim_create_user_command("RunbNextTab", function(_)
    require("runb.view").next_tab()
end, { nargs = 0 })

vim.api.nvim_create_user_command("RunbPreviousTab", function(_)
    require("runb.view").previous_tab()
end, { nargs = 0 })

vim.api.nvim_create_user_command("RunbEnv", function(opts)
    local env_name = opts.fargs[1]
    if env_name ~= nil then
        require("runb.environment").use(env_name)
    end
end, { nargs = 1 })

return M
