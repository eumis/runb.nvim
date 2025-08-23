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

return M
