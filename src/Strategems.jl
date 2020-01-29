__precompile__(true)

module Strategems
    using Dates
    using Temporal
    using Indicators 
    using Random
    using ProgressMeter

    export
        # universe definitions
        Universe, gather!, get_overall_index,
        # parameter sets
        ParameterSet, count_runs, generate_combinations, generate_dict,
        # indicators
        Indicator, calculate,
        # signals
        Signal, prep_signal, ↑, ↓, @signal,
        # rules
        Rule, @rule, →,
        # portfolios
        Portfolio,#, update_portfolio!,
        # order
        AbstractOrder, MarketOrder, LimitOrder, StopOrder, liquidate, long, buy, short, sell,
        # summary statistic calculations
        cum_pnl,
        # strategies
        Strategy, generate_trades, generate_trades!, backtest!, optimize, optimize!, summarize_results

    include("model/universe.jl")
    include("model/paramset.jl")
    include("model/indicator.jl")
    include("model/signal.jl")
    include("model/rule.jl")
    include("model/portfolio.jl")
    include("model/order.jl")
    include("model/strategy.jl")
    include("compute/backtest.jl")
    include("compute/optimize.jl")

end
