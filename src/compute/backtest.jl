import ProgressMeter: Progress, next!

function generate_trades(strat::Strategy; verbose::Bool=true)::Dict{String,TS}
    all_trades = Dict{String,TS}()
    verbose ? progress = Progress(length(strat.universe.assets), 1, "Generating Trades") : nothing
    for asset in strat.universe.assets
        verbose ? next!(progress) : nothing
        trades = TS(falses(size(strat.universe.data[asset],1), length(strat.rules)),
                    strat.universe.data[asset].index)
        local indicator_data = calculate(strat.indicator, strat.universe.data[asset])
        for (i,rule) in enumerate(strat.rules);
            trades[:,i] = rule.trigger.fun(indicator_data)
        end
        all_trades[asset] = trades
    end
    return all_trades
end

function backtest!(strat::Strategy; trade_on::Symbol=:Open, settle_on::Symbol=:Settle, verbose::Bool=true)
    #FIXME types
    trades_by_rule = generate_trades(strat, verbose=verbose)
    index = get_overall_index(strat.universe)
    verbose ? progress = Progress(length(strat.universe.assets), 1, "Running Backtest") : nothing
    N = length(index)
    for (j, asset) in enumerate(strat.universe.assets)
        verbose ? next!(progress) : nothing
        trades = trades_by_rule[asset]
        n = size(trades, 1)
        px_trade = strat.universe.data[asset][trade_on].values
        px_close = strat.universe.data[asset][settle_on].values
        pnl = 0.0
        qty = 0.0
        m2m = 0.0
        txn = 0.0
        px = px_close[1]
        for i in 2:n
            for (r,rule) in enumerate(strat.rules)
                if trades.values[i-1,r] != 0
                    if rule.action == liquidate
                        dir = -sign(qty)
                        txn = round(rule.args[1] * qty * dir)
                    else
                        dir = rule.action in (long,buy) ? 1 : rule.action in (short,sell) ? -1 : 0
                        txn = rule.args[1]
                    end
                    qty += txn * dir
                end
            end
            px = px_close[i]
            pnl = qty * px - m2m
            m2m = qty * m2m
            t = N-n+1
            strat.portfolio.txn.values[t,j] = txn
            strat.portfolio.qty.values[t,j] = qty
            strat.portfolio.pnl.values[t,j] = pnl
            strat.portfolio.m2m.values[t,j] = m2m
        end
    end
    # update total portfolio value at each step
    for t in 1:N
        cap = strat.portfolio.cap.values[t] + sum(strat.portfolio.pnl.values[t])
        m2m = strat.portfolio.m2m.values[t,:]
        strat.portfolio.cap.values[t] = cap
        strat.portfolio.wts.values[t,:] = m2m ./ cap
    end
end
