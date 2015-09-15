Promise = require("bluebird")
DropboxApi = require("../fs/dropboxApi")
fsWalker = require("../fs/fsWalker")
dirComparer = require("./dirComparer")
{ EventEmitter } = require("events")
_ = require("lodash")

module.exports =

class BackupTool extends EventEmitter
	constructor: (token) ->
		@dropboxApi = new DropboxApi(token)
		@dropboxApi.on "reading", (e) => @emit "reading", e

	getFilesAndCompare: (from, to) =>
		promises =
			local: fsWalker.walk from
			remote: @dropboxApi.readDir to

		promises.remote.then =>
			if not promises.local.isResolved() then @emit "still-reading"

		Promise.props(promises).then ({ local, remote }) =>
			dirComparer.compare local, remote

	getInfo: => @dropboxApi.getAccountInfo()
