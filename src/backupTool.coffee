DropboxApi = require("./dropboxApi")
Promise = require("bluebird")
fsWalker = require("./fsWalker")
dirComparer = require("./dirComparer")
_ = require("lodash")
require("colors")

module.exports =

class BackupTool
	constructor: (@options) ->
		@dropboxApi = new DropboxApi(@options.token)

	getFilesAndSync: =>
		@dropboxApi.getAccountInfo().then ({ usedQuota }) =>
			onRead = (size) => @_showReadingState size, usedQuota
			@dropboxApi.on "reading", onRead

			promises =
				local: fsWalker.walk @options.from
				remote: @dropboxApi.readDir @options.to

			promises.remote.then =>
				if not promises.local.isResolved()
					console.log "Still reading local files...".cyan

			Promise.props(promises)
				.then @_sync
				.finally =>
					@dropboxApi.removeListener "reading", onRead

	showInfo: =>
		@dropboxApi.getAccountInfo().then (user) =>
			toGiB = (n) => (n / Math.pow(1024, 3)).toFixed 2
			console.log(
				"User information:\n\n".cyan +
				"User ID: #{user.uid}\n" +
				"Name: #{user.name}\n" +
				"Email: #{user.email}\n" +
				"Quota: #{toGiB(user.usedQuota)} GiB / #{toGiB(user.quota)} GiB"
			)

	_sync: ({ local, remote }) =>
		console.log dirComparer.compare(local, remote)

	_showReadingState: (size, total) =>
		console.log(
			"Reading remote files:".cyan
			((size / total) * 100).toFixed(2).green + "%".cyan
		)
