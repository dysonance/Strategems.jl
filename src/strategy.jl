#=
Type definition and methods containing the overarching backtesting object fueling the engine
=#

mutable struct Strategy
    universe::Universe
    indicators::Dict{String,Indicator}
    signals::Dict{Symbol,Signal}
    rules::Dict{Symbol,Rule}
    portfolio::Portfolio
    results::Dict
    function Strategy(universe::Universe,
                      indicator::Indicator,
                      signals::Dict{Symbol,Signal},
                      rules::Dict{Symbol,Rule},
                      portfolio::Portfolio=Portfolio(universe))
        return new(universe, generate_dict(universe, indicator), signals, rules, portfolio, Dict())
    end
end

function generate_trades(strat::Strategy)::Dict{String,TS}
    trades = Dict{String,TS}()
    for asset in strat.universe.assets
        trades[asset] = TS()
        for signal_id in keys(strat.signals)
            local signal = prep_signal(strat.signals[signal_id], strat.indicators[asset])
            trades[asset] = [trades[asset] eval(signal)]
            trades[asset].fields[end] = signal_id
        end
    end
    return trades
end

function generate_trades!(strat::Strategy)::Void
    strat.results["Trades"] = generate_trades(strat)
    return nothing
end

function backtest(strat::Strategy; px_trade::Symbol=:Open, px_close::Symbol=:Settle)::Dict{String,TS}
    if !haskey(strat.results, "Trades")
        generate_trades!(strat)
    end
    result = Dict{String,TS}()
    for asset in strat.universe.assets
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
    end
    return result
end

function backtest!(strat::Strategy, px_trade::Symbol=:Open, px_close::Symbol=:Settle)::Void
    strat.results["Backtest"] = backtest(strat, px_trade, px_close)
    return nothing
end

function reset_results!(strat::Strategy)::Void
    strat.results = Dict{String,Any}()
    return nothing
end
