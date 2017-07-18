abstract Asset

#TODO: add currency conversion logic
type Currency <: Asset
    asset_id::Symbol
end

type Equity <: Asset
    asset_id::Symbol
    currency::Currency
    multiplier::Real
    min_tick::Real
    data::TS
end

type Forward <: Asset
    asset_id::Symbol
    currency::Currency
    multiplier::Real
    min_tick::Real
    maturity::Dates.TimeType
    data::TS
end

type Option <: Asset
    asset_id::Symbol
    currency::Currency
    multiplier::Real
    min_tick::Real
    maturity::Dates.TimeType
    strike::Float64
    style::Symbol
    data::TS
end

type Bond <: Asset
    asset_id::Symbol
    currency::Currency
    multiplier::Real
    min_tick::Real
    data::TS
end


