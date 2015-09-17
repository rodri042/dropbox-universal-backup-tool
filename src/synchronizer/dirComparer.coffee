_ = require("lodash")

module.exports = new

class DirComparer
	compare: (local, remote) =>
		newFiles: @_missingItems local, remote
		deletedFiles: @_missingItems remote, local
		modifiedFiles:
			_(local)
				.concat(remote)
				.groupBy "path"
				.filter ([l, r]) => l? and r?
				.map ([l, r]) =>
					[l, r].concat [
						size: (l.size isnt r.size)
						date: JSON.stringify(l.clientModifiedAt) isnt JSON.stringify(r.clientModifiedAt)
					]
				.filter ([l, r, hasDiffs]) =>
					hasDiffs.size or hasDiffs.date
				.value()

	_missingItems: (one, another) =>
		one.filter (o) =>
			not _.find another, (a) => o.path is a.path
