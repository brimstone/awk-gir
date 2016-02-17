BEGIN {
mynick = "Gir"

## gameplay
# test starting a game while idle
resetgame()
printferr("Testing start game while idle: ")
process_channel_msg("test", "tester", "!uno")
outputtest("PRIVMSG test :tester started a new game of .*! Type !join before play starts to join in. Type !leave at any time, but you can't come back.\nPRIVMSG test :tester: Type !start when ready to play. !stop to stop the game.\nNOTICE tester :Your current hand is.*\n")

# test joining a game
resetbuffers()
printferr("Testing joining a game: ")
process_channel_msg("test", "tester2", "!join")
outputtest("PRIVMSG test :tester2 joins the game\nNOTICE tester2 :Your current hand is:.*\n")

# test stopping a game
resetbuffers()
printferr("Testing leaving a game: ")
process_channel_msg("test", "tester2", "!leave")
outputtest("PRIVMSG test :tester2 has left the game\n")
}
