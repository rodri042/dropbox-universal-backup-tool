normalizePath = require("../helpers/normalizePath")
_ = require("lodash")

module.exports = new

class DirComparer
	compare: (local, remote) =>
		newFiles = @_missingItems local, remote
		deletedFiles = @_missingItems remote, local

		movedFiles = []
		_.each deletedFiles, (file) =>
			if not file? then return # because we are deleting while iterating the array
			movedFile = _.find newFiles, _.pick(file, "name", "size", "mtime")
			if not movedFile? then return

			_.pull deletedFiles, file
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

		{ newFiles, modifiedFiles, deletedFiles, movedFiles }

	_missingItems: (one, another) =>
		missing = []
		for path, o of one
			if not @_findItem o, another
				missing.push o
		missing

	_findItem: (item, collection) =>
		collection[normalizePath(item.path)]
