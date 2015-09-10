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
					return false if not l? or not r?

					(l.size isnt r.size) or
					(l.clientModifiedAt isnt r.clientModifiedAt)
				.value()

	_missingItems: (one, another) =>
		one.filter (o) =>
			not _.find another, (a) => _.isEqual o, a
