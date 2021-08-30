include("MasterMind.jl")
using .MasterMind

println("*** Play Automatically ***")
# warm up for JIT
play_automatically(Guess([red,white,green,empty_]))
@time play_automatically(Guess([red,white,green,empty_]))

println()
println("*** Play Manually ***")
#play_manually()

println()
println("*** Benchmarks ***")
using BenchmarkTools

function print_benchmark(benchmark)
    io = IOBuffer()
    show(io, "text/plain", benchmark)
    println(String(take!(io)))
end

println("\nBenchmark compare two guesses")
let g1 = random_guess(), g2 = random_guess()
    b = @benchmark answer = compare($g1, $g2)
    print_benchmark(b)
end

println("\nBenchmark get element from FrequencyList")
let g1 = random_guess(), g2 = random_guess()
    answer = compare(g1, g2)
    fl = FrequencyList()
    b = @benchmark $fl.fl[$answer] = get($fl.fl, $answer, 0) + 1
    print_benchmark(b)
end
