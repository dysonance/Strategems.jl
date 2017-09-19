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

function get_run_params(ps::ParameterSet)::Vector{Dict{Symbol,Any}}
    n_runs = get_n_runs(ps)
    arg_dicts = Vector{Dict{Symbol,Any}}(n_runs)
    # initialize holder dictionary to be changed at each iteration below
    #     with the proper argument names in the key slots
    tmp_dict = Dict{Symbol,Any}()
    for j in 1:ps.n_args
        tmp_dict[ps.arg_names[j]] = ps.arg_ranges[j][1]
    end
    # initialize indexes for which value of each argument range will be taken
    idx_args = ones(Int, ps.n_args)
    rng_lens = [length(arg_range) for arg_range in ps.arg_ranges]
    arg_dicts[1] = tmp_dict
    for j in 1:ps.n_args
        for i in 2:n_runs
            tmp_dict[ps.arg_names[j]] = ps.arg_ranges[j][idx_args[j]]
            idx_args[j] += idx_args[j]==rng_lens[j] ? 1-idx_args[j] : 1
        end
        arg_dicts[i] = tmp_dict
    end
    return arg_dicts
end

