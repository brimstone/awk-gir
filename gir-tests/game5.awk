BEGIN {
mynick = "Gir"
channel = "#test"

## gameplay
# test starting a game while idle
resetgame()
# TODO stack the deck
push(deck, "R0")
push(deck, "B1")
push(deck, "Y2")
push(deck, "G3")
push(deck, "R4")
push(deck, "R5")
push(deck, "R6")

push(deck, "RD")
push(deck, "B1")
push(deck, "Y2")
push(deck, "R3")
push(deck, "G4")
push(deck, "B5")
push(deck, "B6")

push(deck, "Y0")
push(deck, "Y1")
push(deck, "Y2")
push(deck, "Y3")
push(deck, "Y4")
push(deck, "Y5")
push(deck, "Y6")
# TODO stack the player hands
push(players, "tester")
for (x = 0; x < 7; x++) {
	deal("tester")
}
push(players, mynick)
for (x = 0; x < 7; x++) {
	deal(mynick)
}
# TODO tester starts
gamestate="preparing"
printferr("Testing starting game when idle: ")
process_channel_msg("test", "tester", "!start")
outputtest("PRIVMSG test :tester starts with current card: \x038Yellow 0\x0f\nPRIVMSG test :tester: it's your turn. Current card is \x038Yellow 0\x0f\nNOTICE tester :Your current hand is: \x034Red 0\x0f, \x032Blue 1\x0f, \x038Yellow 2\x0f, \x033Green 3\x0f, \x034Red 4\x0f, \x034Red 5\x0f, \x034Red 6\x0f\n")

# TODO tester plays top card
resetbuffers()
printferr("Testing player playing card: ")
debuglevel=1
process_channel_msg("test", "tester", "p r 0")
# TODO bot plays it's top card, a RD
outputtest("")
printferr("Testing bot playing draw card: ")
}
