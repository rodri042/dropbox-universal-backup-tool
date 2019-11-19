Promise = require("bluebird")
DropboxApi = require("../fs/dropboxApi")
{ EventEmitter } = require("events")
fsWalker = require("../fs/fsWalker")
dirComparer = require("./dirComparer")
asyncPipeline = require("../helpers/asyncPipeline")
_ = require("lodash")

module.exports =

class BackupTool extends EventEmitter
	constructor: ({ token, @from, @to, @concurrency }) ->
		@dropboxApi = new DropboxApi(token)
		@dropboxApi.on "reading", (e) => @emit "reading", e
		@dropboxApi.on "progress", (e) => @emit "progress", e

	getFilesAndCompare: (from, to, ignore = []) =>
		promises =
			local: fsWalker.walk from, ignore
			remote: @dropboxApi.readDir to

		promises.remote.then =>
			if not promises.local.isResolved() then @emit "still-reading"
		.catch =>

		Promise.props(promises).then ({ local, remote }) =>
			dirComparer.compare local, remote

	sync: (comparision) =>
		getActions = (group, action) =>
			comparision[group].map (file) =>
				=> action file

		uploads = getActions "newFiles", @_uploadFile
		modifications = getActions "modifiedFiles", @_reuploadFile
		deletions = getActions "deletedFiles", @_deleteFile
		moves = getActions "movedFiles", @_moveFile

		asyncPipeline(uploads, @concurrency).then =>
			asyncPipeline(modifications, @concurrency).then =>
				asyncPipeline(deletions, @concurrency).then =>
					asyncPipeline moves

	getInfo: => @dropboxApi.getAccountInfo()

	_uploadFile: (file) =>
		localFile = _.assign _.clone(file),	path: @from + file.path
		@emit "uploading", localFile
		@dropboxApi.uploadFile(localFile, @to + file.path)
			.then => @emit "uploaded", localFile
			.catch (e) => @emit "not-uploaded", e

	_deleteFile: (file) =>
		@emit "deleting", file

		@dropboxApi.deleteFile @to + file.path
			.then => @emit "deleted", file
			.catch (e) => @emit "not-deleted", e

	_reuploadFile: ([local]) =>
		@_uploadFile local

	_moveFile: (file) =>
		@emit "moving", file

		@dropboxApi.moveFile(@to + file.oldPath, @to + file.newPath)
			.then => @emit "moved", file
			.catch (e) => @emit "not-moved", e
