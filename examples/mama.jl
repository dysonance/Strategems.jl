using Strategems, Temporal, Indicators, Base.Dates
using Base.Test

# define universe and gather data
assets = ["CHRIS/CME_CL1", "CHRIS/CME_RB1"]
universe = Universe(["CHRIS/CME_CL1", "CHRIS/CME_RB1"])
function datasource(asset::String; save_downloads::Bool=true)::TS
    savedata_path = Pkg.dir("Strategems", "data/$asset.csv")
    if isfile(savedata_path)
        return Temporal.tsread(savedata_path)
    else
        X = quandl(asset)
        if save_downloads
            Temporal.tswrite(X, savedata_path)
        end
        return X
    end
end
gather!(universe, source=datasource)

# define indicators and parameter space
arg_names = [:fastlimit, :slowlimit]
arg_defaults = [0.5, 0.05]
arg_ranges = [0.01:0.01:0.99, 0.01:0.01:0.99]
paramset = ParameterSet(arg_names, arg_defaults, arg_ranges)
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
backtest!(strat)

# optimize over indicator parameter space
output = optimize(strat)
