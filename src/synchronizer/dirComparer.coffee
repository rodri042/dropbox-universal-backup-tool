_ = require("lodash")

module.exports = new

class DirComparer
	compare: (local, remote) =>
		newFiles = @_missingItems local, remote
		deletedFiles = @_missingItems remote, local

		movedFiles =
			_(_.clone deletedFiles)
				.map (file) =>
					movedFile = _.find newFiles, _.pick(file, "name", "size", "mtime")

					if movedFile?
						_.pull deletedFiles, file
						_.pull newFiles, movedFile

						oldPath: file.path
						newPath: movedFile.path
					else false
				.compact()
				.value()

		modifiedFiles =
			_(_.clone local)
				.concat(remote)
				.groupBy (it) -> it.path.toLowerCase()
				.filter ([l, r]) =>
					(l? and r?) and (l.size isnt r.size or l.mtime isnt r.mtime)
				.value()

		{ newFiles, modifiedFiles, deletedFiles, movedFiles }

	_missingItems: (one, another) =>
		one.filter (o) =>
			not _.find another, (a) => o.path.toLowerCase() is a.path.toLowerCase()
