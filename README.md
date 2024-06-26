# MasterMindJulia

Software that guesses the color combination in the [MasterMind](https://en.wikipedia.org/wiki/Mastermind_%28board_game%29) game. It chooses the guess with the highest [information entropy](https://en.wikipedia.org/wiki/Entropy_(information_theory)). This minimizes the number of steps needed to guess the correct combination.

To run the code, run in the command line
```
julia run_mastermind.jl
```
The computer will play a MasterMind game against itself automatically and measure the time it takes to guess.

You can also think of a color combination and let the computer guess. To do this, you need to modify the file [run_mastermind.jl](run_mastermind.jl) For this, comment out the lines 
```julia
play_automatically(Guess([red,white,green,empty_]))
@time play_automatically(Guess([red,white,green,empty_]))
```
and uncomment the line
```julia
#play_manually()
```
