using Strategems, Temporal, Indicators, Base.Dates
using Base.Test

# define universe and gather data
assets = ["EOD/AAPL", "EOD/MCD", "EOD/JPM", "EOD/MMM", "EOD/XOM"]
universe = Universe(assets)
gather!(universe)

# define indicator and parameters
function fun(x::TS; args...)::TS
    close_prices = cl(x)
    moving_average = sma(close_prices; args...)
    output = [close_prices moving_average]
    output.fields = [:Close, :MA]
    return output
end

#TODO: define method for when only one parameter is needed where it automatically puts things in vectors
# (so that you could call this by doing `ParameterSet(:n, 50)`)
indicator = Indicator(fun, ParameterSet([:n], [50]))

# define signals
signals = Dict{Symbol,Signal}(:GoLong => Signal(:(Close ↑ MA)),
                              :GoShort => Signal(:(Close ↓ MA)))

# define trading rules
rules = Dict{Symbol,Rule}(:EnterLong => Rule(:GoLong, :(buy,asset,100)),
                          :EnterShort => Rule(:GoShort, :(sell,asset,100)))

# construct and test the strategy
strat = Strategy(universe, indicator, signals, rules)

#TODO: auto-generate trades within backtest if trades aren't there yet
generate_trades!(strat)

#TODO: make trade fields keyword arguments
#TODO: print diagnostic information while running backtest
backtest!(strat, :Open, :Close)

