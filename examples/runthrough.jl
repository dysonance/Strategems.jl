using Strategems, Temporal, Indicators, Base.Dates

# define universe and gather data
universe = Universe(["CHRIS/CME_CL1", "CHRIS/CME_RB1"])
gather!(universe)

# define indicators and parameter space
indicator = Indicator((x;args...)->Indicators.mama(Temporal.hl2(x);args...),
                      ParameterSet([:fastlimit, :slowlimit], [0.5, 0.05]))

# define signals
signals = Dict{Symbol,Signal}(:GoLong=>Signal(:(MAMA ↑ FAMA)),
                              :GoShort=>Signal(:(MAMA ↓ FAMA)))

# define the trading rule
#TODO: throwaway functions for now, still have to build definitions
buy(asset::String, amount::Int) = 2+2
sell(asset::String, amount::Int) = 2+2
rules = Dict{Symbol,Rule}(:EnterLong=>Rule(:GoLong, :(buy,asset,100)),
                          :EnterShort=>Rule(:GoShort, :(sell,asset,100)))

#TODO: portfolio
portfolio = :portfolio
#TODO: account
account = :account
#TODO: results
results = :results

# strategy object
strat = Strategy(universe,
                 indicator,
                 signals,
                 rules,
                 portfolio,
                 account,
                 results)

trades = generate_trades(strat)

asset = "CHRIS/CME_CL1"
summary = [strat.universe.data[asset] strat.indicators[asset].data trades[asset]]

