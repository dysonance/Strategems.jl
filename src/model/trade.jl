
mutable struct Trade
    asset::String
    quantity::Float64
    action::Function
    timestamp::TimeType
    price::Float64
    filled::Bool
    queued::Bool
end

function queue_orders(strat::Strategy; px_trade::Symbol=:Open)::Dict{String,Vector{Trade}}
    trades = Dict(asset=>queue_orders(strat, asset, px_trade=px_trade) for asset in strat.universe.assets)
    return trades
end

function queue_orders(strat::Strategy, asset::String; px_trade::Symbol=:Open)::Vector{Trade}
    index = strat.universe.data[asset].index
    N = length(index)
    result = calculate(strat.indicator, strat.universe.data[asset])
    triggers = hcat((rule.trigger.fun(result) for rule in strat.rules)...)
    trades = Vector{Trade}(undef, N)
    trade = Trade(asset, 0, liquidate, index[1], NaN, false, false)
    trade_prices = strat.universe.data[asset][px_trade].values
    for i in 1:N
        if trade.queued
            trade.price = trade_prices[i]
        end
        for (j, rule) in enumerate(strat.rules)
            if triggers[i,j]
                trade.quantity = rule.args[1]
                trade.action = rule.action
                trade.queued = true
            end
        end
        trades[i] = trade
    end
    return trades
end

function update!(portfolio::Portfolio, trade::Trade, close_price::Float64)::Nothing
    i = findfirst(portfolio.nav.index .== trade.timestamp)
    j = findfirst(portfolio.holdings.fields .== Symbol(trade.asset))
    if trade.queued
        portfolio.holdings.values[i,j] += trade.quantity * (trade.action in (long,buy) ? 1.0 : trade.action in (short,sell) ? -1.0 : 0.0)
        portfolio.values.values[i,j] += trade.quantity * close_price
        portfolio.pnl.values[i,j] += portfolio.holdings.values[i,j] * (close_price-trade.price)
        portfolio.nav.values[i,2] -= trade.quantity * trade.price
    else
        portfolio.holdings.values[i,j] = portfolio.holdings.values[i-1,j]
        portfolio.pnl.values[i,j] += portfolio.values.values[i,j] - portfolio.holdings.values[i-1,j]*close_price
        portfolio.nav.values[i,2] -= trade.quantity * trade.price
    end
    portfolio.nav.values[i,1] = sum(portfolio.values.values[i,:]) + portfolio.nav.values[i,2]
    portfolio.weights.values[i,:] = portfolio.weights.values[i,:] ./ portfolio.nav.values[i,1]
    trade.filled = true
    return nothing
end
