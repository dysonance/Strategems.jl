using Strategems, Temporal, Indicators, Base.Dates
using Base.Test

# define universe and gather data
assets = ["Corn"]
@testset "Universe" begin
    @testset "Construct" begin
        global universe = Universe(assets)
        @test universe.assets == assets
    end
    @testset "Gather" begin
        # function datasource(asset::String; save_downloads::Bool=true)::TS
        #     savedata_path = Pkg.dir("Strategems", "data/$asset.csv")
        #     if isfile(savedata_path)
        #         return Temporal.tsread(savedata_path)
        #     else
        #         X = quandl(asset)
        #         if save_downloads
        #             Temporal.tswrite(X, savedata_path)
        #         end
        #         return X
        #     end
        # end
        # gather!(universe, source=datasource)
        gather!(universe, source=(asset)->Temporal.tsread("$(Pkg.dir("Temporal"))/data/$asset.csv"))
        @test length(setdiff(assets, collect(keys(universe.data)))) == 0
    end
end

# define indicators and parameter space
@testset "Parameter Set" begin
    global arg_names          = [:fastlimit, :slowlimit]
    global arg_defaults       = [0.5, 0.05]
    global arg_ranges         = [0.01:0.01:0.99, 0.01:0.01:0.99]
    global paramset           = ParameterSet(arg_names, arg_defaults, arg_ranges)
    @test paramset.arg_names == arg_names
end

@testset "Indicator" begin
    global f(x; args...) = Indicators.mama(x; args...)
    global indicator     = Indicator(f, paramset)
end

# define signals that will trigger trading decisions
@testset "Signal" begin
    @testset "Construct" begin
        global siglong  = @signal MAMA ↑ FAMA
        global sigshort = @signal MAMA ↓ FAMA
        global sigexit  = @signal MAMA .== FAMA
    end
end

# define the trading rules
@testset "Rule" begin
    @testset "Construct" begin
        global longrule  = @rule siglong → long 100
        global shortrule = @rule sigshort → short 100
        global exitrule  = @rule sigexit → liquidate 1.0
        global rules     = (longrule, shortrule, exitrule)
    end
end

# run strategy
@testset "Strategy" begin
    @testset "Construct" begin
        global strat = Strategy(universe, indicator, rules)
    end
    @testset "Backtest" begin
        backtest!(strat)
    end
    @testset "Optimize" begin
        optimize!(strat, samples=10)
        @test size(strat.results.optimization,1) == 10
        @test size(strat.results.optimization,2) == length(arg_names)+1
    end
end
