Dropbox = require("dropbox")
Promise = require("bluebird")
require("colors")

module.exports =

class BackupTool
	constructor: (@options) ->
		@client = Promise.promisifyAll new Dropbox.Client
			token: @options.token

	showInfo: =>
		@client.getAccountInfoAsync().spread (user) =>
			toGiB = (n) => (n / Math.pow(1024, 3)).toFixed 2
			console.log(
				"User information:\n\n".cyan +
				"User ID: #{user.uid}\n" +
				"Name: #{user.name}\n" +
				"Email: #{user.email}\n" +
				"Quota: #{toGiB(user.usedQuota)} GiB / #{toGiB(user.quota)} GiB"
			)
