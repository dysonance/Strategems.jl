import Base.show

struct ParameterSet
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

function count_runs(ps::ParameterSet)::Int
    n_runs = 1
    @inbounds for i in 1:ps.n_args
        n_runs *= length(ps.arg_ranges[i])
    end
    return n_runs
end

function generate_dict(ps::ParameterSet, arg_values::Vector)::Dict{Symbol,Any}
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

function generate_combinations(ps::ParameterSet)
    A = collect(Iterators.product(ntuple(i->ps.arg_ranges[i], length(ps.arg_ranges))...))
    B = A[:]
    T = Tuple(Array{arg_type}(undef, size(B,1)) for arg_type in ps.arg_types)
    for j in 1:length(ps.arg_ranges), i in 1:size(B,1)
        T[j][i] = B[i][j]
    end
    return hcat(T...)
end
