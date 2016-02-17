BEGIN {
mynick = "Gir"
channel="#test"

## game start and stop
# test starting a game while a game is running
resetgame()
push(players, "tester")

push(deck, "Y8")
push(deck, "W4")
push(deck, "BD")
push(deck, "R8")
push(deck, "Y5")
push(deck, "Y0")
push(deck, "Y6")

debuglevel=1
while(deck[0] > 0) {
	deal("tester")
}

debuglevel=0
print "{y}W{b}I{r}L{g}D{x} Draw Four{x}, {y}Yellow 8{x}, {y}Yellow 0{x}, {b}Blue Draw Two{x}, {y}Yellow 5{x}, {y}Yellow 6{x}, {r}Red 8{x}"
print gethand("tester")
}
