#=
Type and methods to simplify data sourcing and management of the universe of tradable assets
=#

using ProgressMeter

import Base: show

const SEPARATORS = ['/', '_', '.']

# function guess_tickers(assets::Vector{String})::Vector{Symbol}
#     tickers = Symbol.([Temporal.namefix(split(asset, SEPARATORS)[end]) for asset in assets])
#     @assert tickers == unique(tickers)  "Non-unique ticker symbols found in universe"
#     return tickers
# end

struct Universe
    assets::Vector{String}
    # tickers::Vector{Symbol}
    data::Dict{String,TS}
    from::TimeType
    thru::TimeType
    function Universe(assets::Vector{String}, data::Dict{String, TS}, from::TimeType=Dates.Date(0), thru::TimeType=Dates.today())
        @assert assets == unique(assets)
        # tickers = guess_tickers(assets)
        return new(assets, data, from, thru)
    end
end

function Universe(assets::Vector{String}, from::TimeType = Dates.Date(0), thru::TimeType=Dates.today())
        @assert assets == unique(assets)
        # tickers = guess_tickers(assets)
        
        data = Dict{String,TS}()
        @inbounds for asset in assets
            data[asset] = TS()
        end

        Universe(assets, data, from, thru)
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

function gather(assets::Vector{String}; source::Function=Temporal.quandl, verbose::Bool=true)::Universe
    t0 = Vector{Dates.Date}()
    tN = Vector{Dates.Date}()
    data = Dict{String,TS}()
    verbose ? progress = Progress(length(assets), 1, "Gathering Universe Data") : nothing
    @inbounds for asset in assets
        verbose ? next!(progress) : nothing
        indata = source(asset)
        push!(t0, indata.index[1])
        push!(tN, indata.index[end])
        data[asset] = indata
    end
    from = minimum(t0)
    thru = maximum(tN)
    Universe(assets, data, from, thru)
end

#FIXME: make robust to other time types
function get_overall_index(universe::Universe)::Vector{Date}
    idx = Vector{Date}()
    for asset in universe.assets
        idx = union(idx, universe.data[asset].index)
    end
    return idx
end

function show(io::IO, universe::Universe)
    println(io, "# Universe:")
    for (i, asset) in enumerate(universe.assets  )
        println(io, TAB, "Asset $i:", TAB, asset)
        data = universe.data[asset]
        if isempty(data)
            println(io, TAB, TAB, "(No Data Gathered)")
        else
            println(io, TAB, TAB, "Range:", TAB, data.index[1], " to ", data.index[end])
            println(io, TAB, TAB, "Fields:", TAB, join(String.(data.fields), "  "))
        end
    end
end
