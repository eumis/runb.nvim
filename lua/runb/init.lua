local async = require "plenary.async"

local M = {}

function M.run()
    if vim.bo.filetype == "lua" then
        dofile(vim.fn.expand("%"))
    elseif vim.bo.filetype == "sh" then
        require("runb.bash").run(vim.fn.expand("%:p"))
    elseif vim.bo.filetype == "python" then
        require("runb.python").run(vim.fn.expand("%:p"))
    elseif vim.bo.filetype == "sql" then
        require("runb.sql").run({"-f", vim.fn.expand("%:p")})
    end
end

function M.async(fun, callback)
    async.run(fun, callback)
end

function M.await(fun, ...)
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
        require("runb.environment").set_current(env_name)
    end
end, { nargs = 1 })

return M
