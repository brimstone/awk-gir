function mydebug(text) {
	debuglevel = 1
	debug(text)
	debuglevel = 0
	debugoutput = ""
}

function privmsg(target, text) {
	gsub(/{b}/, "\x03" "2", text)
	gsub(/{g}/, "\x03" "3", text)
	gsub(/{r}/, "\x03" "4", text)
	gsub(/{y}/, "\x03" "8", text)
	gsub(/{x}/, "\x0f", text)
	output = output "PRIVMSG " target " :" text "\n"
}

function notice(target, text) {
	gsub(/{b}/, "\x03" "2", text)
	gsub(/{g}/, "\x03" "3", text)
	gsub(/{r}/, "\x03" "4", text)
	gsub(/{y}/, "\x03" "8", text)
	gsub(/{x}/, "\x0f", text)
	output = output "NOTICE " target " :" text "\n"
}

function outputtest(text) {
	if (match(output, "^" text "$") == 1) {
		mydebug("OK")
		resetbuffers()
	}
	else {
		debuglevel = 1
		debug("FAILED")
		debug("################################################################################")
		debug("Output expected: " text "\n")
		debug("################################################################################")
		debug("Output obtained: " output)
		debug("################################################################################")
		debug("Debug: " debugoutput)
		exit
	}
}

function printferr (text) {
	printf text > "/dev/stderr"
}

function resetbuffers() {
	output = ""
	debugoutput = ""
	debuglevel = 0
}

function resetgame() {
	resetbuffers()
	gamestate="idle"
	timeoutflag = 0
	delete deck
	delete players
	delete hands
	currentplayer = 1
	direction = 1
}
