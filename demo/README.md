# Demo

Before runnint any file, you have to run `:source %` in config.lua.
It will set up environments for demo. This can be done in your own neovim config.

Try to run every file with `:Runb` command.
To change environemnt to "wdconfig" run `:RunbEnv wdconfig` command

- script to setup environments. should be run before running demo files
    [config.lua](demo/config.lua)
- python script to run
    [test.py](demo/test.py)
- bash script to run
    [bash.py](demo/bash.py)
- lua script to call rest api
    [test.lua](demo/test.lua)
- async script to chain runs
    [script.lua](demo/script.lua)

