Dropbox = require("dropbox-fixed")
Promise = require("bluebird")
{ EventEmitter } = require("events")
fs = require("fs")
_ = require("lodash")

module.exports =

class DropboxApi extends EventEmitter
	constructor: (token) ->
		@BUFFER_SIZE = 10 * 1024 * 1024
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
			stream = fs.createReadStream localFile.path, bufferSize: @BUFFER_SIZE

			cursor = null
			chunk = null
			ready = Promise.pending()
			canRead = => ready.resolve()
			bytesUploaded = 0

			uploadChunk = (err, updatedCursor) =>
				cursor = updatedCursor

				ready.promise.then =>
					ready = Promise.pending()

					if not err?
						chunk = stream.read()
					else
						console.log "HUBO UN ERROR, vuelvo a intentar"

					if chunk?
						@client.resumableUploadStep chunk, cursor, (err, data) =>
							bytesUploaded += chunk.length
							console.log "Subí #{bytesUploaded} bytes..."
							uploadChunk err, data
					else
						@client.resumableUploadFinish remotePath, cursor, (err, data) =>
							stream.removeAllListeners "readable"
							stream.removeAllListeners "end"
							if err then throw err
							console.log "ahí ta viteh"
							resolve()

			stream.on "readable", canRead
			stream.on "end", canRead
			uploadChunk()

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
