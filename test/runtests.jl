using Strategems, Temporal, Indicators, Base.Dates
using Base.Test

# define universe and gather data
assets = ["Corn"]
@testset "Universe" begin
    @testset "Construct" begin
        universe = Universe(assets)
    end
    @testset "Gather" begin
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
    end
end

# define indicators and parameter space
@testset "Parameter Set" begin
    arg_names     = [:fastlimit, :slowlimit]
    arg_defaults  = [0.5, 0.05]
    arg_ranges    = [0.01:0.01:0.99, 0.01:0.01:0.99]
    paramset      = ParameterSet(arg_names, arg_defaults, arg_ranges)
end

@testset "Indicator" begin
    f(x; args...) = Indicators.mama(x; args...)
    indicator     = Indicator(f, paramset)
end

# define signals that will trigger trading decisions
@testset "Signal" begin
    @testset "Construct" begin
        siglong  = @signal MAMA ↑ FAMA
        sigshort = @signal MAMA ↓ FAMA
        sigexit  = @signal MAMA .== FAMA
    end
end

# define the trading rules
@testset "Rule" begin
    @testset "Construct" begin
        longrule  = @rule siglong → long 100
        shortrule = @rule sigshort → short 100
        exitrule  = @rule sigexit → liquidate 1.0
        rules     = (longrule, shortrule, exitrule)
    end
end

# run strategy
@testset "Strategy" begin
    @testset "Construct" begin
        strat = Strategy(universe, indicator, rules)
    end
    @testset "Backtest" begin
        backtest!(strat)
    end
    @testset "Optimize" begin
        optimize!(strat, samples=10)
    end
end
