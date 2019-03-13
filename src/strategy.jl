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

