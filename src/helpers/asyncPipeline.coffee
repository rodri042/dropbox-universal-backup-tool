Promise = require("bluebird")

module.exports = (actions) ->
	pipeline = (previous, upload) => previous.finally upload
	actions.reduce pipeline, Promise.resolve()
