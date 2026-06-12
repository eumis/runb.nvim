local async = require "plenary.async"
local nview = require "runb.niew"
local generic = require "runb.generic"

local M = {
    ---@type {[string]: fun()}
    runs = {
        lua = function()
            dofile(vim.fn.expand("%"))
        end,
        sh = function()
            require("runb.bash").run(vim.fn.expand("%:p"))
        end,
        python = function()
            require("runb.python").run(vim.fn.expand("%:p"))
        end,
        sql = function()
            require("runb.sql").run({ "-f", vim.fn.expand("%:p") })
        end
    }
}

M.run = function()
    local run_fn = M.runs[vim.bo.filetype]
    if run_fn ~= nil then
        local view = nview.open_view()
        generic.use_params {
            on_start = function(result)
                view:render_start(result)
            end,
            on_output = function(output, result)
                view:render_progress(output, result)
            end,
            on_result = function(result)
                view:render_start(result)
                view:render_result(result)
            end
        }
        run_fn()
    end
end

M.async = function(fun, callback)
    async.run(function()
        local params = generic.pop_params()
        fun(params)
    end, function()
        generic.pop_params()
        if callback ~= nil then callback() end
    end)
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
