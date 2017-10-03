VERSION >= v"0.6-" && __precompile__(true)

module Strategems
using Base.Dates
using Temporal
using Indicators 

export
    # universe definitions
    Universe, gather!, get_overall_index,
    # parameter sets
    ParameterSet, get_n_runs, get_param_combos, get_run_params, generate_dict,
    # indicators
    Indicator, calculate!,
    # signals
    Signal, prep_signal,
    # rules
    Rule,
    # portfolios
    Portfolio,#, update_portfolio!,
    # order
    AbstractOrder, MarketOrder, LimitOrder, StopOrder, buy, sell, liquidate,
    # strategies
    Strategy, generate_trades, generate_trades!, backtest

include("universe.jl")
include("paramset.jl")
include("indicator.jl")
include("signal.jl")
include("rule.jl")
include("portfolio.jl")
include("orders.jl")
include("strategy.jl")

end
