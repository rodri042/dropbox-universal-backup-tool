Promise = require("bluebird")
DropboxApi = require("../fs/dropboxApi")
{ EventEmitter } = require("events")
fsWalker = require("../fs/fsWalker")
dirComparer = require("./dirComparer")
asyncPipeline = require("../helpers/asyncPipeline")
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

	sync: (comparision) =>
		uploads = comparision.newFiles.map (newFile) =>
			=> @_uploadFile newFile, comparision

		asyncPipeline uploads

	getInfo: => @dropboxApi.getAccountInfo()

	_uploadFile: (newFile, comparision) =>
		@emit "uploading", newFile
		localPath = comparision.from + newFile.path
		remotePath = comparision.to + newFile.path

		@dropboxApi.uploadFile(localPath, remotePath)
			.then => @emit "uploaded", newFile
			.catch (e) => @emit "not-uploaded", newFile
