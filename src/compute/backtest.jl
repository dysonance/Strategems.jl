using ProgressMeter

function generate_trades(strat::Strategy; arg_values::Union{Vector, Nothing},
                         verbose::Bool=true)::Dict{String,TS}

    if isnothing(arg_values)
        arg_values = strat.indicator.paramset.arg_defaults
    end

    all_trades = Dict{String,TS}()
    verbose ? progress = Progress(length(strat.universe.assets), 1, "Generating Trades") : nothing

    for asset in strat.universe.assets
        verbose ? next!(progress) : nothing
        trades = TS(falses(size(strat.universe.data[asset],1), length(strat.rules)),
                    strat.universe.data[asset].index)

        local indicator_data = calculate(strat.indicator, strat.universe.data[asset], arg_values=arg_values)

        for (i,rule) in enumerate(strat.rules);
            trades[:,i] = rule.trigger.fun(indicator_data)
        end
        all_trades[asset] = trades
    end
    return all_trades
end

# function generate_trades!(strat::Strategy; args...)::Nothing
#     strat.backtest.trades = generate_trades(strat; args...)
#     return nothing
# end

#TODO: generalize this logic to incorporate order types
function backtest(strat::Strategy;
                  arg_values::Union{Vector, Nothing}=nothing,
                  px_trade::Symbol=:Open,
                  px_close::Symbol=:Settle,
                  verbose::Bool=true)::Dict{String,TS{Float64}}

    if isnothing(arg_values)
        arg_values = convert(Vector, strat.indicator.paramset.arg_defaults)
    end

    if isempty(strat.backtest.trades)
        all_trades = generate_trades(strat, arg_values=arg_values, verbose=verbose)
    else
        all_trades = strat.backtest.trades
    end

    result = Dict{String,TS}()
    verbose ? progress = Progress(length(strat.universe.assets), 1, "Running Backtest") : nothing
    for asset in strat.universe.assets
        verbose ? next!(progress) : nothing
        trades = all_trades[asset].values
        N = size(trades, 1)
        summary_ts = strat.universe.data[asset]
        trade_price = summary_ts[px_trade].values
        close_price = summary_ts[px_close].values
        pos = zeros(Float64, N)
        pnl = zeros(Float64, N)
        do_trade = false
        for t in 2:N
            for (i,rule) in enumerate(strat.rules)
                if trades[t-1,i] != 0
                    do_trade = true
                    order_side = rule.action in (long,buy) ? 1 : rule.action in (short,sell) ? -1 : 0
                    (order_qty,) = rule.args
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
    end
    return result
end

# function backtest!(strat::Strategy; args...)::Nothing
#     strat.backtest.backtest = backtest(strat; args...)
#     return nothing
# end
