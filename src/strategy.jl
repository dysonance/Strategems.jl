#=
Type definition and methods containing the overarching backtesting object fueling the engine
=#

mutable struct Strategy
    universe::Universe
    indicators::Dict{String,Indicator}
    rules::Dict{Symbol,Rule}
    portfolio
    account
    results
end

function generate_trades(strat::Strategy)::Dict{String,TS}
    trades = Dict{String,TS}()
    for asset in strat.universe.assets
        trades[asset] = TS()
        for rule_name in keys(strat.rules)
            trigger = prep_trigger(strat.rules[rule_name], strat.indicators[asset])
            trades[asset] = [trades[asset] eval(trigger)]
            trades[asset].fields[end] = rule_name
        end
    end
    return trades
end
