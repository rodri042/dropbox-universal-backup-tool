#!/usr/bin/env node

require("coffee-script/register")

require("./src/commandDispatcher")

/*
Assumptions:
	*re-uploads*:
		- A file "changes" when its `size` or `mtime` is different respect the Dropbox's one.

	*moves*
		- A file "moves" when another with the same `name`, `size`, and `mtime` is found in another path.
*/
