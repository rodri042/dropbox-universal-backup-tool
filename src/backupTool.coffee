DropboxApi = require("./dropboxApi")
Promise = require("bluebird")
fsWalker = require("./fsWalker")
dirComparer = require("./dirComparer")
filesize = require("filesize")
moment = require("moment")
readlineSync = require("readline-sync")
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
			.map ([local, remote, hasDiffs]) =>
				path = "  " + local.path.yellow
				if hasDiffs.size
					path += "\t" + "(".white + "#{filesize remote.size}".red + " -> ".white + "#{filesize local.size}".green + ")".white
				if hasDiffs.date
					path += "\t" + "@ ".white + "#{moment(remote.clientModifiedAt).format('YYYY-MM-DD')}".red + " -> ".gray + "#{moment(local.clientModifiedAt).format('YYYY-MM-DD')}".green
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

		totalUpload = filesize _.sum(comparition.newFiles, "size")
		totalReUpload = filesize _.sum(comparition.modifiedFiles.map(([l]) => l), "size")
		console.log "\nTotals:".white.bold.underline
		console.log "  #{comparition.newFiles.length} to upload (#{totalUpload}).".white
		console.log "  #{comparition.modifiedFiles.length} to re-upload (#{totalReUpload}).".white
		console.log "  #{comparition.deletedFiles.length} to delete.".white

		prompt = require('readline');
		readLine = prompt.createInterface
			input: process.stdin
			output: process.stdout

		doYouAccept = ->
			readLine.question "\nDo you accept? (Y/n) ".cyan, (ans) ->
				ans = ans.toLowerCase()
				if ans isnt "y" and ans isnt "n" then return doYouAccept()

				console.log "OK"
				readLine.close()

		doYouAccept()

	_showReadingState: (size, total) =>
		console.log(
			"Reading remote files:".cyan
			((size / total) * 100).toFixed(2).green + "%".cyan
		)
