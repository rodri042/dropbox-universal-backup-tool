Promise = require("bluebird")
{ EventEmitter } = require("events")
fs = require("fs")
_ = require("lodash")

module.exports =

class DropboxResumableUpload extends EventEmitter
	constructor: (@localFile, @remotePath, @request) ->
		@BUFFER_SIZE = 1 * 1024 * 1024
		@TIMEOUT = 120000

	run: (onProgress) =>
		new Promise (resolve) =>
			@_initialize()
			@_uploadChunk @_getCursor()

			@on "chunk-ok", (progress) ->
				onProgress progress
				@_uploadChunk @_getCursor()

			@on "chunk-error", ->
				@_uploadChunk @_getCursor(), true

			@on "complete", ->
				@_dispose() ; resolve()

	pendingBytes: =>
		@localFile.size - @uploadedBytes

	_getCursor: => @cursor

	_uploadChunk: (cursor, isRetry) =>
		if @pendingBytes() > 0
			if not isRetry
				bytesToRead = @_trimChunkIfNeeded()
				fs.readSync @fd, @chunk, 0, bytesToRead

			return @client.resumableUploadStepAsync(@chunk, @cursor)
				.timeout @TIMEOUT
				.catch => @emit "chunk-error"
				.then (cursor) =>
					if _.isObject cursor then @cursor = cursor
					@uploadedBytes += @chunk.length
					@emit "chunk-ok", @chunk.length

		@client.resumableUploadFinishAsync(@remotePath, @cursor).finally =>
			@emit "complete"

	_initialize: =>
		@fd = fs.openSync @localFile.path, "r"
		if not @fd? then throw "Unable to open the file"

		@uploadedBytes = 0
		@chunk = new Buffer(@BUFFER_SIZE)
		@cursor = null

	_trimChunkIfNeeded: =>
		chunkSize = Math.min @pendingBytes(), @BUFFER_SIZE
		if @pendingBytes() < @BUFFER_SIZE
			@chunk = @chunk.slice 0, chunkSize
		chunkSize

	_dispose: =>
		fs.closeSync @fd
