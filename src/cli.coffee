BackupTool = require("./synchronizer/backupTool")
filesize = require("filesize")
moment = require("moment")
prompt = require("readline")
_ = require("lodash")
require("colors")

module.exports =

class Cli
	constructor: (@options) ->
		@backupTool = new BackupTool(@options.token)
		@backupTool.on "still-reading", =>
			console.log "Still reading local files...".cyan

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
				"(#{filesize it.size})".white + "\t" +
				"@ #{moment(it.clientModifiedAt).format('YYYY-MM-DD')}".gray
			.join "\n"
		)

		console.log "\nModified files:".white.bold.underline

		console.log(comparision.modifiedFiles
			.map ([local, remote, hasDiffs]) =>
				path = "  " + local.path.yellow
				if hasDiffs.size
					path += "\t" + "(".white + "#{filesize remote.size}".red + " -> ".white + "#{filesize local.size}".green + ")".white
				if hasDiffs.date
					path += "\t" + "@ ".white + "#{moment(remote.clientModifiedAt).format('YYYY-MM-DD')}".red + " -> ".gray + "#{moment(local.clientModifiedAt).format('YYYY-MM-DD')}".green
			.join "\n"
		)

		console.log "\nDeleted files:".white.bold.underline

		console.log(comparision.deletedFiles
			.map (it) =>
				"  " + it.path.red + "\t" +
				"(#{filesize it.size})".white + "\t" +
				"@ #{moment(it.clientModifiedAt).format('YYYY-MM-DD')}".gray
			.join "\n"
		)

		totalUpload = filesize _.sum(comparision.newFiles, "size")
		totalReUpload = filesize _.sum(comparision.modifiedFiles.map(([l]) => l), "size")
		console.log "\nTotals:".white.bold.underline
		console.log "  #{comparision.newFiles.length} to upload (#{totalUpload}).".white
		console.log "  #{comparision.modifiedFiles.length} to re-upload (#{totalReUpload}).".white
		console.log "  #{comparision.deletedFiles.length} to delete.".white

		@_doYouAccept()
			.then => console.log "YES"
			.catch => console.log "NO"

	_doYouAccept: =>
		new Promise (resolve, reject) =>
			readLine = prompt.createInterface
				input: process.stdin
				output: process.stdout

			if @options.yes then return resolve()
			ask = =>
				readLine.question "\nDo you accept? (y/n) ".cyan, (ans) =>
					ans = ans.toLowerCase()
					if ans isnt "y" and ans isnt "n" then return ask()

					if ans is "y" then resolve() else reject()
					readLine.close()
			ask()

	_showReadingState: (size, total) =>
		console.log(
			"Reading remote files:".cyan
			((size / total) * 100).toFixed(2).green + "%".cyan
		)
