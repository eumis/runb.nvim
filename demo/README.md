# Demo

Before runnint any file, you have to run `:source %` in config.lua.
It will set up environments for demo. This can be done in your own neovim config.

Try to run every file with `:Runb` command.
To change environemnt to "wdconfig" run `:RunbEnv wdconfig` command

- script to setup environments. should be run before running demo files
    [config.lua](config.lua)
- python script to run
    [test.py](test.py)
- bash script to run
    [test.sh](test.sh)
- lua script to call rest api
    [test.lua](test.lua)
- async script to chain runs
    [script.lua](script.lua)
