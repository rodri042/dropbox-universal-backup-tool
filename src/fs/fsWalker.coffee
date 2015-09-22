Promise = require("bluebird")
walk = require("walk")
fs = Promise.promisifyAll require("fs")

module.exports = new

class FsWalker
	walk: (path, ignore = []) =>
		fs.statAsync(path)
			.catch => throw "Error reading the local directory #{path}."
			.then =>
				new Promise (resolve) =>
					files = []
					walker = walk.walk path, followLinks: true

					walker.on "file", (root, stats, next) =>
						stats = @_makeStats path, root, stats

						ignored = ignore.some (exp) =>
							new RegExp(exp, "i").test stats.path

						if not ignored then files.push stats

						next()

					walker.on "end", =>
						resolve files

	_makeStats: (path, root, stats) =>
		path: "#{root.replace path, ""}/#{stats.name}"
		name: stats.name
		size: stats.size
