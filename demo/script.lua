local runb = require "runb"
local niew = require "runb.niew"

local env = require("runb.environment").get()

-- view.use_view({
--     tabs = { "api", "python", "bash" },
--     start = view.default.start,
--     append = view.default.append,
--     render = function(result, view_buf, opts)
--         vim.bo[view_buf].filetype = "json"
--         local content = result[opts.tab]
--         view.default.render(content, view_buf, opts)
--     end
-- }, true)

runb.async(function()
    local view = niew.get_view()
    view:set_type("json")
    niew.open_view()

    local result = {}

    local rest_result = runb.await(require "runb.rest".get, {
        env.host .. "/repos/" .. env.repo,
        "-s"
    })
    local info_json = table.concat(rest_result.output, "\n")
    local info = vim.json.decode(info_json)
    env.html_url = info.html_url
    result.api = rest_result.output
    view:render_result(rest_result, { start_line = 0 })

    local py_result = runb.await(require "runb.python".run, vim.fn.expand("test.py"))
    result.python = py_result.output
    env.python_output = py_result.output[2]
    view:render_result(py_result, { start_line = -1 })

    local bash_result = runb.await(require "runb.bash".run, vim.fn.expand("test.sh"))
    result.bash = bash_result.output
    view:render_result(bash_result, { start_line = -1 })
end)
