BEGIN {
mynick = "Gir"
channel="#test"

## game start and stop
# test starting a game while a game is running
resetgame()
initdeck()
shuffledeck()

process_channel_msg(channel, "tester", "!uno")
resetbuffers()
process_channel_msg(channel, "tester", "!start")
print output
resetbuffers()

debuglevel=1
printarray(deck)
iplaynow(channel)
debuglevel=0
outputtest("")
}
