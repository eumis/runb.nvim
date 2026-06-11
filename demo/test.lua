local env = require "runb.environment".get()

require "runb.rest".get {
    env.host .. "/repos/" .. env.repo,
    "-s"
}
