using Strategems, Temporal, Indicators, Base.Dates
using Base.Test

# define universe and gather data
assets = ["Corn"]
universe = Universe(assets)
@test universe.assets == assets
gather!(universe, source=(asset)->Temporal.tsread("$(Pkg.dir("Temporal"))/data/$asset.csv"))
@test length(setdiff(assets, collect(keys(universe.data)))) == 0

# define indicators and parameter space
arg_names = [:fastlimit, :slowlimit]
arg_defaults = [0.5, 0.05]
#FIXME: get_param_combos breaking with other argument ranges
arg_ranges = [0.05:0.25:0.99, 0.05:0.25:0.95]
paramset = ParameterSet(arg_names, arg_defaults, arg_ranges)
@test paramset.arg_names == arg_names
f(x; args...) = Indicators.mama(Temporal.hl2(x); args...)
indicator = Indicator(f, paramset)

# define signals
signals = Dict{Symbol,Signal}(:GoLong=>Signal(:(MAMA ↑ FAMA)),
                              :GoShort=>Signal(:(MAMA ↓ FAMA)))

# define the trading rule
rules = Dict{Symbol,Rule}(:EnterLong=>Rule(:GoLong, :(buy,asset,100)),
                          :EnterShort=>Rule(:GoShort, :(sell,asset,100)))

# strategy object
strat = Strategy(universe, indicator, signals, rules)
generate_trades!(strat)
backtest!(strat)
optimize!(strat)
@test size(strat.results.optimization,1) == get_n_runs(paramset)
@test size(strat.results.optimization,2) == length(arg_names)+1
@test strat.results.optimization[:,1:length(arg_names)] == get_param_combos(paramset)
