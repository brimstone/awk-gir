BEGIN {
mynick = "Gir"

################################################################################
## function tests
# test printarray
resetbuffers()
printferr("Testing printarray: ")
split("R1,B2,G3,Y4,W,W4", deck, "/,/")
printarray(deck)
outputtest("")

#TODO processcard
#TODO iplaynow
#TODO shownext
#TODO advanceplayer
#TODO random_line
#TODO push
#TODO pop
#TODO pushm
#TODO initdeck
#TODO shuffledeck
#TODO shift
#TODO deal
#TODO msghand
#TODO gethand
#TODO counthand
#TODO searchhand
#TODO removehand
#TODO displaycard
#TODO validatecard
#TODO points
#TODO removeplayer
#TODO endgame
}
