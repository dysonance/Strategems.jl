using Stratems, Temporal, Indicators, Base.Dates

# define universe and gather data
universe = Universe(["CHRIS/CME_CL1", "CHRIS/CME_RB1"])
gather!(universe)

# define indicators and parameter space
paramset = ParameterSet([:fastlimit, :slowlimit], [0.5, 0.05])
f(x; args...) = Indicators.mama(Temporal.hl2(x); args...)
indicator = Indicator(f, paramset)
indicators = generate_dict(universe, indicator)

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
rules = Dict(:GoLong=>long_rule, :GoShort=>short_rule)

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
