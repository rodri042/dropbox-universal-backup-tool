Dropbox = require("dropbox-fixed")
Promise = require("bluebird")
{ EventEmitter } = require("events")
fs = Promise.promisifyAll require("fs")
_ = require("lodash")

module.exports =

class DropboxApi extends EventEmitter
	constructor: (token) ->
		@BUFFER_SIZE = 1 * 1024 * 1024
		@TIMEOUT = 120000

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
		if localFile.size is 0
			return @client.writeFileAsync remotePath, new Buffer(0)

		new Promise (resolve, reject) =>
			fd = fs.openSync localFile.path, "r"
			if not fd? then return reject "Unable to open the file"

			chunk = new Buffer(@BUFFER_SIZE)
			uploadChunk = (cursor, isRetry = false) =>
				bytesUploaded = cursor?.offset || 0
				pendingBytes = localFile.size - bytesUploaded
				hasPendingBytes = pendingBytes > 0

				if hasPendingBytes
					if not isRetry
						chunkSize = Math.min @BUFFER_SIZE, pendingBytes
						chunk = chunk.slice 0, chunkSize
						fs.readSync fd, chunk, 0, chunkSize

					@client.resumableUploadStepAsync(chunk, cursor)
						.timeout @TIMEOUT
						.catch (err) =>
							uploadChunk cursor, true
						.then (updatedCursor) =>
							@emit "progress", chunk.length
							uploadChunk updatedCursor
				else
					@client.resumableUploadFinish remotePath, cursor, (err, data) =>
						fs.closeSync fd
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
