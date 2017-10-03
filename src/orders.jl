#=
types and methods to facilitate the interaction between orders, rules, and portfolios
=#

abstract AbstractOrder

struct MarketOrder <: AbstractOrder
    asset::String
    quantity::Number
end

struct LimitOrder <: AbstractOrder
    asset::String
    quantity::Number
    limit::Number
end

struct StopOrder <: AbstractOrder
    asset::String
    quantity::Number
    stop::Number
end

#TODO: complete this logic, enable interaction with strategy/portfolio objects
function buy(asset::String, quantity::Number)::Void
    return nothing
end
function sell(asset::String, quantity::Number)::Void
    return nothing
end
function liquidate(asset::String)::Void
    return nothing
end
