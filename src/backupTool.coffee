DropboxApi = require("./dropboxApi")
require("colors")

module.exports =

class BackupTool
	constructor: (@options) ->
		@dropboxApi = new DropboxApi(@options.token)

	sync: =>
		@dropboxApi.readDir(@options.to).then (entries) =>
			console.log entries

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
