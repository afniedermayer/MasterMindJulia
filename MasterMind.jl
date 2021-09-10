module MasterMind

export empty_, blue, red, black, white, green, yellow,  Guess, Answer, random_guess,
    compare, FrequencyList, play_manually, play_automatically, play, npegs, ncolors, incr


using StatsBase
using StaticArrays

import Base: values

@enum Color::Int empty_ blue red black white green yellow
const ncolors = length(instances(Color))
const color_letters = Dict(
    "e" => empty_, "b" => blue, "r" => red, "k" => black,
    "w" => white, "g" => green, "y" => yellow
)

const npegs = 4
struct Guess
    pegs::SVector{npegs, Color}
end
Guess() = Guess(fill(empty_, npegs))
Guess(s::String) = Guess([color_letters[string(c)] for c in s])
Base.show(io::IO, g::Guess) = print(io, "[", join(replace.(string.(g.pegs), "_" => ""), " "), "]")


random_color() = Color(rand(0:ncolors-1))
random_color(n) = Color.(rand(0:ncolors-1, n))
random_guess() = Guess(random_color(npegs))

struct Answer
    blacks::Int
    whites::Int
end
all_black(a::Answer) = a.blacks == npegs
Base.show(io::IO, a::Answer) = print(io, "[blacks=$(a.blacks) whites=$(a.whites)]")

function compare(g1::Guess, g2::Guess)
    blacks, whites = 0, 0
    used1 = @MVector zeros(Bool, npegs)
    used2 = @MVector zeros(Bool, npegs)
    @inbounds @simd for i = 1:npegs
        if g1.pegs[i] == g2.pegs[i]
            blacks += 1
            used1[i], used2[i] = true, true
        end
    end
    @inbounds for i = 1:npegs
        for j = 1:npegs
            if i != j && !used1[i] && !used2[j] && g1.pegs[i] == g2.pegs[j]
                whites += 1
                used1[i], used2[j] = true, true
            end
        end
    end
    return Answer(blacks, whites)
end

struct Fact
    guess::Guess
    answer::Answer
end

allows(f::Fact, g::Guess) = f.answer == compare(f.guess, g)
allows(fs::Vector{Fact}, g::Guess) = all(allows(f, g) for f in fs)

const frequency_list_size = (npegs+1)^2
struct FrequencyList
    value::MVector{frequency_list_size, Int}
end
FrequencyList() = FrequencyList(zero(MVector{frequency_list_size, Int}))
index(a::Answer) = (npegs+1)*a.blacks + a.whites + 1
count_allblacks(fl::FrequencyList) = fl.value[index(Answer(npegs, 0))]
values(fl::FrequencyList) = fl.value
incr(fl::FrequencyList, answer) = fl.value[index(answer)] += 1

function info_value(fl::FrequencyList)
    ntot = frequency_list_size
    r = sum(v!=1 ? -v*log(v) : 0.0 for v in values(fl) if v!=0)
    return (r/ntot + log(ntot)) / log(2.0)
end

function calculate_all_guesses!(result, prev_colors, npegs=npegs)
    if length(prev_colors) == npegs
        push!(result, Guess(prev_colors))
    else
        for color in instances(Color)
            calculate_all_guesses!(result, [prev_colors; color], npegs)
        end
    end
end

function calculate_all_guesses(npegs=npegs)
    result = Guess[]
    calculate_all_guesses!(result, Color[], npegs)
    return result
end

const all_guesses = calculate_all_guesses();

@enum GameState notfound found impossible


const fixed_first_guess = Guess([yellow, blue, red, black])
const random_first_guess = false

function first_guess()
    if !random_first_guess
        return fixed_first_guess
    end
    replace = ncolors < npegs
    return Guess(sample(collect(instances(Color)), npegs, replace=replace))
end

function make_guess(facts::Vector{Fact})
    if length(facts) == 0
        return first_guess(), notfound, ncolors^npegs
    end
    possible_solutions = [guess for guess in all_guesses if allows(facts, guess)]
    if length(possible_solutions) == 1
        return possible_solutions[1], found, 1
    elseif length(possible_solutions) == 0
        return Guess(), impossible, 0
    end
    info_values = zeros(length(all_guesses))
    Threads.@threads for i = 1:length(all_guesses)
        guess = all_guesses[i]
        fl = FrequencyList()
        for solution in possible_solutions
            answer = compare(guess, solution)
            incr(fl, answer)
        end
        info_values[i] = info_value(fl)
    end
    max_info_value = maximum(info_values)
    idx_best_guesses = findall((x->x==max_info_value), info_values)
    for idx in idx_best_guesses
        if allows(facts, all_guesses[idx])
            return all_guesses[idx], notfound, length(possible_solutions)
        end
    end
    return all_guesses[idx_best_guesses[1]], notfound, length(possible_solutions)
end

function play(ask)
    facts = Vector{Fact}()
    guess, state = Guess(), notfound
    counter = 0
    while state == notfound
        @time guess, state, possibilities = make_guess(facts)
        println("$possibilities possible solutions left.")
        if state == impossible
            break
        end
        answer = ask(guess)
        if answer == nothing
            println("quitting")
            return
        elseif all_black(answer)
            state = found
        else
            push!(facts, Fact(guess, answer))
        end
        counter += 1
    end
    if state == found
        println("Found solution: $guess in $counter steps.")
    else
        println("No solution possible!")
    end
end

function play_automatically(solution)
    function ask(guess)
        answer = compare(guess, solution)
        @show guess answer
        return answer
    end
    play(ask)
end

function play_manually()
    println("Please think of a color for $npegs pegs.")
    println("Possible colors are $(instances(Color)).")
    println("For each question, respond with the number of black pegs and white pegs, separated by a space.")
    println("Enter 'q' to quit.")
    function ask(guess)
        println()
        println("My guess is $guess.")
        println("Black pegs, white pegs?")
        response = readline()
        if startswith(response, "q")
            return nothing
        else
            blacks, whites = parse.(Int, split(response))
            return Answer(blacks, whites)
        end
    end
    play(ask)
end
end
