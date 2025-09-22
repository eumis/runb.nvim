local M = {
    ---@type table<string, table>
    envs = {},
    ---@type string?
    current = nil,
    ---@type fun(env: table):table
    job_env_transform = nil
}

---@param name string
---@param env table
---@param set_current? boolean
---@return table
M.set = function(name, env, set_current)
    M.envs[name] = env
    if set_current == true then
        M.use(name)
    end
    return env
end

---@param name string
---@return table
M.use = function(name)
    M.current = name
    vim.api.nvim_exec_autocmds("User", {
        pattern = "RunbEnvChanged",
        data = { name = name },
    })
    return M.get(name)
end

---@param name? string
---@return table
M.get = function(name)
    if name == nil then
        name = M.current
    end
    return M.envs[name]
end

---@type fun(name?:string):table
M.get_job_env = M.get

return M
