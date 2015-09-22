Dropbox = require("dropbox-fixed")
Promise = require("bluebird")
{ EventEmitter } = require("events")
fs = Promise.promisifyAll require("fs")
_ = require("lodash")

module.exports =

class DropboxApi extends EventEmitter
	constructor: (token) ->
		@BUFFER_SIZE = 1 * 1024 * 1024
		@TIMEOUT = 60000

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

			fs.openAsync(localFile.path, "r").then (fd) =>

				uploadChunk = (cursor, chunk, retry = false) =>
					if not retry
						bytesUploaded = cursor?.offset || 0

						if bytesUploaded < localFile.size
							chunkSize = Math.min @BUFFER_SIZE, localFile.size
							chunk = new Buffer(chunkSize)
							fs.readSync fd, chunk, 0, chunkSize, bytesUploaded
						else
							chunk = null

					if chunk?
						@client.resumableUploadStepAsync(chunk, cursor)
							.timeout @TIMEOUT
							.catch (err) =>
								uploadChunk cursor, chunk, true
							.then (updatedCursor) =>
								@emit "progress", chunk.length
								uploadChunk updatedCursor, chunk
					else
						@client.resumableUploadFinish remotePath, cursor, (err, data) =>
							if err then throw err
							resolve()

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
