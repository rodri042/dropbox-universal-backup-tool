Promise = require("bluebird")
asyncQueue = require("async/queue")
_ = require("lodash");
require("colors")

module.exports = (actions, concurrency) ->
	return Promise.resolve() if _.isEmpty actions

	new Promise (resolve) ->
		queue = asyncQueue((action, done) ->
			promise = action()
			promise.catch (e) -> console.log "#{e}".red
			promise.finally done
		, concurrency)

		actions.forEach (it) -> queue.push it
		queue.drain resolve
