DropboxApi = require("./dropboxApi")
Promise = require("bluebird")
fsWalker = require("./fsWalker")
dirComparer = require("./dirComparer")
filesize = require("filesize")
moment = require("moment")
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
			console.log(
				"User information:\n\n".white.bold.underline +
				"User ID: ".white.bold + "#{user.uid}\n".white +
				"Name: ".white.bold + "#{user.name}\n".white +
				"Email: ".white.bold + "#{user.email}\n".white +
				"Quota: ".white.bold + "#{filesize(user.usedQuota)} / #{filesize(user.quota)}".white
			)

	_sync: ({ local, remote }) =>
		comparition = dirComparer.compare local, remote

		console.log "\nNew files:".white.bold.underline

		console.log(comparition.newFiles
			.map (it) =>
				"  " + it.path.green + "\t" +
				"(#{filesize it.size})".white + "\t" +
				"@ #{moment(it.clientModifiedAt).format('YYYY-MM-DD')}".gray
			.join "\n"
		)

		console.log "\nModified files:".white.bold.underline

		console.log(comparition.modifiedFiles
			.map (it) =>
				"  " + it.path.yellow + "\t" +
				"(#{filesize it.size})".white + "\t" +
				"@ #{moment(it.clientModifiedAt).format('YYYY-MM-DD')}".gray
			.join "\n"
		)

		console.log "\nDeleted files:".white.bold.underline

		console.log(comparition.deletedFiles
			.map (it) =>
				"  " + it.path.red + "\t" +
				"(#{filesize it.size})".white + "\t" +
				"@ #{moment(it.clientModifiedAt).format('YYYY-MM-DD')}".gray
			.join "\n"
		)

		console.log "\nTotal:".white.bold.underline
		console.log "  #{comparition.newFiles.length} to upload."
		console.log "  #{comparition.modifiedFiles.length} to re-upload."
		console.log "  #{comparition.deletedFiles.length} to delete."
	_showReadingState: (size, total) =>
		console.log(
			"Reading remote files:".cyan
			((size / total) * 100).toFixed(2).green + "%".cyan
		)
