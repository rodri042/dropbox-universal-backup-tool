Dropbox = require("dropbox-fixed")
Promise = require("bluebird")
EventEmitter = require("events").EventEmitter
_ = require("lodash")

module.exports =

class DropboxApi
	constructor: (token) ->
		@client = Promise.promisifyAll new Dropbox.Client { token }
		@events = new EventEmitter()

	readDir: (path, tail = { changes: [] }) =>
		@client.deltaAsync(tail.cursorTag, pathPrefix: path)
			.catch (e) => throw "Error reading the remote directory #{path}."
			.then (delta) =>
				delta.changes = tail.changes.concat delta.changes
				@events.emit "reading", _.sum delta.changes, "stat.size"

				if delta.shouldPullAgain
					@readDir path, delta
				else delta.changes.map (change) =>
					_.assign _.pick(
						change.stat
						"name", "size"
						"isFolder", "isFile", "clientModifiedAt"
					), path: change.path

	stat: (path) =>
		@client.statAsync path

	getAccountInfo: =>
		@client.getAccountInfoAsync()
			.spread (user) => user
			.catch => throw "Error retrieving the user info."
