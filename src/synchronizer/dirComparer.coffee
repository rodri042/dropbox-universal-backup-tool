_ = require("lodash")

module.exports = new

class DirComparer
	compare: (local, remote) =>
		newFiles = @_missingItems local, remote, "new"
		deletedFiles = @_missingItems remote, local, "deleted"

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

	_missingItems: (one, another, a) =>
		one.filter (o) =>
			not @_findItem o, another

	_findItem: (item, collection) =>
		_.find collection, (it) => _.deburr(it.path.toLowerCase()) is _.deburr(item.path.toLowerCase())
