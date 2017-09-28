#=
Type definition and methods containing the overarching backtesting object fueling the engine
=#

mutable struct Strategy
    universe::Universe
    indicators::Dict{String,Indicator}
    rules::Dict{String,Rule}
    portfolio
    account
    results
end
