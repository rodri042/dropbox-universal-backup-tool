pad = (num, size) ->
  s = "000000000#{num}"
  s.substr s.length - size

isASCII = (str) ->
  /^[\x00-\x7F]*$/.test str

module.exports = (str) ->
	chars = str.split ""
	chars
		.map (it) ->
			ascii = it.charCodeAt()
			hexAscii = ascii.toString 16

			if isASCII(it) then it
			else "\\u#{pad(hexAscii, 4)}"
		.join ""
