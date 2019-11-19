BackupTool = require("./synchronizer/backupTool")
filesize = require("filesize")
moment = require("moment")
prompt = require("readline")
MultiProgress = require("multi-progress")
_ = require("lodash")
require("colors")

module.exports =

class Cli
	constructor: (@options) ->
		@backupTool = new BackupTool(@options)
		onError = (e) ->
			console.log " ^ it didn't work".red
			console.log "#{e}".red

		@multiProgress = new MultiProgress(process.stdout);
		@progressBars = {}

		@backupTool
			.on "still-reading", =>
				console.log "Still reading local files...".cyan
			.on "uploading", (file) =>
				console.log "Uploading ".white + file.path.yellow + " (#{filesize file.size})...".white
				if file.size > 0
					@progressBars[file.path] = @multiProgress.newBar "[:bar] [:percent] :etas",
						complete: '\u001b[42m \u001b[0m'
						incomplete: '\u001b[41m \u001b[0m'
						total: file.size
					@progressBars[file.path].tick 0
			.on "progress", ({ file, progress }) =>
				@progressBars[file.path]?.tick progress
			.on "uploaded", (file) =>
				@progressBars[file.path]?.terminate()
				delete @progressBars[file.path]
			.on "deleting", (file) =>
				console.log "Deleting ".white + file.path.yellow + "...".white
			.on "moving", (file) =>
				console.log "Moving ".white + file.oldPath.yellow + " to ".white + file.newPath.yellow + "...".white
			.on "not-uploaded", onError
			.on "not-deleted", onError
			.on "not-moved", onError

	getFilesAndSync: =>
		onRead = (count) => @_showReadingState count
		@backupTool.on "reading", onRead

		@backupTool
			.getFilesAndCompare @options.from, @options.to, @options.ignore
			.then @_askForSync
			.finally =>
				@backupTool.removeListener "reading", onRead

	showInfo: =>
		@backupTool.getInfo().then (user) =>
			console.log(
				"User information:\n\n".white.bold.underline +
				"User ID: ".white.bold + "#{user.account_id}\n".white +
				"Name: ".white.bold + "#{user.name.display_name}\n".white +
				"Email: ".white.bold + "#{user.email}".white
			)

	_askForSync: (comparision) =>
		formatDate = (it) =>
			moment(it.mtime).format "YYYY-MM-DD HH:mm:ss"

		console.log "\n\nNew files:".white.bold.underline

		console.log(comparision.newFiles
			.map (it) =>
				"  " + it.path.green + "\t" +
				"(#{filesize it.size})".white + "\t" +
				"@ #{formatDate(it)}".white
			.join "\n"
		)

		console.log "\nModified files:".white.bold.underline

		console.log(comparision.modifiedFiles
			.map ([local, remote]) =>
				"  " + local.path.yellow + "\t" +
				"(".white + "#{filesize remote.size}".red + " -> ".white + "#{filesize local.size}".green + ")".white + "\t" +
				"@ ".white + "#{formatDate(remote)}".red + " -> ".white + "#{formatDate(local)}".green
			.join "\n"
		)

		console.log "\nDeleted files:".white.bold.underline

		console.log(comparision.deletedFiles
			.map (it) =>
				"  " + it.path.red + "\t" +
				"(#{filesize it.size})".white + "\t" +
				"@ #{formatDate(it)}".white
			.join "\n"
		)

		console.log "\nMoved files:".white.bold.underline

		console.log(comparision.movedFiles
			.map (it) =>
				"  " + it.oldPath.red + " -> ".white +
				it.newPath.green
			.join "\n"
		)

		totalUpload = filesize _.sumBy(comparision.newFiles, "size")
		totalReUpload = filesize _.sumBy(comparision.modifiedFiles.map(([l]) => l), "size")
		console.log "\nTotals:".white.bold.underline
		console.log "  #{comparision.newFiles.length} to upload (#{totalUpload}).".white
		console.log "  #{comparision.modifiedFiles.length} to re-upload (#{totalReUpload}).".white
		console.log "  #{comparision.deletedFiles.length} to delete.".white
		console.log "  #{comparision.movedFiles.length} to move.".white

		totalChanges = comparision.newFiles.length + comparision.modifiedFiles.length + comparision.deletedFiles.length + comparision.movedFiles.length
		if totalChanges is 0 then return

		@_doYouAccept()
			.catch => process.exit 0
			.then => @_sync comparision

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

	_showReadingState: (count) =>
		process.stdout.write(
			"Reading remote files: #{count}\r".cyan, "utf8"
		)
