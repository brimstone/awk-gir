BEGIN {
	print "nick " mynick
	print "user " mynick " \"\" \"\" :test"
}
/^:[^ ]* 001/ {
	print "join " channel
}
/^PING/ {
	print "PONG " $2
	process_timers()
}
/^:[^ ]* PRIVMSG/ {
	nick = $1
	sub(/!.*$/, "", nick)
	sub(/^:/, "", nick)
	text = $0
	sub(/^.* :/, "", text)
	sub(/\r$/, "", text)
	debug(">" $0)
	process_channel_msg($3, nick, text)
}

function privmsg(target, text) {
	gsub(/{b}/, "\x03" "2", text)
	gsub(/{g}/, "\x03" "3", text)
	gsub(/{r}/, "\x03" "4", text)
	gsub(/{y}/, "\x03" "8", text)
	gsub(/{x}/, "\x0f", text)
	debug("PRIVMSG " target " :" text)
	print "PRIVMSG " target " :" text
	system("sleep 2")
}

function notice(target, text) {
	gsub(/{b}/, "\x03" "2", text)
	gsub(/{g}/, "\x03" "3", text)
	gsub(/{r}/, "\x03" "4", text)
	gsub(/{y}/, "\x03" "8", text)
	gsub(/{x}/, "\x0f", text)
	print "NOTICE " target " :" text
}

