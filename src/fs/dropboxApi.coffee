DropboxResumableUpload = require("./dropboxResumableUpload")
Promise = require("bluebird")
{ EventEmitter } = require("events")
fs = Promise.promisifyAll require("fs")
request = Promise.promisifyAll require("request")
moment = require("moment")
_ = require("lodash")

module.exports =

class DropboxApi extends EventEmitter
	constructor: (@token) ->
		@URL = "https://$type.dropboxapi.com/2"

	readDir: (path, tail) =>
		path = path.toLowerCase()

		req =
			if tail?
				@request "files/list_folder/continue", { cursor: tail.cursor }
			else
				@request "files/list_folder", { path: path, recursive: true }

		req
			.catch => throw "Error reading the remote directory #{path}."
			.then (chunk) =>
				cursor = chunk.cursor
				entries = (tail?.entries || []).concat chunk.entries
				@emit "reading", entries.length

				if chunk.has_more
					@readDir path, { cursor, entries }
				else
					_(entries)
						.filter ".tag": "file"
						.map (stats) => @_makeStats path, stats
						.value()

	uploadFile: (localFile, remotePath) =>
		if localFile.size is 0
			@request "files/upload", "", @_makeSaveOptions(localFile, remotePath)
		else
			new DropboxResumableUpload(localFile, remotePath, @)
				.run (progress) =>
					@emit "progress", progress

	deleteFile: (path) =>
		process.exit 8
		#@client.deleteAsync path

	moveFile: (oldPath, newPath) =>
		process.exit 8
		#@client.moveAsync oldPath, newPath

	getAccountInfo: =>
		@request "users/get_current_account"
			.catch => throw "Error retrieving the user info."

	request: (url, body, header) =>
		isBinary = header?
		if _.isEmpty header
			header = undefined

		baseUrl = @URL.replace "$type", (if isBinary then "content" else "api")
		options =
			auth: bearer: @token
			headers:
				if isBinary
					"Content-Type": "application/octet-stream"
					"Dropbox-API-Arg": JSON.stringify(header)
			url: "#{baseUrl}/#{url}"
			body: body
			json: not isBinary

		request.postAsync(options).then ({ statusCode, body }) =>
			success = /2../.test statusCode
			if not success
				throw new Error(body.error_summary || body.error || body)
			if isBinary then JSON.parse(body) else body

	_makeStats: (path, stats) =>
		path: stats.path_lower.replace path, ""
		name: stats.name
		size: stats.size
		mtime: new Date(stats.client_modified).setMilliseconds 0

	_makeSaveOptions: (localFile, remotePath) =>
		path: remotePath
		mode: "overwrite"
		client_modified: moment(localFile.mtime).format("YYYY-MM-DDTHH:mm:ss") + "Z"
		mute: true
