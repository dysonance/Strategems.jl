#=
Type definition and methods containing the overarching backtesting object fueling the engine
=#

import Base: show

const TABWIDTH = 4
const TAB = ' ' ^ TABWIDTH

struct Strategy
    universe::Universe
    indicator::Indicator
    rules::Tuple{Vararg{Rule}}
    portfolio::Portfolio
    backtest::Backtest
    function Strategy(universe::Universe,
                      indicator::Indicator,
                      rules::Tuple{Vararg{Rule}},
                      portfolio::Portfolio=Portfolio(universe))
        return new(universe, indicator, rules, portfolio, Backtest())
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
        asset_result = strat.backtest.backtest[asset]
        holding = asset_result[:Pos]
        holdings = [holdings holding]
        values = [values cl(asset_result) * holding]
        profits = [profits asset_result[:PNL]]
    end
    # data cleaning - field assignment and missing value replacement
    holdings.fields = Symbol.(strat.universe.assets)
    profits.fields = Symbol.(strat.universe.assets)
    values.fields = Symbol.(strat.universe.assets)
    holdings.values[isnan.(holdings.values)] .= 0.0
    values.values[isnan.(values.values)] .= 0.0
    profits.values[isnan.(profits.values)] .= 0.0
    # portfolio weights, net exposure, and leverage calculations
    weights = values / apply(values, 1, fun=sum)
    weights.fields = Symbol.(strat.universe.assets)
    exposure = apply(weights, 1, fun=sum)
    leverage = apply(weights, 1, fun=x->(sum(abs.(x))))
    weights = [weights exposure leverage]
    weights.fields[end-1:end] = [:Exposure, :Leverage]
    # compute other temporal totals and return
    profits = [profits apply(profits, 1, fun=sum)]
    profits.fields[end] = :Total
    values = [values apply(values, 1, fun=sum)]
    values.fields[end] = :Total
    return weights, holdings, values, profits
end
