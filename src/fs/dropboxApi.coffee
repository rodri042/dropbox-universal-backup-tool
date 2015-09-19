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
		new Promise (resolve, reject) ->
			stream = fs.createReadStream localFile.path

			cursor = null
			bytesUploaded = 0

			stream.on "data", (chunk) =>
				bytesUploaded += chunk.length
				console.log "Subí #{bytesUploaded} bytes..."

				uploadChunk = (err, updatedCursor) =>
					# chequear err y reintentar con el cursor
					cursor = updatedCursor

					@resumableUploadStepAsync chunk, cursor

			stream.on "end", =>
				@resumableUploadFinish remotePath, cursor, (err, data) =>
					console.log "ahí ta viteh", data

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
