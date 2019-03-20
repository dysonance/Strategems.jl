using ProgressMeter

function generate_trades!(strat::Strategy; args...)::Nothing
    strat.backtest.trades = generate_trades(strat; args...)
    return nothing
end

#TODO: generalize this logic to incorporate order types
function backtest(strat::Strategy; px_trade::Symbol=:Open, px_close::Symbol=:Settle, verbose::Bool=true)::Portfolio
    trades = queue_orders(strat, px_trade=px_trade)
    K = length(strat.universe.assets)
    verbose ? progress = Progress(K, 1, "Running Backtest") : nothing
    for (j, asset) in enumerate(strat.universe.assets)
        verbose ? next!(progress) : nothing
        trade_price = strat.universe.data[asset][px_trade].values[:]
        close_price = strat.universe.data[asset][px_close].values[:]
        asset_trades = trades[asset]
        for (i, trade) in enumerate(asset_trades)
            i == 1 ? continue : nothing
            update!(strat.portfolio, trade, close_price[i])
        end
    end
    return strat.portfolio
end

function backtest!(strat::Strategy; args...)::Nothing
    strat.portfolio = backtest(strat; args...)
    return nothing
end
