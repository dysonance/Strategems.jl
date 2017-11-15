#=
Type definition and methods containing the overarching backtesting object fueling the engine
=#

mutable struct Strategy
    universe::Universe
    indicator::Indicator
    rules::Tuple{Vararg{Rule}}
    portfolio::Portfolio
    results::Results
    function Strategy(universe::Universe,
                      indicator::Indicator,
                      rules::Tuple{Vararg{Rule}},
                      portfolio::Portfolio=Portfolio(universe))
        return new(universe, indicator, rules, portfolio, Results())
    end
end

function generate_trades(strat::Strategy; verbose::Bool=true)::Dict{String,TS}
    all_trades = Dict{String,TS}()
    for asset in strat.universe.assets
        verbose ? print("Generating trades for asset $asset...") : nothing
        trades = TS(falses(size(strat.universe.data[asset],1), length(strat.rules)),
                    strat.universe.data[asset].index)
        for (i,rule) in enumerate(strat.rules);
            local indicator_data = calculate(strat.indicator, strat.universe.data[asset])
            trades[:,i] = rule.trigger.fun(indicator_data)
        end
        all_trades[asset] = trades
        verbose ? print("Done.\n") : nothing
    end
    return all_trades
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
        trades = strat.results.trades[asset].values
        N = size(asset_trades, 1)
        #summary_ts = [strat.universe.data[asset] asset_trades]
        #TODO: add setindex! method for TS objects using Symbol and Vector to assign inplace
        #TODO: generalize this logic to incorporate order types
        #FIXME: generalize this logic to use the actual rules (this is a temporary quickfix)
        trade_price = summary_ts[px_trade].values
        close_price = summary_ts[px_close].values
        pos = zeros(Float64, N)
        pnl = zeros(Float64, N)
        do_trade = false
        for t in 2:N
            for (i,rule) in strat.rules
                if trades[t-1,i] != 0
                    do_trade = true
                    #TODO: fill out this logic with the various order types
                    order_side = rule.action in (long,buy) ? 1 : rule.action in (short,sell) ? -1 : 0
                    #TODO: add logic here for the int vs. float argument type to order function
                    (order_qty,) = rule.args
                    #if isa(order_qty, Int); else FIXME: portfolio adjustment logic; end
                    pos[t] = order_qty * order_side
                    pnl[t] = pos[t] * (close_price[t] - trade_price[t])
                end
            end
            if !do_trade
                pos[t] = pos[t-1]
                pnl[t] = pos[t] * (close_price[t]-close_price[t-1])
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

Base.copy(strat::Strategy) = Strategy(strat.universe, strat.indicator, strat.rules)

# define matrix row iterator protocol
# this allows us to `enumerate(EachRow(M))`
# thereby getting the count of the iteration as well as the row
immutable EachRow{T<:AbstractMatrix}
    A::T
end
Base.start(::EachRow) = 1
Base.next(itr::EachRow, s) = (itr.A[s,:], s+1)
Base.done(itr::EachRow, s) = s > size(itr.A,1)

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
    else
        samples = n_runs
    end
    combos = get_param_combos(strat.indicator.paramset, n_runs)[idx_samples,:]
    result = zeros(samples)
    for (run, combo) in enumerate(idx_samples)
        verbose ? println("Run $run/$samples") : nothing
        strat.indicator.paramset.arg_defaults = combo
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
        if seed >= 0
            srand(seed)
        end
        idx_samples = rand(idx_samples, samples)
    else
        samples = n_runs
    end
    combos = get_param_combos(strat.indicator.paramset, n_runs)[idx_samples,:]
    strat.results.optimization = zeros(samples,1)
    for (run, combo) in enumerate(EachRow(combos))
        verbose ? println("Run $run/$samples") : nothing
        strat.indicator.paramset.arg_defaults = combo
        generate_trades!(strat, verbose=false)
        backtest!(strat, verbose=false; args...)
        strat.results.optimization[run] = summary_fun(strat.results)
    end
    strat.results.optimization = [combos strat.results.optimization]
    return nothing
end

