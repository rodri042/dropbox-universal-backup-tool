DropboxApi = require("./dropboxApi")
_ = require("lodash")
require("colors")

module.exports =

class BackupTool
	constructor: (@options) ->
		@dropboxApi = new DropboxApi(@options.token)
		@_subscribeToDebugEvents()

	sync: =>
		@dropboxApi.readDir(@options.to).then (entries) =>
			console.log _.map entries, "path"

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

	_subscribeToDebugEvents: =>
		if @options.debug
			@dropboxApi.events.on "resolving", (path) =>
				console.log "Resolving #{path}..."
			@dropboxApi.events.on "resolved", (path) =>
				console.log "Resolved #{path}."
