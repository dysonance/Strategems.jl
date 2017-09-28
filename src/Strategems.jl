VERSION >= v"0.6-" && __precompile__(true)

module Strategems
using Base.Dates
using Temporal
using Indicators 
using RecipesBase

export
    # universe definitions
    Universe, gather!,
    # parameter sets
    ParameterSet, get_n_runs, get_param_combos, get_run_params, generate_dict,
    # indicators
    Indicator, calculate!,
    # signals
    Signal, prep_signal,
    # rules
    Rule,
    # portfolios
    # accounting
    # strategies
    Strategy, generate_trades

include("universe.jl")
include("paramset.jl")
include("indicator.jl")
include("signal.jl")
include("rule.jl")
include("strategy.jl")

end
