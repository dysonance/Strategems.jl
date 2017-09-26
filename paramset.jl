mutable struct ParameterSet
    arg_names::Vector{Symbol}
    arg_defaults::Vector
    arg_ranges::Vector
    n_args::Int
    function ParameterSet(arg_names::Vector{Symbol},
                          arg_defaults::Vector,
                          arg_ranges::Vector=[x:x for x in arg_defaults])
        @assert length(arg_names) == length(arg_defaults) == length(arg_ranges)
        return new(arg_names, arg_defaults, arg_ranges, length(arg_names))
    end
end

function get_n_runs(ps::ParameterSet)::Int
    n_runs = 1
    @inbounds for i in 1:ps.n_args
        n_runs *= length(ps.arg_ranges[i])
    end
    return n_runs
end

#FIXME: giving all the same dictionaries in the final vector as the last element of the loop
#FIXME: also check that the loop is doing what its intended to do

function get_run_params(ps::ParameterSet)#::Vector{Dict{Symbol,Any}}
    n_runs = get_n_runs(ps)
    combos = Matrix{Any}(n_runs, ps.n_args)
    P = 1
    for j in 1:ps.n_args
        n_vals = length(ps.arg_ranges[j])
        n_reps = ceil(Int, n_runs/(n_vals*P))
        for i in 1:n_vals
            first_row = ceil(Int, n_vals/P)*(i-1)+1
            step_by = ceil(Int, n_runs/(n_vals*n_reps))
            #last_row = ceil(Int, n_runs/n_reps)
            last_row = first_row + n_vals*step_by - 1
            rows = first_row:step_by:last_row
            arg_val = ps.arg_ranges[j][i]
            combos[rows,j] = arg_val
        end
        P *= n_vals
    end
    #return combos
    arg_dicts = Vector{Dict{Symbol,Any}}(n_runs)
    for i in 1:size(combos,1)
        tmp_dict = Dict{Symbol,Any}()
        for j in 1:size(combos,2)
            tmp_dict[ps.arg_names[j]] = combos[i,j]
        end
        arg_dicts[i] = tmp_dict
    end
    return arg_dicts
end

ps = ParameterSet([:fastlimit, :slowlimit], [0.5, 0.05])
ps.arg_ranges = [0.01:0.01:0.99, 0.01:0.01:0.99]

params = get_run_params(ps)
