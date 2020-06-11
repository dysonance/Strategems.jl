using Random, ProgressMeter
using SharedArrays
import Base.Threads.@threads

import Base: copy

copy(strat::Strategy) = Strategy(strat.universe, strat.indicator, strat.rules)

#TODO: parallel processing
function optimize(strat::Strategy; samples::Int=0, seed::Int=0, verbose::Bool=true, summary_fun::Function=cum_pnl, args...)::Matrix
    original = copy(strat)
    if samples > 0
        seed >= 0 ? Random.seed!(seed) : nothing
        sample_index = rand(collect(1:samples), samples)
    else
        samples = count_runs(strat.indicator.paramset)
        sample_index = collect(1:samples)
    end
    combos = generate_combinations(strat.indicator.paramset)[sample_index,:]
    optimization = convert(SharedArray, zeros(samples, 1))
    verbose ? progress = Progress(length(sample_index), 1, "Optimizing Backtest") : nothing

    @threads for i in 1:length(sample_index)
        verbose ? next!(progress) : nothing
        strat.indicator.paramset.arg_defaults = combos[i,:]
        bt = backtest(strat, verbose=false; args...)
        optimization[i] = summary_fun(bt)
    end

    #=
    for (i, combo) in enumerate(sample_index)
        verbose ? next!(progress) : nothing
        strat.indicator.paramset.arg_defaults = combos[i,:]
        # generate_trades!(strat, verbose=false)
        backtest!(strat, verbose=false; args...)
        optimization[i] = summary_fun(strat.backtest)
    end
    =#

    # prevent out-of-scope alteration of strat object
    strat = original
    return [combos optimization]
end

function optimize!(strat::Strategy; samples::Int=0, seed::Int=0, verbose::Bool=true, summary_fun::Function=cum_pnl, args...)::Nothing
    optimization = optimize(strat, samples=samples, seed=seed, verbose=verbose, summary_fun=summary_fun; args...)
    strat.backtest.optimization = optimization
    return nothing
end
