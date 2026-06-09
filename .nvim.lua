local tasks = require "tasks"
tasks.add("test all", "nvim --headless -c 'PlenaryBustedDirectory lua/tests'")
tasks.add("test current file", function(bufnr)
    return "nvim --headless -c 'PlenaryBustedFile " .. vim.fn.expand("#" .. bufnr) .. "'"
end)

tasks.add("deploy",
    { "rm -rf /home/em/.local/share/nvim/lazy/runb.nvim", "cp -rf runb.nvim /home/em/.local/share/nvim/lazy/" },
    { cwd = ".." })
