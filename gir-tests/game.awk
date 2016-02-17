BEGIN {
mynick = "Gir"
channel="#test"

## game start and stop
# test starting a game while a game is running
resetgame()
initdeck()
shuffledeck()

resetbuffers()
process_channel_msg(channel, "tester", "!uno")
outputtest("")
}
