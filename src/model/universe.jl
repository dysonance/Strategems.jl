#=
Type and methods to simplify data sourcing and management of the universe of tradable assets
=#

using ProgressMeter

import Base: show

mutable struct Universe
    assets::Vector{String}
    data::Dict{String,TS}
    from::TimeType
    thru::TimeType
    index::Vector{TimeType}
    function Universe(assets::Vector{String}, from::TimeType=Dates.Date(0), thru::TimeType=Dates.today())
        @assert assets == unique(assets)
        data = Dict{String,TS}()
        @inbounds for asset in assets
            data[asset] = TS()
        end
        index = union((data[asset].index for asset in assets)...)
        return new(assets, data, from, thru, index)
    end
end

#TODO: ensure type compatibility across variables (specifically with regard to TimeTypes)
function gather!(universe::Universe; source::Function=Temporal.quandl, verbose::Bool=true)::Nothing
    t0 = Vector{Dates.Date}()
    tN = Vector{Dates.Date}()
    verbose ? progress = Progress(length(universe.assets), 1, "Gathering Universe Data") : nothing
    @inbounds for asset in universe.assets
        verbose ? next!(progress) : nothing
        indata = source(asset)
        push!(t0, indata.index[1])
        push!(tN, indata.index[end])
        universe.data[asset] = indata
    end
    universe.from = max(minimum(t0), universe.from)
    universe.thru = min(maximum(tN), universe.thru)
    return nothing
end

function show(io::IO, universe::Universe)
    println(io, "# Universe:")
    for (i, asset) in enumerate(universe.assets  )
        println(io, TAB, "Asset $i:", TAB, asset)
        data = universe.data[asset]
        println(io, TAB, TAB, "Range:", TAB, data.index[1], " to ", data.index[end])
        println(io, TAB, TAB, "Fields:", TAB, join(String.(data.fields), "  "))
    end
end
