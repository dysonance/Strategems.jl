using Random, ProgressMeter

import Base: copy

copy(strat::Strategy) = Strategy(strat.universe, strat.indicator, strat.rules)

#TODO: more meaningful progres information
#TODO: parallel processing
#TODO: streamline this so that it doesnt run so slow (seems to be recompiling at each run)
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
    optimization = zeros(samples, 1)
    verbose ? progress = Progress(length(sample_index), 1, "Optimizing Backtest") : nothing
    for (i, combo) in enumerate(sample_index)
        verbose ? next!(progress) : nothing
        strat.indicator.paramset.arg_defaults = combos[i,:]
        generate_trades!(strat, verbose=false)
        backtest!(strat, verbose=false; args...)
        optimization[i] = summary_fun(strat.backtest)
    end
    # prevent out-of-scope alteration of strat object
    strat = original
    return [combos optimization]
end

# TODO: implement function to edit results member of strat in place
function optimize!(strat::Strategy; samples::Int=0, seed::Int=0, verbose::Bool=true, summary_fun::Function=cum_pnl, args...)::Nothing
    optimization = optimize(strat, samples=samples, seed=seed, verbose=verbose, summary_fun=summary_fun; args...)
    strat.backtest.optimization = optimization
    return nothing
end
