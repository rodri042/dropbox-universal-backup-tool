Dropbox = require("dropbox")
Promise = require("bluebird")

module.exports =

class DropboxApi
	constructor: (token) ->
		@client = Promise.promisifyAll new Dropbox.Client { token }

	readDir: (path) =>
		@client.readdirAsync(path)
			.catch => throw "Error reading the directory #{path}."

	getAccountInfo: =>
		@client.getAccountInfoAsync()
			.spread (user) => user
			.catch => throw "Error retrieving the user info."
