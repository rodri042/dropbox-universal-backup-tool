_ = require("lodash")
require("colors")

actions =
	"from": ->
		["to", "token"].forEach (property) =>
			if not config.options[property]?
				throw "Missing param '#{property}'"

	"version": ->
		console.log "1.0.0"
	"help": ->
		options.showHelp()

options = require("node-getopt").create [
	["f", "from=PATH", "Local source path."]
	["t", "to=DROPBOX_PATH", "Dropbox destination path."]
	["s", "simulate", "Only show the changes."]
	["k", "token=TOKEN", "Dropbox token."]
	["v", "version", "Display the version."]
	["h", "help", "Display this help."]
]
options.setHelp(
	"Usage:\n".cyan +
	"node dxubt.js --from=\"/home\" --to=\"/\" --token=blah\n".cyan +
	"\n" +
	"[[OPTIONS]]\n"
)

# run the first action
config = options.parseSystem()
for option of actions
	if config.options[option]?
		try
			actions[option]() ; return
		catch e
			if _.isString e
				console.log "Error: #{e}.".red ; return
			else throw e

# run the default action
actions.help()
