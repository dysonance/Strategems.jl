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
end

type Forward <: Asset
    asset_id::Symbol
    currency::Currency
    multiplier::Real
    min_tick::Real
    maturity::TimeType
end

type Option <: Asset
    asset_id::Symbol
    currency::Currency
    multiplier::Real
    min_tick::Real
    maturity::TimeType
    strike::Float64
    style::Symbol
end

type Bond <: Asset
    asset_id::Symbol
    currency::Currency
    multiplier::Real
    min_tick::Real
end


