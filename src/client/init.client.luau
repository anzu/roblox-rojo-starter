-- Client bootstrap. Prints once for each player when their scripts load.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Hello = require(ReplicatedStorage.Shared.Hello)
local Players = game:GetService("Players")

local player = Players.LocalPlayer
print(Hello.greet(player and player.Name or "client"))
