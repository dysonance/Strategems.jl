#=
Type definition and methods containing the overarching backtesting object fueling the engine
=#

mutable struct Strategy
    universe::Universe
    indicator::Indicator
    signals::Dict{Symbol,Signal}
    rules::Dict{Symbol,Rule}
    portfolio::Portfolio
    results::Results
    function Strategy(universe::Universe,
                      indicator::Indicator,
                      signals::Dict{Symbol,Signal},
                      rules::Dict{Symbol,Rule},
                      portfolio::Portfolio=Portfolio(universe))
        return new(universe, indicator, signals, rules, portfolio, Results())
    end
end

function generate_trades(strat::Strategy; verbose::Bool=true)::Dict{String,TS}
    trades = Dict{String,TS}()
    for asset in strat.universe.assets
        verbose ? print("Generating trades for asset $asset...") : nothing
        trades[asset] = TS()
        for signal_id in keys(strat.signals)
            local indicator_data = calculate(strat.indicator, strat.universe.data[asset])
            local signal = prep_signal(strat.signals[signal_id], indicator_data)
            trades[asset] = [trades[asset] eval(signal)]
            trades[asset].fields[end] = signal_id
        end
        verbose ? print("Done.\n") : nothing
    end
    return trades
end

function generate_trades!(strat::Strategy; args...)::Void
    strat.results.trades = generate_trades(strat; args...)
    return nothing
end

function backtest(strat::Strategy; px_trade::Symbol=:Open, px_close::Symbol=:Settle, verbose::Bool=true)::Dict{String,TS{Float64}}
    if isempty(strat.results.trades)
        generate_trades!(strat, verbose=verbose)
    end
    result = Dict{String,TS}()
    for asset in strat.universe.assets
        verbose ? print("Running backtest for asset $asset...") : nothing
        asset_trades = strat.results.trades[asset]
        N = size(asset_trades, 1)
        summary_ts = [strat.universe.data[asset] asset_trades]
        #TODO: add setindex! method for TS objects using Symbol and Vector to assign inplace
        #TODO: generalize this logic to incorporate order types
        #FIXME: generalize this logic to use the actual rules (this is a temporary quickfix)
        trade_price = summary_ts[px_trade].values
        close_price = summary_ts[px_close].values
        pos = zeros(Float64, N)
        pnl = zeros(Float64, N)
        do_trade = false
        for i in 2:N
            for rule in keys(strat.rules)
                if summary_ts[strat.rules[rule].trigger].values[i-1] != 0
                    do_trade = true
                    order_side = strat.rules[rule].action.args[1] == :buy ? 1 : strat.rules[rule].action.args[1] == :sell ? -1 : 0
                    order_qty = strat.rules[rule].action.args[3]
                    pos[i] = order_qty * order_side
                    pnl[i] = pos[i] * (close_price[i] - trade_price[i])
                end
            end
            if !do_trade
                pos[i] = pos[i-1]
                pnl[i] = pos[i] * (close_price[i]-close_price[i-1])
            end
            do_trade = false
        end
        summary_ts = [summary_ts TS([pos pnl cumsum(pnl)], summary_ts.index, [:Pos,:PNL,:CumPNL])]
        result[asset] = summary_ts
        verbose ? print("Done.\n") : nothing
    end
    return result
end

function backtest!(strat::Strategy; args...)::Void
    strat.results.backtest = backtest(strat; args...)
    return nothing
end

Base.copy(strat::Strategy) = Strategy(strat.universe, strat.indicator, strat.signals, strat.rules)

#TODO: more meaningful progres information
#TODO: parallel processing
#TODO: streamline this so that it doesnt run so slow (seems to be recompiling at each run)
function optimize(strat::Strategy; samples::Int=0, seed::Int=0, verbose::Bool=true, summary_fun::Function=cum_pnl, args...)::Matrix
    strat_save = copy(strat)
    n_runs = get_n_runs(strat.indicator.paramset)
    idx_samples::Vector{Int} = collect(1:n_runs)
    if samples > 0
        srand(seed)
        idx_samples = rand(idx_samples, samples)
    end
    combos = get_param_combos(strat.indicator.paramset, n_runs)[idx_samples,:]
    result = zeros(n_runs)
    @inbounds for run in idx_samples
        verbose ? println("Run $run/$(length(idx_samples))") : nothing
        strat.indicator.paramset.arg_defaults = combos[run,:]
        generate_trades!(strat, verbose=false)
        backtest!(strat, verbose=false; args...)
        result[run] = summary_fun(strat.results.backtest)
    end
    # prevent out-of-scope alteration of strat object
    strat = strat_save
    return result
end

# TODO: implement function to edit results member of strat in place
function optimize!(strat::Strategy; samples::Int=0, seed::Int=0, verbose::Bool=true, summary_fun::Function=cum_pnl, args...)::Void
    n_runs = get_n_runs(strat.indicator.paramset)
    idx_samples::Vector{Int} = collect(1:n_runs)
    if samples > 0
        srand(seed)
        idx_samples = rand(idx_samples, samples)
    end
    combos = get_param_combos(strat.indicator.paramset, n_runs)[idx_samples,:]
    strat.results.optimization = zeros(n_runs,1)
    @inbounds for run in idx_samples
        verbose ? println("Run $run/$(length(idx_samples))") : nothing
        strat.indicator.paramset.arg_defaults = combos[run,:]
        generate_trades!(strat, verbose=false)
        backtest!(strat, verbose=false; args...)
        strat.results.optimization[run] = summary_fun(strat.results)
    end
    strat.results.optimization = [combos strat.results.optimization]
    return nothing
end

