BEGIN {
mynick = "Gir"

## gameplay
# test starting a game while idle
resetgame()
printferr("Testing start game while idle: ")
process_channel_msg("test", "tester", "!uno")
outputtest("PRIVMSG test :tester started a new game of .*! Type !join before play starts to join in. Type !leave at any time, but you can't come back.\nPRIVMSG test :tester: Type !start when ready to play. !stop to stop the game.\nNOTICE tester :Your current hand is.*\n")

# test starting the game without a bot
resetbuffers()
printferr("Testing starting a game with one person: ")
delete deck
push(deck, "R0")
push(deck, "R1")
push(deck, "R2")
push(deck, "R3")
push(deck, "R4")
push(deck, "R5")
push(deck, "R6")
push(deck, "R7")
push(deck, "R8")
process_channel_msg("test", "tester", "!start")
outputtest("PRIVMSG test :I'mma play too!.*PRIVMSG test :tester starts with current card:.*\nPRIVMSG test :tester: it's your turn. Current card is .*NOTICE tester :Your current hand is:.*\n")

# test stopping a game
resetbuffers()
printferr("Testing stop game: ")
process_channel_msg("test", "tester", "!stop")
outputtest("PRIVMSG test :tester ends the game\n")
}
