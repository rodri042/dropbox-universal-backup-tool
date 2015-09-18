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
				.filter ([l, r]) =>
					(l? and r?) and (l.size isnt r.size)
				.value()

	_missingItems: (one, another) =>
		one.filter (o) =>
			not _.find another, (a) => o.path is a.path
