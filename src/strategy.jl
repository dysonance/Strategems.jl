#=
Type definition and methods containing the overarching backtesting object fueling the engine
=#

mutable struct Strategy
    universe::Universe
    indicator::Indicator
    signals::Dict{Symbol,Signal}
    rules::Dict{Symbol,Rule}
    portfolio::Portfolio
    results::Dict
    function Strategy(universe::Universe,
                      indicator::Indicator,
                      signals::Dict{Symbol,Signal},
                      rules::Dict{Symbol,Rule},
                      portfolio::Portfolio=Portfolio(universe))
        return new(universe, indicator, signals, rules, portfolio, Dict())
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
    strat.results["Trades"] = generate_trades(strat; args...)
    return nothing
end

function backtest(strat::Strategy; px_trade::Symbol=:Open, px_close::Symbol=:Settle, verbose::Bool=true)::Dict{String,TS}
    if !haskey(strat.results, "Trades")
        generate_trades!(strat, verbose=verbose)
    end
    result = Dict{String,TS}()
    for asset in strat.universe.assets
        verbose ? print("Running backtest for asset $asset...") : nothing
        trades = strat.results["Trades"]
        @assert haskey(trades, asset) "Asset $asset not found in generated trades."
        asset_trades = trades[asset]
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
    strat.results["Backtest"] = backtest(strat; args...)
    return nothing
end

function cum_pnl(strat::Strategy)::Float64
    result = 0.0
    @inbounds for asset in strat.universe.assets
        pnl::Vector = strat.results["Backtest"][asset][:PNL].values
        result += sum(pnl)
    end
    return result
end

Base.copy(strat::Strategy) = Strategy(strat.universe, strat.indicator, strat.signals, strat.rules)

function optimize(strat::Strategy; summary_fun::Function=cum_pnl, args...)::Matrix
    strat_save = copy(strat)
    paramset = strat.indicator.paramset
    combos = get_param_combos(paramset)
    result = zeros(size(combos,1), size(combos,2)+1)
    for run in 1:size(combos,1)
        reset_results!(strat)
        for asset in strat.universe.assets
            combo = combos[run,:]
            #sub_paramset = ParameterSet(strat.indicators[asset].paramset.arg_names, combo)
            #sub_indicator = Indicator(strat.indicators[asset].fun, sub_paramset)
            #sub_strat = Strategy(strat.universe, sub_indicator, strat.signals, strat.rules)
            strat.indicator.paramset.arg_defaults = combo
            backtest!(sub_strat; args...)
            results[run,end] = summary_fun(sub_strat)
        end
    end
    # prevent out-of-scope alteration of strat object
    strat = strat_save
    return result
end

# TODO: implement function to edit results member of strat in place
function optimize!(strat::Strategy; args...)::Void
    strat.results["Optimization"] = optimize(strat; args...)
    return nothing
end

function reset_results!(strat::Strategy)::Void
    strat.results = Dict{String,Any}()
    return nothing
end
