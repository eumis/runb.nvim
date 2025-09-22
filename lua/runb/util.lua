local M = {}

---@param list any[]
---@param values any[]
M.append = function(list, values)
    for _, value in ipairs(values) do
        table.insert(list, value)
    end
end

---@param list any[]
---@return any[]
M.flatten = function(list)
    local result = {}
    for _, item in ipairs(list) do
        if type(item) == 'table' then
            M.append(result, item)
        else
            table.insert(result, item)
        end
    end
    return result
end

---@param list any[]
---@param value any
---@return integer?
M.index = function(list, value)
    for index, item in ipairs(list) do
        if item == value then
            return index
        end
    end
    return nil
end

---@param list any[]
---@param cond fun(i:integer, value: any):boolean
---@param callback fun(i:integer, value: any)
M.for_each = function(list, cond, callback)
    for i, value in ipairs(list) do
        if cond(i, value) then
            callback(i, value)
        end
    end
end

---@param list any[]
---@param n integer
M.take = function(list, n)
    local result = {}
    for i, value in ipairs(list) do
        if i <= n then
            table.insert(result, value)
        end
    end
    return result
end

---@param list any[]
---@param n integer
M.skip = function(list, n)
    local result = {}
    for i, value in ipairs(list) do
        if i > n then
            table.insert(result, value)
        end
    end
    return result
end

---@param s string
---@param delimiter string
M.split = function(s, delimiter)
    local result = {}
    for part in string.gmatch(s, "([^" .. delimiter .. "]+)") do
        table.insert(result, part)
    end
    return result
end

---@param value? boolean
---@param default? boolean
---@return boolean
M.bool = function(value, default)
    if value == nil then
        return default == nil or default
    end
    return value
end

return M
