function debug(text) {
	if (debuglevel > 0) {
		print text > "/dev/stderr"
	}
	else {
		debugoutput = debugoutput text "\n"
	}
}

