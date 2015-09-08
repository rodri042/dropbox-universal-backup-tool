BackupTool = require("./backupTool")
_ = require("lodash")
require("colors")

actions =
	"from": ->
		new BackupTool(config.checkParams("to", "token")).sync()
	"me": ->
		new BackupTool(config.checkParams "token").showInfo()
	"version": ->
		console.log "1.0.0"
	"help": ->
		options.showHelp()

# ------------------------------

options = require("node-getopt").create [
	["f", "from=PATH", "Local source path."]
	["t", "to=DROPBOX_PATH", "Dropbox destination path."]
	["k", "token=TOKEN", "Dropbox token."]
	["s", "simulate", "Only show the changes."]
	["m", "me", "Show the user's Dropbox information."]
	["v", "version", "Display the version."]
	["h", "help", "Display this help."]
]

options.setHelp(
	"Usages:\n".cyan +
	"./dxubt.js --from=\"/home\" --to=\"/\" --token=blah [--simulate]\n".cyan +
	"./dxubt.js --me --token=blah\n".cyan +
	"\n" +
	"[[OPTIONS]]\n"
)

config = options.parseSystem()
config.checkParams = (params...) ->
	params.forEach (property) ->
		if not config.options[property]?
			console.log "Missing param '#{property}'.".red
			process.exit 1
	config.options

# ------------------------------

# run the first or the default action
for option of actions
	if config.options[option]?
		actions[option]() ; return
actions.help()
