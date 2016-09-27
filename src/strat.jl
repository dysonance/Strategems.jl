# SETUP ########################################################################
using Temporal
using Indicators
abstract Strategem

# DATA #########################################################################
tickers = ["XLY","XLP","XLE","XLF","XLV","XLI","XLB","XLK","XLU"]
universe = Dict()
for t in tickers
    print("Downloading data for $t...")
    universe[t] = yahoo(t)
    print("Done.\n")
end

# CALCS ########################################################################
type Parameter <: Strategem
    val
    pos::Int
    kw::String
    rng::AbstractArray
    function Parameter(val, pos, kw, rng=0:0)
        @assert pos >= 0 "`pos` argument must be non-negative."
        if pos == 0 && kw == ""
            error("If `pos` is zero, keyword argument name `kw` must be given.")
        elseif pos != 0
            kw = ""
        end
        new(val, pos, kw, rng)
    end
end
type Calc <: Strategem
    fld::Symbol
    fun::Function
    par::Parameter
    name::Symbol
    lag::Bool
end


# RULES ########################################################################
abstract Trade
type Buy <: Trade
    qty::Number
    prc::Symbol
end
type Sell <: Trade
    qty::Number
    prc::Symbol
end
type Signal <: Strategem
    left::Symbol
    comparison::Function
    right::Symbol
    name::Symbol
end


# SIMULATIONS ##################################################################
type Strategy <: Strategem
    universe::Dict
    calcs::Vector{Calc}
    signals::Vector{Signal}
    # rules::Vector{Rule}
end

function backtest!(strat::Strategy)
    for sym in keys(strat.universe)
        print("Backtesting $sym...")
        print("Running calculations...")
        for calc in strat.calcs
            if calc.lag
                strat.universe[sym] = [strat.universe[sym] lag(calc.fun(strat.universe[sym][calc.fld], calc.par.val))]
            else
                strat.universe[sym] = [strat.universe[sym] calc.fun(strat.universe[sym][calc.fld], calc.par.val)]
            end
            strat.universe[sym].fields[end] = calc.name
        end
        print("Generating signals...")
        for sig in strat.signals
            strat.universe[sym] = [strat.universe[sym] sig.comparison(strat.universe[sym][sig.left], strat.universe[sym][sig.right])]
            strat.universe[sym].fields[end] = sig.name
        end
        print("Processing transactions...")
        print("Done.\n")
    end
end

short_ma = Calc(:AdjClose, sma, Parameter(40, 1, "", 20:80), :ShortMA, true)
long_ma = Calc(:AdjClose, sma, Parameter(200, 1, "", 100:200), :LongMA, true)
longsig = Signal(:ShortMA, >, :LongMA, :Long)
sellsig = Signal(:ShortMA, <, :LongMA, :Short)
exitsig = Signal(:ShortMA, ==, :LongMA, :Exit)
strat = Strategy(universe, [short_ma,long_ma], [longsig,sellsig,exitsig])
