BEGIN {
mynick = "Gir"

## game start and stop
# test starting a game while a game is running
resetgame()
gamestate="running"
printferr("Testing start game while a game is running: ")
process_channel_msg("test", "tester", "!uno")
outputtest("PRIVMSG test :tester: we're already playing\n")

# test starting a game while idle
resetgame()
printferr("Testing start game while idle: ")
process_channel_msg("test", "tester", "!uno")
outputtest("PRIVMSG test :tester started a new game of .*! Type !join before play starts to join in. Type !leave at any time, but you can't come back.\nPRIVMSG test :tester: Type !start when ready to play. !stop to stop the game.\nNOTICE tester :Your current hand is.*\n")

# test stopping a game
resetbuffers()
printferr("Testing stop game: ")
process_channel_msg("test", "tester", "!stop")
outputtest("PRIVMSG test :tester ends the game\n")
}
