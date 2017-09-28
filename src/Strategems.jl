VERSION >= v"0.6-" && __precompile__(true)

module Strategems
using Base.Dates
using Temporal
using Indicators 
using RecipesBase

export
    # parameter sets
    ps, get_n_runs, get_param_combos, get_run_params
    # indicators
    # strategies
    # portfolios
    # accounting

include("paramset.jl")

end
