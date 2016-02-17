BEGIN {
	# see the random counter
	srand()
	gamestate = "idle"
	charlookup["Y"] = -1
	charlookup["G"] = -2
	charlookup["R"] = -3
	charlookup["B"] = -4
	charlookup["W"] = -5

	charlookup["S"] = -1
	charlookup["D"] = -2
	# R is already 3
}

function process_timers() {
	debug("Processing timers")
	"date +%s" | getline systime
	close("date +%s")
	debug("systime: " systime " gir_timeout: " gir_timeout " play_timeout: " play_timeout " timeoutflag: " timeoutflag)
	if (gir_timeout + 600 < systime) {
		if (rand() > .99) {
			privmsg(channel, random_line("gir.quotes"))
		}
		"date +%s" | getline gir_timeout
		close("date +%s")
	}
	# Check for idle players
	if (gamestate != "idle" && gamestate != "preparing") {
		debug("Checking for idle players")
		if (play_timeout + 60 < systime && timeoutflag == 1) {
			debug("warning timeout")
			timeoutflag = 2
			if (match(discard[discard[0]], /^W/) != 0) {
				privmsg(channel, players[currentplayer] ": are you still there? Current card is " displaycard(colorcard))
			}
			else {
				privmsg(channel, players[currentplayer] ": are you still there? Current card is " displaycard(discard[discard[0]]))
			}
		}
		if (play_timeout + 120 < systime && timeoutflag == 2) {
			debug("removal timeout")
			privmsg(channel, players[currentplayer] ": you are the weakest link, good bye")
			# TODO bug about here with the 1 player timing out
			removeplayer(players[currentplayer])
			if (players[0] < 2) {
				gamestate = "idle"
				privmsg(channel, "out of players, game over")
				return
			}
			if (direction == -1) {
				advanceplayer()
			}
			if (currentplayer > players[0]) {
				currentplayer = 1
			}
			if (players[currentplayer] == mynick) {
				iplaynow(channel)
			}
			else {
				shownext(channel)
			}
		}
	}
	if (gamestate == "preparing") {
		debug("Checking for idle starters")
		if (play_timeout + 600 < systime) {
			startgame(channel)
		}
	}
}

function startgame(channel) {
	if (players[0] == 1) {
		privmsg(channel, "I'mma play too!")
		push(players, mynick)
		for (x = 0; x < 7; x++) {
			deal(mynick)
		}
	}
	gamestate = "running"
	delete discard
	currentplayer = 1
	while(1) {
		card = shift(deck)
		privmsg(channel, players[1] " starts with current card: " displaycard(card))
		push(discard, card)
		if(match(card, /^[RBGY][0-9]$/)) {
			processcard(card)
			#advanceplayer()
			break
		}
		else {
			privmsg(channel, "that card's lame, let's try again")
		}
	}
	if (players[currentplayer] == mynick) {
		iplaynow(channel)
	}
	else {
		shownext(channel)
	}
}

function process_channel_msg (channel, nick, text) {
	debug("Checking msg from " nick ": " text)
	# TODO: !help
	if (match(text, /^!uno$/) != 0) {
		debug("Got a request to start uno gamestate:" gamestate)
		if (gamestate == "idle") {
			gamestate = "preparing"
			"date +%s" | getline play_timeout
			close("date +%s")
			delete players
			delete hands
			initdeck()
			shuffledeck()
			push(players, nick)
			currentplayer = 1
			direction = 1
			privmsg(channel, nick " started a new game of {r}U{b}N{g}O{x}! Type !join before play starts to join in. Type !leave at any time, but you can't come back.")
			privmsg(channel, nick ": Type !start when ready to play. !stop to stop the game.")
			debug("top card: " deck[1])
			for (x = 0; x < 7; x++) {
				deal(nick)
			}
			msghand(nick)
		}
		else {
			privmsg(channel, nick ": we're already playing")
		}
	}
	else if (match(text, /^!join$/) != 0) {
		if (gamestate == "preparing") {
			if (counthand(nick) == 0) {
				privmsg(channel, nick " joins the game")
				push(players, nick)
				for (x = 0; x < 7; x++) {
					deal(nick)
				}
				msghand(nick)
			} else {
				privmsg(channel, nick ": you are already in the game")
			}
		}
		else if (gamestate == "idle") {
			privmsg(channel, nick ": No game is running. Type !uno to start it")
		}
	}
	else if (match(text, /^!joinbot$/) != 0 || match(text, /^!botjoin$/) != 0) {
		if (gamestate == "preparing") {
			if (nick == players[1] && counthand(mynick) == 0) {
				privmsg(channel, "I'mma play too!")
				push(players, mynick)
				for (x = 0; x < 7; x++) {
					deal(mynick)
				}
			}
		}
	}
	else if (match(text, /^!start$/) != 0) {
		if (gamestate == "preparing") {
			if (nick == players[1]) {
				startgame(channel)
			}
			else {
				privmsg(channel, nick ": " players[1] " has to !start")
			}
		}
		else if (gamestate == "idle" ) {
			privmsg(channel, nick ": No game is running. Type !uno to start one")
		}
		else {
			privmsg(channel, nick ": A game is running, wait till later to try to start one")
		}
	}
	else if (match(text, /^!players$/) != 0 || match(text, /^!playas$/) != 0) {
		if (gamestate == "idle") {
			return
		}
		if (direction == -1) {
			text="<-"
		}
		else {
			text="->"
		}
		for(x=1; x<=players[0]; x++) {
			text=text " " players[x] "(" counthand(players[x]) ")"
		}
		privmsg(channel, "Players: " text)
	}
	else if (match(text, /^!hand$/) != 0) {
		msghand(nick)
	}
	else if (match(text, /^[Pp](lay)? /) != 0) {
		# check to see if our player is actually in the game
		if (hands[nick, "0"] == "") {
			debug(nick " is not in uno")
			return
		}
		# check to see if we're running a game
		if (gamestate != "running" && gamestate != "drawing") {
			debug("Gamestate is not running it's " gamestate)
			return
		}
		# check to see if it's even their turn
		if (players[currentplayer] != nick) {
			privmsg(channel, nick ": it is currently " players[currentplayer] "'s turn")
			return
		}
		# figure out what they said and setup defaults
		count = split(text, cmd, " ")
		color = "_"
		number = ""
		# parse color
		if (match(cmd[2], /^[Rr](ed)?$/) != 0) {
			color = "R"
		}
		else if (match(cmd[2], /^[Bb](lue)?$/) != 0) {
			color = "B"
		}
		else if (match(cmd[2], /^[Gg](reen)?$/) != 0) {
			color = "G"
		}
		else if (match(cmd[2], /^[Yy](ellow)?$/) != 0) {
			color = "Y"
		}
		else if (match(cmd[2], /^[Ww](ild)?$/) != 0) {
			color = "W"
		}
		else {
			debug("wut?")
		}
		# if it's a number card
		if (match(cmd[3], /^[0-9]$/) != 0) {
			number = cmd[3]
		}
		else if (match(cmd[3], /^[Dd](raw)?$/) != 0) {
			if(color == "W") {
				number = "4"
			}
			else {
				number = "D"
			}
		}
		# reverse
		else if (match(cmd[3], /^[Rr](everse)?$/) != 0) {
			number = "R"
		}
		# skip
		else if (match(cmd[3], /^[Ss](kip)?$/) != 0) {
			number = "S"
		}
		debug("Parsing " text " from " nick " to color: " cmd[2] "-" color " number: " cmd[3] "-" number)
		card = color number
		# check to see if that's a card in their hand
		if (searchhand(nick, card) != 0) {
			privmsg(channel, nick " you don't have that card, try again")
			return
		}
		# check to see if that's a valid card to play on the top card
		if (validatecard(card) != 0) {
			privmsg(channel, nick ": that's not valid to play at this time")
			return
		}
		gamestate = "running"
		# show the channel what they've played
		privmsg(channel, nick " plays a " displaycard(card))
		# remove it from their hand
		removehand(nick, card)
		push(discard, card)
		# show the deck and the discard pile
		debug("Deck is now: ")
		printarray(deck)
		debug("Discard is now: ")
		printarray(discard)
		count=counthand(nick)
		# figure out what to do with the card
		processcard(card)
		# Check to see if 1 card left
		if (count == 1) {
			privmsg(channel, nick " has uno!");
		}
		# Check to see if 0 cards left
		else if (count == 0) {
			endgame(channel, nick)
			return
		}
		if (gamestate == "coloring") {
			privmsg(channel, nick ": now pick a color")
			# reset timeout
			"date +%s" | getline play_timeout
			close("date +%s")
			timeoutflag = 1
		}
		else {
			# regular card
			advanceplayer()
			if (match(discard[discard[0]], /^W4$/) != 0 || match(discard[discard[0]], /D$/) != 0) {
				privmsg(channel, players[currentplayer] " gets skipped")
				advanceplayer()
			}
			if (players[currentplayer] == mynick) {
				iplaynow(channel)
			}
			else {
				shownext(channel)
			}
		}
	}
	# handle draws
	else if (match(text, /^draw$/) != 0) {
		if (players[currentplayer] != nick) {
			return
		}
		if (gamestate != "running" ) {
			return
		}
		gamestate = "drawing"
		flag = deal(nick)
		notice(nick, "You drew a " displaycard(hands[nick, flag]))
	}
	# handle pass
	else if (match(text, /^pass$/) != 0 || match(text, /^pfft$/) != 0) {
		if (players[currentplayer] != nick) {
			return
		}
		# you can only pass if we're in the drawing state
		if (gamestate != "drawing") {
			return
		}
		# put the game back to just running
		gamestate = "running"
		advanceplayer()
		if (players[currentplayer] == mynick) {
			iplaynow(channel)
		}
		else {
			shownext(channel)
		}
	}
	else if (match(text, /^!status$/) != 0) {

	}
	# handle !stop
	else if (match(text, /^!stop$/) != 0) {
		if (gamestate == "idle") {
			return
		}
		# if it's the first player currentplayer
		if (players[1] == nick) {
			# change gamestate
			gamestate="idle"
			# announce it
			privmsg(channel, nick " ends the game")
		}
		else {
			privmsg(channel, nick ": sorry, only " players[1] " can end the game")
		}
	}
	# handle !leave
	else if (match(text, /^!leave$/) != 0) {
		if (gamestate == "idle") {
			return
		}
		# TODO check for the current player and advance if needed
		if (counthand(nick) == 0) {
			return
		}
		if (players[currentplayer] == nick && gamestate != "preparing") {
			advanceplayer()
			shownext(channel)
		}
		# TODO need checks around here 
		removeplayer(nick)
		# announce it
		privmsg(channel, nick " has left the game")
		if (players[0] < 2 && gamestate!="preparing") {
			gamestate = "idle"
			privmsg(channel, "out of players, game over")
			return
		}
	}
	else if (match(text, /^c(olor)? /) != 0) {
		if (players[currentplayer] != nick) {
			debug("not their turn to color")
			return
		}
		# you can only pass if we're in the drawing state
		if (gamestate != "coloring") {
			debug("Gamestate is " gamestate)
			return
		}
		#add color
		if (match(text, /^c(olor)? r(ed)?$/) != 0){
			colorcard="R"
		}
		else if (match(text, /^c(olor)? b(lue)?$/) != 0){
			colorcard="B"
		}
		else if (match(text, /^c(olor)? g(reen)?$/) != 0){
			colorcard="G"
		}
		else if (match(text, /^c(olor)? y(ellow)?$/) != 0){
			colorcard="Y"
		}
		else {
			# we don't know what they're trying to say
			privmsg(channel, nick ": you dumb, that's not a color")
			return
		}
		# put the game back to just running
		gamestate = "running"
		# next person's turn
		advanceplayer()
		# skip someone if needed
		if (match(discard[discard[0]], /^W4$/) != 0 || match(discard[discard[0]], /D$/) != 0) {
			privmsg(channel, players[currentplayer] " gets skipped")
			advanceplayer()
		}
		# if it's our turn
		if (players[currentplayer] == mynick) {
			iplaynow(channel)
		}
		else {
			shownext(channel)
		}
	}
	process_timers()
}

# This function should discard the played card, figure out if anyone needs to draw anything, and not advance the next player
function processcard(card) {
	# figure out if it's a special card
	if (match(card, /^W/) != 0) {
		# wild draw four
		if (match(card, /4$/) != 0) {
			# add direction once
			advanceplayer()
			# deal this person 4 cards
			if (players[currentplayer] == mynick) {
				privmsg(channel, "\x01" "ACTION gives itself four cards\x01")
				for (x = 0; x < 4; x++) {
					deal(players[currentplayer])
				}
			}
			else {
				notice(players[currentplayer], "You were forced to draw a " displaycard(hands[players[currentplayer], deal(players[currentplayer])]) ", a " displaycard(hands[players[currentplayer], deal(players[currentplayer])]) ", a " displaycard(hands[players[currentplayer], deal(players[currentplayer])]) ", and a " displaycard(hands[players[currentplayer], deal(players[currentplayer])]))
				privmsg(channel, "\x01" "ACTION gives " players[currentplayer] " four cards\x01")
			}
			# change state to waiting for color
			gamestate = "coloring"
			# deadvance
			direction = direction * -1
			advanceplayer()
			direction = direction * -1
			# if we go too low
			if (currentplayer < 1) {
				# go back to the top
				currentplayer = players[0]
			}
			# if we go too high
			else if (currentplayer > players[0]) {
				# go back to the bottom
				currentplayer = 1
			}
		}
		# plain wild
		else {
			# change state to waiting for color
			gamestate = "coloring"
		}
	}
	# draw two
	else if (match(card, /D$/) != 0) {
		# add direction once
		advanceplayer()
		# deal this person 2 cards
		if (players[currentplayer] == mynick) {
			privmsg(channel, "\x01" "ACTION gives itself two cards\x01")
			for (x = 0; x < 2; x++) {
				deal(players[currentplayer])
			}
		}
		else {
			notice(players[currentplayer], "You were forced to draw a " displaycard(hands[players[currentplayer], deal(players[currentplayer])]) " and a " displaycard(hands[players[currentplayer], deal(players[currentplayer])]))
			privmsg(channel, "\x01" "ACTION gives " players[currentplayer] " two cards\x01")
		}
		# deadvance
		direction = direction * -1
		advanceplayer()
		direction = direction * -1
	}
	# skip
	else if (match(card, /S$/) != 0) {
		# add direction once
		advanceplayer()
		if (players[currentplayer] == mynick) {
			privmsg(channel, "\x01" "ACTION gets skipped\x01")
		}
		else {
			privmsg(channel, players[currentplayer] " gets skipped")
		}
	}
	# reverse
	else if (match(card, /R$/) != 0) {
		# just swap the direction and continue
		direction = direction * -1
		# if it's just two players, it works like a skip
		if (players[0] == 2) {
			advanceplayer()
			privmsg(channel, players[currentplayer] " gets skipped")
		}
	}
}

function iplaynow(channel,	flag, card) {
	debug("My hand: " gethand(mynick))
	flag = -1
	flagrank = 0
	# figure out our current card in play
	currentcard = pop(discard)
	# push the card back on since pop is distructive
	push(discard, currentcard)
	split(currentcard, currentinfo, "")
	# figure out if i have a valid card
	debug("Figure out if i have a valid card for " currentcard)
	for(combined in hands) {
		# split the keys apart
		split(combined, separate, SUBSEP)
		# if the first key is what we want
		if (separate[1] == mynick && validatecard(hands[mynick, separate[2]]) == 0) {
			split(hands[mynick, separate[2]], cardinfo, "")
			rank=1
			if (cardinfo[1] == "W") {
				rank=4
			}
			else if (cardinfo[1] == currentinfo[1]) {
				if (cardinfo[2] == "D") {
					rank=3
				}
				else if (cardinfo[2] == "R") {
					rank=2
				}
				else if (cardinfo[2] == "S") {
					rank=2
				}
			}
			else if (cardinfo[2] == currentinfo[2]) {
				rank=1
			}
			if (rank > flagrank) {
				flag = separate[2]
				flagrank = rank
			}
			debug("I found " hands[mynick, separate[2]] " rank: " rank)
		}
	}
	# if we didn't find a valid card
	if (flag == -1) {
		debug("I don't seem to")
		# draw a card
		debug("I'm drawing a card")
		privmsg(channel, "\x01" "ACTION draws a card\x01")
		flag = deal(mynick)
		# if it's still not valid
		debug("Let's see if I can play this")
		if (validatecard(hands[mynick, flag]) != 0) {
			# pass
			debug("Lame, I can't " hands[mynick, flag])
			privmsg(channel, "\x01" "ACTION passes\x01")
			# but it's still not valid
			flag = -1
		}
	}
	# if it's valid even now
	if (flag > -1) {
		# remove our card from our hand
		card = hands[mynick, flag]
		removehand(mynick, card)
		# announce it
		debug("I can play a " card)
		privmsg(channel, "I play a " displaycard(card))
		# process our card
		processcard(card)
		debug("Moving it to the discard pile")
		push(discard, card)
		count=counthand(mynick)
		if (count == 1) {
			debug("I have UNO!")
			privmsg(channel, "UNO!")
		}
		else if (count == 0){
			debug("I won!")
			endgame(channel, mynick)
			return
		}
	}
	# we have to pick a color?
	if (gamestate == "coloring") {
		debug("We have to pick a color?")
		# let's do it randomly!
		color = int(rand() * 4)
		if (color == 0) {
			colorcard = "R"
		}
		else if (color == 1) {
			colorcard = "G"
		}
		else if (color == 2) {
			colorcard = "B"
		}
		else if (color == 3) {
			colorcard = "Y"
		}
		debug("I pick " colorcard)
		privmsg(channel, "I choose " displaycard(colorcard))
		gamestate = "running"
	}
	# skip someone if needed
	if (flag > -1 && ( match(discard[discard[0]], /^W4$/) != 0 || match(discard[discard[0]], /D$/) != 0 )) {
		advanceplayer()
		debug("I'm skipping " players[currentplayer])
		privmsg(channel, players[currentplayer] " gets skipped")
	}
	# advance to the next player
	debug("We're advancing players")
	advanceplayer()
	if (players[currentplayer] == mynick) {
		debug("Oh my turn again is it?")
		iplaynow(channel)
	}
	else {
		debug("Who goes next?")
		shownext(channel)
	}
}

function shownext(channel) {
	# Add color if wild
	if (match(discard[discard[0]], /^W/) != 0) {
		privmsg(channel, players[currentplayer] ": it's your turn. Current card is " displaycard(colorcard))
	}
	else {
		privmsg(channel, players[currentplayer] ": it's your turn. Current card is " displaycard(discard[discard[0]]))
	}
	msghand(players[currentplayer])
	# reset timeout
	"date +%s" | getline play_timeout
	close("date +%s")
	timeoutflag = 1
}

# this moves the player token to the next person
function advanceplayer() {
	debug("Currentplayer before: " currentplayer)
	currentplayer = currentplayer + direction
	debug("Currentplayer after: " currentplayer)
	# if we go too low
	if (currentplayer < 1) {
		# go back to the top
		debug("Too low")
		currentplayer = players[0]
	}
	# if we go too high
	else if (currentplayer > players[0]) {
		# go back to the bottom
		debug("Too high")
		currentplayer = 1
	}
}

function random_line(file) {
	# init our line counter
	count = 0
	# read in every line
	while(getline temp <file) {
		# inc our counter
		count++
	}
	# randomly pick one of our lines
	choosen = rand() * count
	# close our line
	close(file)
	# init our counter
	count = 0
	# read in every line
	while(getline temp <file) {
		# if we get to our random number
		if (count > choosen) {
			# return it
			return temp
		}
		# inc our counter
		count++
	}
	# return the last one regardless
	return temp
}

# this is just easier to read
function push(a,	e, i) {
	i = ++a[0]
	a[i] = e
}
function pop(a,   x,i) {
	i = a[0]--;  
	if (!i) {
		return ""
	}
	else {
		x = a[i]
		delete a[i]
		return x
	}
}

function pushm(a, x1, e,		i, j, k, combined, separate, ea, sa, eav, sav) {
	# first, find the number of elements in the second array so we know where to put our new element
	# loop for each group of major keys
	i = 0
	debug("Start of push loop for x1: " x1 " e: " e)
	split(e, ea, "")
	j=-1
	#for(combined in a) {
	#	debug("hands:" combined " " a[combined])
	#}
	# figure out how many we have in our hand
	for(combined in a) {
		split(combined, separate, SUBSEP)
		if (separate[1] == x1) {
			i++
		}
	}
	for(k=0;k<i;k++) {
		# FINDME
		split(a[x1, k], sa, "")
		debug("k:" k " i:" i)
		debug("Comparing " a[x1, k] " with " e " a:" sa[1] charlookup[sa[1]] " e:" ea[1] charlookup[ea[1]])
		if (charlookup[sa[1]] < charlookup[ea[1]]) {
			debug(sa[1] " < " ea[1])
			if (j == -1) {
				debug("This looks like a good spot for " e " " i)
				j=k
			}
		}
		else if (charlookup[sa[1]] == charlookup[ea[1]]) {
			debug(sa[1] " = " ea[1])
			sav=charlookup[sa[2]]
			if (sav == "") {
				sav=sa[2]
			}
			eav=charlookup[ea[2]]
			if (eav == "") {
				eav=ea[2]
			}
			if (sav > eav) {
				if (j == -1) {
					j=k
				}
			}
		}
	}
	debug("i: " i " j: " j)
	# if we don't know, put it at the end
	if ( j == -1) {
		#debug("Appending " e " to " x1 i)
		j=i
	}
	else {
		for(k=i-1;k>=j;k--) {
			#debug("Pushing " k " " a[x1, k] " down")
			a[x1, k+1] = a[x1, k]
		}
	}
	a[x1, j] = e
	#for(combined in a) {
	#	debug("hands:" combined " " a[combined])
	#}
	debug("")
	return j
}

function initdeck() {
	delete deck
	split("R Y G B", colors, " ")
	for(c in colors) {
		push(deck, colors[c] "0")
		for(a = 0;a < 2;a++) {
			for(b = 1;b < 10;b++) {
				push(deck, colors[c] b)
			} 
			push(deck, colors[c] "R")
			push(deck, colors[c] "S")
			push(deck, colors[c] "D")
		}
		push(deck, "W")
		push(deck, "W4")
	}
	debug("Size of deck: " deck[0])
}

function shuffledeck(x, card, card1, card2) {
	debug("Shuffing cards")
	for(x = 1;x < 500;x++) {
		card1 = int(rand() * 108) + 1
		card2 = int(rand() * 108) + 1
		card = deck[card1]
		deck[card1] = deck[card2]
		deck[card2] = card
	}
}
function printarray(deck,	x, output) {
	output = ""
	for (x = 0;x < 108;x++) {
		output = output "-" deck[x]
	}
	output = output "\n"
	debug(output)
}

function shift(a,	c, x, i) {
	debug("Popping an element off an array")
	x = a[1]
	delete a[1]
	c = a[0]
	for(i = 1;i < c;i++) {
		a[i] = a[i+1]
	}
	delete a[i]
	a[0]--;
	#debug("x: " x)
	return x
}

function deal(nick,	x, card) {
	card = shift(deck)
	debug("Dealing a " card " to " nick)
	#debug("Adding to hand")
	if (deck[0] == 0) {
		debug("Deck is empty")
		debug("Moving discard to deck")
		for(x = 1; x < discard[0]; x++) {
			deck[x] = discard[x]
		}
		debug("Shuffling deck")
		privmsg(channel, "\x01" "ACTION shuffling the discard pile back into the deck\x01")
		shuffledeck()
		
	}
	return pushm(hands, nick, card)
}

function msghand(nick) {
	debug("Showing " nick " their hand: " gethand(nick))
	notice(nick, "Your current hand is worth " points(nick) " with: " gethand(nick))
}

function gethand(nick,	output, combined, separate, i, k) {
	output = ""
	i=0
	for(combined in hands) {
		# split the keys apart
		split(combined, separate, SUBSEP)
		# if the first key is what we want
		if (separate[1] == nick) {
			i++
		}
	}
	for(k=0;k<i;k++) {
			output = output ", " displaycard(hands[nick, k])
	}
	sub(/^, /, "", output)
	return output
}

function counthand(nick, 	combined, separate) {
	count=0
	for(combined in hands) {
		# split the keys apart
		split(combined, separate, SUBSEP)
		#print separate[1] "==" nick " && " hands[nick, separate[2]] "==" card
		# if the first key is what we want
		if (separate[1] == nick) {
			count++
		}
	}
	return count
}

function searchhand(nick, card,	combined, separate) {
	for(combined in hands) {
		# split the keys apart
		split(combined, separate, SUBSEP)
		#print separate[1] "==" nick " && " hands[nick, separate[2]] "==" card
		# if the first key is what we want
		if (separate[1] == nick && hands[nick, separate[2]] == card) {
			return 0
		}
	}
	return -1
}

function removehand(nick, card,		combined, separate, flag, i) {
	for(combined in hands) {
		# split the keys apart
		split(combined, separate, SUBSEP)
		# if the first key is what we want
		if (separate[1] == nick && hands[nick, separate[2]] == card) {
			# remove the card from the hand
			delete hands[nick, separate[2]]
			break
		}
	}
	flag = -1
	# loop through all of the cards in the player's hand
	i = 0
	while (1) {
		# if we find a hole in our hand
		if (hands[nick, i] == "") {
			# if this is the first empty spot
			if (flag == -1) {
				# just remember it for our next test
				flag = i
			}
			# if this is our second empty spot
			else if (flag > -1) {
				# delete the previous card, it's a dup
				delete hands[nick, i-1]
				# break the loop, we're done
				break
			}
		}
		else {
			if (flag > -1) {
				# move our current card back one
				hands[nick, i-1] = hands[nick, i]
			}
		}
		# move to the next card
		i++
	}
	# remove the last card anyway
	delete hands[nick, i]
	return -1
}

function displaycard(card) {
	sub(/^Y/, "{y}Yellow ", card)
	sub(/^R/, "{r}Red ", card)
	sub(/^B/, "{b}Blue ", card)
	sub(/^G/, "{g}Green ", card)
	sub(/R$/, "Reverse", card)
	sub(/S$/, "Skip", card)
	sub(/D$/, "Draw Two", card)
	sub(/^W$/, "{y}W{b}I{r}L{g}D", card)
	sub(/^W4$/, "{y}W{b}I{r}L{g}D{x} Draw Four", card)
	card=card "{x}"
	return card
}

function validatecard(card,	carda, currentcard, currentcarda) {
	# divide up what we're checking
	split(card, carda, "")
	# if it's wild, it's good
	if (carda[1] == "W") {
		return "0"
	}
	# pop off our current discard
	currentcard = pop(discard)
	debug("Validating " card " against " currentcard)
	# push the card back on since pop is distructive
	push(discard, currentcard)
	# divide up what we're checking against
	split(currentcard, currentcarda, "")
	# if the current card is wild, check colorcard
	if (currentcarda[1] == "W") {
		debug("but it's really wild, so check: " carda[1] " against " colorcard)
		# if we match up our color card
		if (carda[1] == colorcard) {
			# we're good
			return "0"
		}
		# if the current card is wild as well
		else if (carda[1] == "W") {
			# we're good
			return "0"
		}
		# it's not good
		return "-1"
	}
	# if the color is the same
	if (carda[1] == currentcarda[1]) {
		# we're good
		return "0"
	}
	# if the type of card is the same
	else if (carda[2] == currentcarda[2]) {
		# we're good
		return "0"
	}
	# otherwise it's bad
	return "-1"
}

function points(nick,	combined,	separate, card, count) {
	count=0
	card=""
	for(combined in hands) {
		# split the keys apart
		split(combined, separate, SUBSEP)
		# if the first key is what we want
		if (separate[1] == nick) {
			if (match(hands[nick, separate[2]], /^W/) != 0) {
				count = count + 50
			}
			else if (match(hands[nick, separate[2]], /D$/) != 0) {
				count = count + 20
			}
			else if (match(hands[nick, separate[2]], /R$/) != 0) {
				count = count + 20
			}
			else if (match(hands[nick, separate[2]], /S$/) != 0) {
				count = count + 20
			}
			else {
				card=hands[nick, separate[2]]
				sub(/^./, "", card)
				count = count + card
			}
			#print separate[1] "==" nick " && " hands[nick, separate[2]] "==" card
		}
	}
	return count
}

function removeplayer(nick,	x) {
	# if current player is the one removing, advance
	if (players[currentplayer] == nick) {
		advanceplayer()
	}
	# remove the player from the array
	for (x = 1;x < players[0];x++) {
		if(players[x] == nick) {
			delete players[x]
			break
		}
	}
	# move everyone up
	for (1; x < players[0]; x++) {
		players[x] = players[x+1]
	}
	delete players[players[0]]
	players[0]--
	debug("Players is now: ")
	printarray(players)
	# return all cards to the discard pile
	card=pop(discard)
	for(combined in hands) {
		# split the keys apart
		split(combined, separate, SUBSEP)
		# if the first key is what we want
		if (separate[1] == nick) {
			push(discard, hands[nick, separate[2]])
			delete hands[nick, separate[2]]
		}
	}
	push(discard, card)
}

function endgame(channel, nick,	x, i, score) {
	privmsg(channel, nick " wins!");
	gamestate = "idle"
	timeoutflag = 0
	removeplayer(nick)
	score=0
	for(x = 1; x <= players[0]; x++) {
		i = points(players[x])
		privmsg(channel, players[x] " had " i " points with " gethand(players[x]))
		score = score + i
	}
}
