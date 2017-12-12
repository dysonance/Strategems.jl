#=
Type and methods to simplify data sourcing and management of the universe of tradable assets
=#

const SEPARATORS = ['/', '_', '.']

# function guess_tickers(assets::Vector{String})::Vector{Symbol}
#     tickers = Symbol.([Temporal.namefix(split(asset, SEPARATORS)[end]) for asset in assets])
#     @assert tickers == unique(tickers)  "Non-unique ticker symbols found in universe"
#     return tickers
# end

mutable struct Universe
    assets::Vector{String}
    # tickers::Vector{Symbol}
    data::Dict{String,TS}
    from::TimeType
    thru::TimeType
    function Universe(assets::Vector{String}, from::TimeType=Base.Dates.Date(0), thru::TimeType=Base.Dates.today())
        @assert assets == unique(assets)
        # tickers = guess_tickers(assets)
        data = Dict{String,TS}()
        @inbounds for asset in assets
            data[asset] = TS()
        end
        return new(assets, data, from, thru)
    end
end

#TODO: ensure type compatibility across variables (specifically with regard to TimeTypes)
function gather!(universe::Universe; source::Function=Temporal.quandl, verbose::Bool=true)::Void
    t0 = Vector{Base.Dates.Date}()
    tN = Vector{Base.Dates.Date}()
    @inbounds for asset in universe.assets
        verbose ? print("Sourcing data for asset $asset...") : nothing
        indata = source(asset)
        push!(t0, indata.index[1])
        push!(tN, indata.index[end])
        universe.data[asset] = indata
        verbose ? print("Done.\n") : nothing
    end
    universe.from = max(minimum(t0), universe.from)
    universe.thru = min(maximum(tN), universe.thru)
    return nothing
end

#FIXME: make robust to other time types
function get_overall_index(universe::Universe)::Vector{Date}
    idx = Vector{Date}()
    for asset in universe.assets
        idx = union(idx, universe.data[asset].index)
    end
    return idx
end

#TODO: show method
