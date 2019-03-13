VERSION >= v"0.6-" && __precompile__(true)

module Strategems
    using Dates
    using Temporal
    using Indicators 

    export
        # universe definitions
        Universe, gather!, get_overall_index,
        # parameter sets
        ParameterSet, get_n_runs, get_param_combos, get_run_params, generate_dict,
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
        # strategy results
        Results,
        # summary statistic calculations
        cum_pnl,
        # strategies
        Strategy, generate_trades, generate_trades!, backtest, backtest!, optimize, optimize!, summarize_results

    include("universe.jl")
    include("paramset.jl")
    include("indicator.jl")
    include("signal.jl")
    include("rule.jl")
    include("portfolio.jl")
    include("order.jl")
    include("results.jl")
    include("stats.jl")
    include("strategy.jl")
    include("backtest.jl")

end
