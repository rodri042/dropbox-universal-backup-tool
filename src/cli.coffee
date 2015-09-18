BackupTool = require("./synchronizer/backupTool")
filesize = require("filesize")
prompt = require("readline")
_ = require("lodash")
require("colors")

module.exports =

class Cli
	constructor: (@options) ->
		@backupTool = new BackupTool(@options)
		onError = (e) ->
			console.log "^ it didn't work".red
			console.log "#{e}".red

		@backupTool
			.on "still-reading", =>
				console.log "Still reading local files...".cyan
			.on "uploading", (file) ->
				console.log "Uploading ".white + file.path.yellow + "...".white
			.on "deleting", (file) ->
				console.log "Deleting ".white + file.path.yellow + "...".white
			.on "not-uploaded", onError
			.on "not-deleted", onError

	getFilesAndSync: =>
		@backupTool.getInfo().then ({ usedQuota }) =>
			onRead = (size) => @_showReadingState size, usedQuota
			@backupTool.on "reading", onRead

			@backupTool
				.getFilesAndCompare @options.from, @options.to
				.then @_askForSync
				.finally =>
					@backupTool.removeListener "reading", onRead

	showInfo: =>
		@backupTool.getInfo().then (user) =>
			console.log(
				"User information:\n\n".white.bold.underline +
				"User ID: ".white.bold + "#{user.uid}\n".white +
				"Name: ".white.bold + "#{user.name}\n".white +
				"Email: ".white.bold + "#{user.email}\n".white +
				"Quota: ".white.bold + "#{filesize(user.usedQuota)} / #{filesize(user.quota)}".white
			)

	_askForSync: (comparision) =>
		console.log "\nNew files:".white.bold.underline

		console.log(comparision.newFiles
			.map (it) =>
				"  " + it.path.green + "\t" +
				"(#{filesize it.size})".white
			.join "\n"
		)

		console.log "\nModified files:".white.bold.underline

		console.log(comparision.modifiedFiles
			.map ([local, remote]) =>
				path = "  " + local.path.yellow
				path += "\t" + "(".white + "#{filesize remote.size}".red + " -> ".white + "#{filesize local.size}".green + ")".white
			.join "\n"
		)

		console.log "\nDeleted files:".white.bold.underline

		console.log(comparision.deletedFiles
			.map (it) =>
				"  " + it.path.red + "\t" +
				"(#{filesize it.size})".white
			.join "\n"
		)

		totalUpload = filesize _.sum(comparision.newFiles, "size")
		totalReUpload = filesize _.sum(comparision.modifiedFiles.map(([l]) => l), "size")
		console.log "\nTotals:".white.bold.underline
		console.log "  #{comparision.newFiles.length} to upload (#{totalUpload}).".white
		console.log "  #{comparision.modifiedFiles.length} to re-upload (#{totalReUpload}).".white
		console.log "  #{comparision.deletedFiles.length} to delete.".white

		totalChanges = comparision.newFiles.length + comparision.modifiedFiles.length + comparision.deletedFiles.length
		if totalChanges is 0 then return

		@_doYouAccept()
			.then => @_sync comparision
			.catch => process.exit 0

	_sync: (comparision) =>
		console.log "\nSyncing files...\n".cyan.bold
		@backupTool.sync comparision

	_doYouAccept: =>
		new Promise (resolve, reject) =>
			if @options.yes then return resolve()

			readLine = prompt.createInterface
				input: process.stdin
				output: process.stdout

			ask = =>
				readLine.question "\nDo you accept? (y/n) ".cyan, (ans) =>
					ans = ans.toLowerCase()
					if ans isnt "y" and ans isnt "n" then return ask()

					readLine.close()
					if ans is "y" then resolve() else reject()
			ask()

	_showReadingState: (size, total) =>
		console.log(
			"Reading remote files:".cyan
			((size / total) * 100).toFixed(2).green + "%".cyan
		)
