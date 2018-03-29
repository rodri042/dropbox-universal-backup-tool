Promise = require("bluebird")
walk = require("walk")
fs = Promise.promisifyAll require("fs")

IGNORED_FILE = ".DS_Store"

module.exports = new

class FsWalker
	walk: (path, ignore = []) =>
		fs.statAsync(path)
			.catch => throw "Error reading the local directory #{path}."
			.then =>
				new Promise (resolve) =>
					files = []
					walker = walk.walk path, followLinks: true, filters: ignore

					walker.on "file", (root, stats, next) =>
						stats = @_makeStats path, root, stats
						files.push stats if stats.name isnt IGNORED_FILE

						next()

					walker.on "end", =>
						resolve files

	_makeStats: (path, root, stats) =>
		path: "#{root.replace path, ""}/#{stats.name}"
		name: stats.name
		size: stats.size
		mtime: stats.mtime.setMilliseconds 0
