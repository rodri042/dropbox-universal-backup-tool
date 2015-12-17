_ = require("lodash")

module.exports = new

class DirComparer
	compare: (local, remote) =>
		newFiles = @_missingItems local, remote
		deletedFiles = @_missingItems remote, local

		movedFiles =
			_(deletedFiles)
				.map (file) =>
					if not file? then return
					movedFile = _.find newFiles, _.pick(file, "name", "size", "mtime")

					if movedFile?
						_.pull deletedFiles, file
						_.pull newFiles, movedFile

						oldPath: file.path
						newPath: movedFile.path
					else false
				.compact()
				.value()

		modifiedFiles = _.filter local, (l) =>
			r = @_findItem l, remote
			r? and (l.size isnt r.size or l.mtime isnt r.mtime)

		{ newFiles, modifiedFiles, deletedFiles, movedFiles }

	_missingItems: (one, another) =>
		one.filter (o) =>
			not @_findItem o, another

	_findItem: (item, collection) =>
		_.find collection, (it) => it.path.toLowerCase() is item.path.toLowerCase()
