# runb.nvim

Runs current buffer and shows output in split buffer.
Rest client in lua for neovim.

## Installation

- neovim 0.10.0+ required
- install using your favorite plugin manager

[lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
    "eumis/runb.nvim", 
    dependencies = { "nvim-lua/plenary.nvim" }
}
```

[mini.deps](https://github.com/echasnovski/mini.nvim/blob/main/readmes/mini-deps.md)

```lua
add({
    source = "eumis/runb.nvim",
    depends = { "nvim-lua/plenary.nvim" },
})
```

[packer](https://github.com/wbthomason/packer.nvim)

```lua
use {
    "eumis/runb.nvim",
    requires = { {"nvim-lua/plenary.nvim"} }
}
```

## Usage

```lua
vim.keymap.set("n", "<leader>asdf", function() require("runb").run() end)
```

```vim
:Runb
```

### Environments

```lua
local environment = require "runb.environment"
--add environment
environment.set("test", {
    github_host = "https://api.github.com"
})

--get environment
local env = environment.get("test")

--use current environment
environment.use("test")

--get current environment
env = environment.get()
```

### Rest

Uses `curl` to execute http request

```lua
local environment = require "runb.environment"
local env = environment.get()
local rest = require "runb.rest"

-- curl -X GET https://api.github.com/repos/eumis/runb.nvim -i
rest.get {
    env.github_host .. "/repos/eumis/runb.nvim",
    "-i"
}
```

```lua use query
-- -G --data-urlencode property=value
rest.get {
    "http://localhost",
    rest.query {
        property = "value"
    }
}
```

```lua use headers
-- -H key:value
rest.get {
    "http://localhost",
    rest.H {
        key = "value"
    }
}
```

```lua use form
-- -H Content-Type:application/x-www-form-urlencoded -d property=value
rest.post {
    "http://localhost",
    rest.form {
        property = "value"
    }
}
```

```lua use urlencoded form data
-- -H Content-Type:application/x-www-form-urlencoded --data-urlencode property=value
rest.put {
    "http://localhost",
    rest.form_url_encoded {
        property = "value"
    }
}
```

```lua use json data
-- -H Content-Type:application/json -d {"property":"value"}
rest.patch {
    "http://localhost",
    rest.json {
        property = "value"
    }
}
```

```lua use arguments for every request
rest.use_args({ "-i" })
-- curl -X GET https://api.github.com/repos/eumis/runb.nvim -i
rest.get {
    env.github_host .. "/repos/eumis/runb.nvim"
}
```

### Python

```lua
local environment = require "runb.environment"
environment.set("test", {
    env_key = "value"
}, true)
```

```python
import os

print(os.getenv("env_key"))
```

### Bash

```lua
local environment = require "runb.environment"
environment.set("test", {
    env_key = "value"
}, true)
```

```bash
#!/bin/bash

echo $env_key
```

### Async/await

```lua
local runb = requie "runb"

runb.async(function()
    local result = {}

    local rest_result = runb.await(require "runb.rest".get, {
        "https://api.github.com/repos/eumis/runb.nvim",
        "-s"
    })
end)
```

### Demo

[Demo](demo/README.md)
