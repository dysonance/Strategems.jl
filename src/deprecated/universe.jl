using Base.Dates

immutable struct Universe
    symbols::Vector{Symbol}
    assets::Vector{Asset}
    fromdate::TimeType
    thrudate::TimeType
end

