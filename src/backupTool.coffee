Dropbox = require("dropbox")
Promise = require("bluebird")

class BackupTool
	constructor: (config) ->
		@client = Promise.promisifyAll new Dropbox.Client
			token: config.token

	showInfo: =>
		@client.getAccountInfoAsync().spread (user) =>
			toGiB = (n) => n / Math.pow(1024, 3)
			console.log "User ID: #{user.uid}"
			console.log "Name: #{user.name}"
			console.log "Email: #{user.email}"
			console.log "Quota: #{toGiB(user.usedQuota)} GiB / #{toGiB(user.quota)} GiB"
