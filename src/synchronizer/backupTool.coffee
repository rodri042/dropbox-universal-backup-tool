Promise = require("bluebird")
DropboxApi = require("../fs/dropboxApi")
{ EventEmitter } = require("events")
fsWalker = require("../fs/fsWalker")
dirComparer = require("./dirComparer")
asyncPipeline = require("../helpers/asyncPipeline")
_ = require("lodash")

module.exports =

class BackupTool extends EventEmitter
	constructor: ({ token, @from, @to }) ->
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
		getActions = (group, action) =>
			comparision[group].map (file) =>
				=> action file

		uploads = getActions "newFiles", @_uploadFile
		modifications = getActions "modifiedFiles", @_reuploadFile
		deletions = getActions "deletedFiles", @_deleteFile

		asyncPipeline(uploads).then =>
			asyncPipeline(modifications).then =>
				asyncPipeline deletions

	getInfo: => @dropboxApi.getAccountInfo()

	_uploadFile: (file) =>
		@emit "uploading", file
		localPath = @from + file.path
		remotePath = @to + file.path

		@dropboxApi.uploadFile(localPath, remotePath)
			.then => @emit "uploaded", file
			.catch => @emit "not-uploaded", file

	_deleteFile: (file) =>
		@emit "deleting", file
		@dropboxApi.deleteFile @to + file.path
			.then => @emit "deleted", file
			.catch (e) => @emit "not-deleted", file

	_reuploadFile: ([local]) =>
		@_uploadFile local
