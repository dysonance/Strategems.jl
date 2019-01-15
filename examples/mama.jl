using Strategems, Temporal, Indicators, Dates, Pkg

# define universe and gather data
assets = ["CME_CL1", "CME_RB1"]
universe = Universe(assets)
function datasource(asset::String; save_downloads::Bool=true)::TS
    savedata_path = joinpath(dirname(pathof(Strategems)), "..", "data", "test", "$asset.csv")
    if isfile(savedata_path)
        return Temporal.tsread(savedata_path)
    else
        X = quandl("CHRIS/$asset")
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
f(x; args...) = Indicators.mama(x; args...)
indicator = Indicator(f, paramset)

# define signals that will trigger trading decisions
siglong = @signal MAMA ↑ FAMA
sigshort = @signal MAMA ↓ FAMA
sigexit = @signal MAMA == FAMA

# define the trading rules
longrule = @rule siglong → long 100
shortrule = @rule sigshort → short 100
exitrule = @rule sigexit → liquidate 1.0
rules = (longrule, shortrule, exitrule)

# run strategy
strat = Strategy(universe, indicator, rules)
backtest!(strat)
optimize!(strat, samples=10)
