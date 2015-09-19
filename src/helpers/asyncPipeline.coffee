Promise = require("bluebird")
require("colors")

module.exports = (actions) ->
	pipeline = (previous, upload) =>
		previous.catch (e) => console.log "#{e}".red
		previous.finally upload
	actions.reduce pipeline, Promise.resolve()
