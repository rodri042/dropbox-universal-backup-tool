Cli = require("./cli")
PrettyError = require("pretty-error")
isPromise = require("is-promise")
_ = require("lodash")
require("colors")

actions =
	"me": ->
		new Cli(config.checkParams "token").showInfo()
	"from": ->
		new Cli(config.checkParams("to", "token")).getFilesAndSync()
	"version": ->
		console.log "1.0.0"
	"help": ->
		options.showHelp()

# ------------------------------

options = require("node-getopt").create [
	["f", "from=PATH", "Local source path."]
	["t", "to=DROPBOX_PATH", "Dropbox destination path."]
	["k", "token=TOKEN", "Dropbox token."]
	["y", "yes", "Don't review changes before the sync."]
	["m", "me", "Show the user's Dropbox information."]
	["d", "debug", "Show detailed traces for debugging."]
	["v", "version", "Display the version."]
	["h", "help", "Display this help."]
]

options.setHelp(
	"Usages:\n".cyan +
	"./dxubt.js --from=\"/home\" --to=\"/\" --token=blah [--yes]\n".cyan +
	"./dxubt.js --me --token=blah\n".cyan +
	"\n" +
	"[[OPTIONS]]".white
)

config = options.parseSystem()
config.checkParams = (params...) ->
	params.forEach (property) ->
		if not config.options[property]?
			console.log "Missing param '#{property}'.".red
			process.exit 1
	config.options

# ------------------------------

# handle errors more pretty
if not config.options.debug
	new PrettyError().start()
	Error.stackTraceLimit = 3

# run the first or the default action
for option of actions
	if config.options[option]?
		actions[option]()
		return

actions.help()
