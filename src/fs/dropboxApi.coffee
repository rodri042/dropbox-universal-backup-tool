DropboxResumableUpload = require("./dropboxResumableUpload")
Dropbox = require("dropbox-fixed")
Promise = require("bluebird")
{ EventEmitter } = require("events")
fs = Promise.promisifyAll require("fs")
request = Promise.promisifyAll require("request")
_ = require("lodash")

module.exports =

class DropboxApi extends EventEmitter
	constructor: (@token) ->
		@client = Promise.promisifyAll new Dropbox.Client { @token }
		@URL = "https://api.dropboxapi.com/2/"

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

		new DropboxResumableUpload(localFile, remotePath, @client)
			.run (progress) =>
				@emit "progress", progress

	deleteFile: (path) =>
		@client.deleteAsync path

	moveFile: (oldPath, newPath) =>
		@client.moveAsync oldPath, newPath

	getAccountInfo: =>
		@_doRequest "users/get_current_account"
			.catch => throw "Error retrieving the user info."

	_makeStats: (path, stats) =>
		_.assign _.pick(
			stats, "path", "name", "size"
		), path: stats.path.replace path, ""

	_doRequest: (url, body) =>
		options =
			auth: bearer: @token
			url: "#{@URL}/#{url}"
			body: body
			json: true

		request.postAsync(options).spread ({ statusCode, body }) =>
			success = /2../.test statusCode
			if not success then throw body
			body
