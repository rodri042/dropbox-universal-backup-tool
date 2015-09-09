Promise = require("bluebird")
walk = require("walk")
fs = Promise.promisifyAll require("fs")

module.exports = (path) ->
	fs.statAsync(path)
		.catch -> throw "Error reading the local directory #{path}."
		.then ->
			new Promise (resolve) ->
				files = []

				walker = walk.walk path, followLinks: true

				walker.on "file", (root, stat, next) ->
					files.push
						path: "#{root.replace path, ""}/#{stat.name}"
						name: stat.name
						size: stat.size
						clientModifiedAt: stat.mtime
					next()

				walker.on "end", ->
					resolve files
