local Config = require(script.Parent.Config)

local Hello = {}

function Hello.greet(who: string): string
	return string.format("[%s] Hello, %s!", Config.GameName, who)
end

return Hello
