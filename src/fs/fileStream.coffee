Promise = require("bluebird")
EventEmitter2 = require("eventemitter2").EventEmitter2
fs = require("fs")

module.exports =

class FileStream
	constructor: (path) ->
		@BUFFER_SIZE = 3 * 1024 * 1024

		@stream = fs.createReadStream path, highWatermark: @BUFFER_SIZE
		@events = new EventEmitter2()

		@ready = false
		@stream.on "readable", @_canRead

	whenReady: (action) =>
		if @ready then return action()
		@events.once "ready", action

	read: =>
		readed = @stream.read()

	_canRead: =>
		@ready = true
		@events.emit "ready"
		@stream.removeAllListeners "readable"
