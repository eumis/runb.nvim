require "runb.python".settings.command = "python3"

local environment = require "runb.environment"

environment.set("default", {
    host = "https://api.github.com",
    repo = "eumis/runb.nvim",
    name = "default"
}, true)

environment.envs["wdconfig"] = {
    host = "https://api.github.com",
    repo = "eumis/wdconfig.nvim",
    name = "wdconfig"
}

environment.set("tasks", {
    host = "https://api.github.com",
    repo = "eumis/tasks.nvim",
    name = "tasks"
})

environment.use("default")
