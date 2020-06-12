using Strategems, Indicators, Temporal, Dates
using Plots

# define universe and gather data
assets = ["CHRIS/CME_CL1", "CHRIS/CME_RB1"]
function datasource(asset::String; save_downloads::Bool=true)::TS
    savedata_path = joinpath(dirname(pathof(Strategems)), "..", "data", "$asset.csv")
    if isfile(savedata_path)
        return Temporal.tsread(savedata_path)
    else
        X = quandl(asset)
        if save_downloads
            if !isdir(dirname(savedata_path))
                mkdir(dirname(savedata_path))
            end
            Temporal.tswrite(X, savedata_path)
        end
        return X
    end
end

function run(samples::Int64=0)
    # gather!(universe, source=datasource)
    universe = gather(assets, source=datasource)

    # define indicators and parameter space
    arg_names     = [:fastlimit, :slowlimit]
    arg_defaults  = [0.5, 0.05]
    arg_ranges    = [0.01:0.01:0.99, 0.01:0.01:0.99]
    paramset      = ParameterSet(arg_names, arg_defaults, arg_ranges)
    f(x; args...) = Indicators.mama(x; args...)
    indicator     = Indicator(f, paramset)

    # define signals that will trigger trading decisions
    # note the uparrow infix operator is defined to simplify one variable crossing over another
    # (similarly for the downarrow infix operator for crossing under)
    siglong  = @signal MAMA ↑ FAMA
    sigshort = @signal MAMA ↓ FAMA
    sigexit  = @signal MAMA == FAMA

    # define the trading rules
    longrule  = @rule siglong → long 100
    shortrule = @rule sigshort → short 100
    exitrule  = @rule sigexit → liquidate 1.0
    rules     = (longrule, shortrule, exitrule)

    # run strategy
    strat = Strategy(universe, indicator, rules)
    # results = backtest(strat)
    opt = optimize(strat, samples=samples)  # randomly sample the parameter space (0 -> use all combinations)

    # cumulative pnl for each combination of the parameter space
    (strat, opt)
end

# visualizing results with the Plots.jl package
function vis(opt)
    gr()
    (x, y, z) = (opt[:,i] for i in 1:3)
    surface(x, y, z)
end

strat, opt = run(1000)
vis(opt)
return nothing
