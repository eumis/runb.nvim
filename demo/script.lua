local runb = require "runb"
local view = require "runb.view"

local env = require("runb.environment").get()

view.use_view({
    tabs = { "api", "python", "bash" },
    start = view.default.start,
    append = view.default.append,
    render = function(result, view_buf, opts)
        vim.bo[view_buf].filetype = "json"
        local content = result[opts.tab]
        view.default.render(content, view_buf, opts)
    end
}, true)

runb.async(function()
    local result = {}

    local rest_result = runb.await(require "runb.rest".get, {
        env.host .. "/repos/" .. env.repo,
        "-s"
    })
    local info_json = table.concat(rest_result.output, "\n")
    local info = vim.json.decode(info_json)
    env.html_url = info.html_url
    result.api = rest_result.output
    view.render(result, { tab = "api" })

    local py_result = runb.await(require "runb.python".run, vim.fn.expand("demo/test.py"))
    result.python = py_result.output
    env.python_output = py_result.output[2]
    view.render(result, { tab = "python" })

    local bash_result = runb.await(require "runb.bash".run, { vim.fn.expand("demo/test.sh"), "arg" })
    result.bash = bash_result.output
    view.render(result, { tab = "bash" })
end)
