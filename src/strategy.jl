#=
Type definition and methods containing the overarching backtesting object fueling the engine
=#

import Base: show

const TABWIDTH = 4
const TAB = ' ' ^ TABWIDTH

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

function show(io::IO, strat::Strategy)
    println(io, strat.indicator.paramset)
    println(io, "# Rules:")
    for rule in strat.rules
        println(io, TAB, rule)
    end
    println()
    show(io, strat.universe)
end

function summarize_results(strat::Strategy)
    holdings = TS()
    values = TS()
    profits = TS()
    for asset in strat.universe.assets
        asset_result = strat.results.backtest[asset]
        holding = asset_result[:Pos]
        profit = asset_result[:PNL]
        # TODO: determine if would best be determined by the px_close field
        value = cl(asset_result) * holding
        holding.fields = [Symbol(asset)]
        value.fields = [Symbol(asset)]
        profit.fields = [Symbol(asset)]
        holdings = [holdings holding]
        values = [values value]
        profits = [profits profit]
    end
    weights = values / apply(values, 1, fun=sum)
    profits.values[isnan.(profits.values)] .= 0.0
    return weights, holdings, values, profits
end
