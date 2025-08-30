local M = {
    ---@type table<string, table>
    envs = {},
    ---@type string?
    current = nil
}

---@param name string
---@param env table
---@param set_current? boolean
---@return table
M.set = function(name, env, set_current)
    M.envs[name] = env
    if set_current == true then
        M.set_current(name)
    end
    return env
end

---@param name string
---@return table
M.set_current = function(name)
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

---@param env table
---@return table
M.add_system_vars = function(env)
    for k, v in pairs(vim.uv.os_environ()) do
        env[k] = v
    end
    return env
end

return M
