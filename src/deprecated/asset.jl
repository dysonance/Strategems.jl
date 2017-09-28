abstract type Asset end

#TODO: add currency conversion logic
mutable struct Currency <: Asset
    asset_id::Symbol
end

mutable struct Equity <: Asset
    asset_id::Symbol
    currency::Currency
    multiplier::Real
    min_tick::Real
    data::TS
end

mutable struct Forward <: Asset
    asset_id::Symbol
    currency::Currency
    multiplier::Real
    min_tick::Real
    maturity::Dates.TimeType
    data::TS
end

mutable struct Option <: Asset
    asset_id::Symbol
    currency::Currency
    multiplier::Real
    min_tick::Real
    maturity::Dates.TimeType
    strike::Float64
    style::Symbol
    data::TS
end

mutable struct Bond <: Asset
    asset_id::Symbol
    currency::Currency
    multiplier::Real
    min_tick::Real
    data::TS
end


