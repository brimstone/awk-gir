BEGIN {
mynick = "Gir"

## gameplay
# test joining a game not in progress
resetgame()
printferr("Testing joining a game not in progress: ")
process_channel_msg("##gen", "shapr", "!join")
outputtest("PRIVMSG ##gen :shapr: No game is running. Type !uno to start it\n")
}
