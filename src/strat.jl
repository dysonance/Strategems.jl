# SETUP ########################################################################
workspace()
using Temporal
using Indicators
abstract Strategem

# CALCS ########################################################################
#TODO: control calc output names
#TODO: allow for multiple parameters

type Calc <: Strategem
    fun::Function
    input::Vector{Symbol}
    par::Expr
    rng::AbstractArray
    lag::Bool
    function Calc(fun::Function, input::Vector{Symbol}, par::Expr, rng::AbstractArray=0:0, lag::Bool=true)
        new(fun, input, par, rng, lag)
    end
end
Calc(fun::Function, input::Symbol, par::Expr, rng::AbstractArray=0:0, lag::Bool=true) = Calc(fun, [input], par, rng, lag)

# SIGNALS ######################################################################
type Signal <: Strategem
    left::Symbol
    fun::Function
    right::Symbol
end

# RULES ########################################################################


# SIMULATIONS ##################################################################
type Strategy <: Strategem
    universe::Dict
    calcs::Dict
    signals::Dict
    # rules::Vector{Rule}
end
function backtest!(strat::Strategy)
    for sym in keys(strat.universe)
        print("Backtesting $sym...")
        print("Running calculations...")
        for c in keys(strat.calcs)
            if strat.calcs[c].lag
                out = lag(strat.calcs[c].fun(strat.universe[sym][strat.calcs[c].input]; strat.calcs[c].par.args))
            else
                out = strat.calcs[c].fun(strat.universe[sym][strat.calcs[c].input]; strat.calcs[c].par.args)
            end
            if size(out,2) == 1
                out.fields = [c]
            else
                out.fields = map((s) -> Symbol("$(string(c))$(string(s))"), out.fields)
            end
            strat.universe[sym] = [strat.universe[sym] out]
        end
        print("Generating signals...")
        # sigs = falses(strat.universe[sym])[:,1:length(strat.signals)]
        # sigs.fields = map((s) -> Symbol(string(s)), keys(strat.signals))
        for s in keys(strat.signals)
            strat.universe[sym] = [strat.universe[sym] strat.signals[s].fun(strat.universe[sym][strat.signals[s].left], strat.universe[sym][strat.signals[s].right])]
        end
        strat.universe[sym].fields[end-length(strat.signals)+1:end] = map((k)->Symbol(k),keys(strat.signals))
        print("Processing transactions...")
        print("Done.\n")
    end
end

# DATA #########################################################################
tickers = ["XLY","XLP","XLE","XLF","XLV","XLI","XLB","XLK","XLU"]
universe = Dict()
for t in tickers
    print("Downloading data for $t...")
    universe[t] = yahoo(t)
    print("Done.\n")
end

calcs = Dict()
calcs[:ShortMA] = Calc(ema, [:AdjClose], :(n=40), 20:5:80)
calcs[:LongMA] = Calc(sma, [:AdjClose], :(n=200), 100:20:300)

sigs = Dict()
sigs[:Long] = Signal(:ShortMA, >, :LongMA)
sigs[:Short] = Signal(:ShortMA, <, :LongMA)
sigs[:Exit] = Signal(:ShortMA, ==, :LongMA)

strat = Strategy(universe, calcs, sigs)
