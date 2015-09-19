Dropbox = require("dropbox-fixed")
Promise = require("bluebird")
{ EventEmitter } = require("events")
fs = require("fs")
_ = require("lodash")

module.exports =

class DropboxApi extends EventEmitter
	constructor: (token) ->
		@client = Promise.promisifyAll new Dropbox.Client { token }

	readDir: (path, tail = { changes: [] }) =>
		path = path.toLowerCase()
		@client.deltaAsync(tail.cursorTag, pathPrefix: path)
			.catch (e) => throw "Error reading the remote directory #{path}."
			.then (delta) =>
				delta.changes = tail.changes.concat delta.changes
				@emit "reading", _.sum delta.changes, "stat.size"

				if delta.shouldPullAgain
					@readDir path, delta
				else
					_(delta.changes)
						.map (change) => change.stat
						.filter isFile: true
						.map (stats) => @_makeStats path, stats
						.value()

	uploadFile: (localFile, remotePath) =>
		new Promise (resolve, reject) =>
			stream = fs.createReadStream localFile.path

			cursor = null
			chunk = null
			bytesUploaded = 0

			uploadChunk = (err, updatedCursor) =>
				cursor = updatedCursor

				waitForData = =>
					console.log "ahí esperé"
					stream.removeListener "readable", arguments.callee

					console.log "jeje"
					if not err?
						chunk = stream.read()
					else
						console.log "HUBO UN ERROR, vuelvo a intentar"

					if chunk?
						@client.resumableUploadStep chunk, cursor, (err, data) =>
							bytesUploaded += chunk.length
							console.log "Subí #{bytesUploaded} bytes..."
							console.log "más bytes, sigo"
							uploadChunk err, data
					else
						@client.resumableUploadFinish remotePath, cursor, (err, data) =>
							console.log "ahí ta viteh"
							resolve()

				console.log "vamo a esperar por datos"
				stream.on "readable", waitForData
				console.log "no pasa nada :("
				console.log stream

			uploadChunk null

	deleteFile: (path) =>
		@client.deleteAsync path

	moveFile: (oldPath, newPath) =>
		@client.moveAsync oldPath, newPath

	getAccountInfo: =>
		@client.getAccountInfoAsync()
			.spread (user) => user
			.catch => throw "Error retrieving the user info."

	_makeStats: (path, stats) =>
		_.assign _.pick(
			stats, "path", "name", "size"
		), path: stats.path.replace path, ""
