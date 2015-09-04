Dropbox = require("dropbox")
Promise = require("bluebird")
fs = require("fs")

config = null
try
	config = fs.readFileSync "#{__dirname}/../config.json", "utf-8"
	config = JSON.parse config
catch
	return console.log "Error: Can't load the config file."

client = Promise.promisifyAll new Dropbox.Client
	token: config.token

client.getAccountInfoAsync().spread (user) =>
	toGiB = (n) => n / Math.pow(1024, 3)
	console.log "User ID: #{user.uid}"
	console.log "Name: #{user.name}"
	console.log "Email: #{user.email}"
	console.log "Quota: #{toGiB(user.usedQuota)} GiB / #{toGiB(user.quota)} GiB"