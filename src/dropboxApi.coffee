Dropbox = require("dropbox")
Promise = require("bluebird")
EventEmitter = require("events").EventEmitter
_ = require("lodash")

module.exports =

class DropboxApi
	constructor: (token) ->
		@client = Promise.promisifyAll new Dropbox.Client { token }
		@events = new EventEmitter()

	readDir: (path) =>
		@events.emit "resolving", path
		@client.readdirAsync(path)
			.catch => throw "Error reading the directory #{path}."
			.spread (__, ___, entries) =>
				files = _.reject entries, "isFolder"
				folders = _.filter entries, "isFolder"

				promises = folders.map (entry) => @readDir entry.path

				Promise.all(promises).then (foldersContent) =>
					@events.emit "resolved", path
					_.flatten folders.concat(files).concat(foldersContent)

	getAccountInfo: =>
		@client.getAccountInfoAsync()
			.spread (user) => user
			.catch => throw "Error retrieving the user info."
