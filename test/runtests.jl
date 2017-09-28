using Strategems, Temporal, Indicators, Base.Dates
using Base.Test

# define universe and gather data
assets = ["CHRIS/CME_CL1", "CHRIS/CME_RB1"]
universe = Universe(["CHRIS/CME_CL1", "CHRIS/CME_RB1"])
@test universe.assets == assets
gather!(universe)
@test length(setdiff(assets, collect(keys(universe.data)))) == 0

# define indicators and parameter space
arg_names = [:fastlimit, :slowlimit]
arg_defaults = [0.5, 0.05]
paramset = ParameterSet(arg_names, arg_defaults)
@test paramset.arg_names == arg_names
f(x; args...) = Indicators.mama(Temporal.hl2(x); args...)
indicator = Indicator(f, paramset)
indicators = generate_dict(universe, indicator)
@test length(setdiff(assets, collect(keys(indicators)))) == 0

# define the trading rule
#TODO: throwaway functions for now, still have to build definitions
buy(asset::String, amount::Int) = 2+2
sell(asset::String, amount::Int) = 2+2
# long side logic
long_trigger = :(MAMA ↑ FAMA)  # note the up arrow infix operator defined to alias crossover function
long_action = :(buy(asset, 100))  # note the down arrow infix operator defined to alias crossunder function
long_rule = Rule(long_trigger, long_action)
# short side logic
short_trigger = :(MAMA ↓ FAMA)
short_action = :(sell(asset, 100))
short_rule = Rule(short_trigger, short_action)
# combine the rules
rules = Dict{Symbol,Rule}(:GoLong=>long_rule, :GoShort=>short_rule)

#TODO: portfolio
portfolio = :portfolio
#TODO: account
account = :account
#TODO: results
results = :results

# strategy object
strat = Strategy(universe,
                 indicators,
                 rules,
                 portfolio,
                 account,
                 results)

trades = generate_trades(strat)
