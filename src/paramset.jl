import Base.show

mutable struct ParameterSet
    arg_names::Vector{Symbol}
    arg_defaults::Vector
    arg_ranges::Vector
    arg_types::Vector{<:Type}
    n_args::Int
    #TODO: parameter constraints (e.g. ensure one parameter always greater than another)
    #TODO: refactor out the arg_ prefix (its redundant if they all start with it)
    function ParameterSet(arg_names::Vector{Symbol},
                          arg_defaults::Vector,
                          arg_ranges::Vector=[x:x for x in arg_defaults])
        @assert length(arg_names) == length(arg_defaults) == length(arg_ranges)
        @assert eltype.(arg_defaults) == eltype.(arg_ranges)
        arg_types::Vector{<:Type} = eltype.(arg_defaults)
        return new(arg_names, arg_defaults, arg_ranges, arg_types, length(arg_names))
    end
end

function get_n_runs(ps::ParameterSet)::Int
    n_runs = 1
    @inbounds for i in 1:ps.n_args
        n_runs *= length(ps.arg_ranges[i])
    end
    return n_runs
end

function get_param_combos(ps::ParameterSet; n_runs::Int=get_n_runs(ps))::Matrix
    combos = Matrix{Any}(undef, n_runs, ps.n_args)
    P = 1
    for j in 1:ps.n_args
        n_vals = length(ps.arg_ranges[j])
        n_reps = ceil(Int, n_runs/(n_vals*P))
        for i in 1:n_vals
            first_row = ceil(Int, n_vals/P)*(i-1)+1
            step_by = ceil(Int, n_runs/(n_vals*n_reps))
            last_row = first_row + n_vals*step_by - 1
            rows = first_row:step_by:last_row
            arg_val = ps.arg_ranges[j][i]
            combos[rows,j] .= arg_val
        end
        P *= n_vals
    end
    return combos
end

function get_run_params(ps::ParameterSet; n_runs::Int=get_n_runs(ps))::Vector{Dict{Symbol,Any}}
    n_runs = get_n_runs(ps)
    combos::Matrix{Any} = get_param_combos(ps, n_runs=n_runs)
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

function generate_dict(ps::ParameterSet; arg_values::Vector=ps.arg_defaults)::Dict{Symbol,Any}
    out_dict = Dict{Symbol,Any}()
    for j in 1:ps.n_args
        out_dict[ps.arg_names[j]] = arg_values[j]
    end
    return out_dict
end

function show(io::IO, ps::ParameterSet)::Nothing
    println(io, "# Parameters:")
    @inbounds for i in 1:ps.n_args
        println(io, TAB, "($i) $(ps.arg_names[i])  →  $(ps.arg_defaults[i])  ∈  {$(string(ps.arg_ranges[i]))} :: $(ps.arg_types[i])")
    end
end
