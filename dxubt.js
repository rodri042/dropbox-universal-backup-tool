#!/usr/bin/env node

require("coffee-script/register")

require("./src/commandDispatcher")

/*
Assumptions:
	*re-uploads*:
		- A file "changes" when its size is different respect the Dropbox's one.

	*moves*
		- A file "moves" when another with the same name and size is found in another path.
*/
