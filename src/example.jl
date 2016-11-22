# DEPENDENCIES #################################################################
using Temporal
using Indicators
include("strat.jl")
getdata = false

# DATA #########################################################################
tickers = ["XLY","XLP","XLE","XLF","XLV","XLI","XLB","XLK","XLU"]
if getdata
    universe = Dict{Symbol,TS}()
    for t in tickers
        print("Downloading data for $t...")
        universe[Symbol(t)] = yahoo(t)
        print("Done.\n")
    end
end

# SETUP ########################################################################
calcs = Dict{Symbol,Expr}()
calcs[:ShortMA] = :(sma(X, n=40))
calcs[:LongMA] = :(sma(X, n=200))

sigs = Dict{Symbol,Expr}()
sigs[:Long] = :(crossover(ShortMA, LongMA))
sigs[:Short] = :(crossunder(ShortMA, LongMA))


strat = Strategy(universe, calcs, sigs)
