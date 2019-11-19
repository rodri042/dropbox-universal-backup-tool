normalizePath = require("../helpers/normalizePath")
_ = require("lodash")

module.exports = new

class DirComparer
	compare: (local, remote) =>
		emptyFolders = @_emptyFolders remote
		newFiles = @_missingItems local, remote
		deletedFiles = @_missingItems remote, local

		movedFiles = []
		for file, i in deletedFiles by -1
			movedFile = _.find newFiles, _.pick(file, "name", "size", "mtime")
			if not movedFile? then continue

			deletedFiles.splice i, 1
			_.pull newFiles, movedFile

			movedFiles.push
				oldPath: file.path
				newPath: movedFile.path

		modifiedFiles = []
		_.each local, (l) =>
			r = @_findItem l, remote
			isModified = r? and (l.size isnt r.size or l.mtime isnt r.mtime)

			if isModified
				modifiedFiles.push [l, r]

		{ emptyFolders, newFiles, modifiedFiles, deletedFiles, movedFiles }

	_missingItems: (one, another) =>
		missing = []
		for path, o of one
			continue if o.isFolder

			if not @_findItem o, another
				missing.push o
		missing

	_findItem: (item, collection) =>
		item = collection[normalizePath(item.path)]

		if item?.isFolder then undefined
		else item

	_emptyFolders: (remote) =>
		empty = []
		for path, folder of remote
			continue if not folder.isFolder or folder.path is ""

			isEmpty = true
			for filePath, file of remote
				continue if file.isFolder

				if _.startsWith(file.path, folder.path + "/")
					isEmpty = false
					break

			empty.push folder if isEmpty

		empty
