_ = require("lodash")

module.exports = (path) =>
	_.deburr path.toLowerCase()
