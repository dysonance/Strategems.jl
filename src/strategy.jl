#=
Type definition and methods containing the overarching backtesting object fueling the engine
=#

mutable struct Strategy
    universe::Universe
    indicators::Dict{String,Indicator}
    signals::Dict{Symbol,Signal}
    rules::Dict{Symbol,Rule}
    portfolio
    account
    results
    function Strategy(universe::Universe,
                      indicator::Indicator,
                      signals::Dict{Symbol,Signal},
                      rules::Dict{Symbol,Rule},
                      portfolio,
                      account,
                      results)
        return new(universe, generate_dict(universe, indicator), signals, rules, portfolio, account, results)
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
