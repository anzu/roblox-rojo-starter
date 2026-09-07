-- Server bootstrap. Prints once when the server starts (Play in Studio).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Hello = require(ReplicatedStorage.Shared.Hello)

print(Hello.greet("server"))
