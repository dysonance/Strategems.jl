#=
Type and methods to simplify data sourcing and management of the universe of tradable assets
=#

mutable struct Universe
    assets::Vector{String}
    data::Dict{String,TS}
    from::TimeType
    thru::TimeType
    function Universe(assets::Vector{String}, from::TimeType=Base.Dates.Date(0), thru::TimeType=Base.Dates.today())
        @assert assets == unique(assets)
        data = Dict{String,TS}()
        @inbounds for asset in assets
            data[asset] = TS()
        end
        return new(assets, data, from, thru)
    end
end

#TODO: ensure type compatibility across variables (specifically with regard to TimeTypes)
function gather!(universe::Universe; source::Function=Temporal.quandl)::Void
    t0 = Vector{Base.Dates.Date}()
    tN = Vector{Base.Dates.Date}()
    @inbounds for asset in universe.assets
        print("Sourcing data for asset $asset...")
        indata = source(asset)
        push!(t0, indata.index[1])
        push!(tN, indata.index[end])
        universe.data[asset] = indata
        print("Done.\n")
    end
    universe.from = max(minimum(t0), universe.from)
    universe.thru = min(maximum(tN), universe.thru)
    return nothing
end

#TODO: show method
