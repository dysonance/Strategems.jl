#=
types and methods to facilitate the interaction between orders, rules, and portfolios
=#

abstract type AbstractOrder end

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
#TODO: diffierentiate between buying vs. going long and the like (the latter should reverse position if short)

#TODO: add logic whereby the order logic is altered by the type `T` of qty
# (if T<:Int, order that many *shares*, else if T<:Float64, interpret qty as a fraction of the portfolio at time t)

liquidate(qty::T) where {T<:Real} = qty

long(qty::T) where {T<:Real} = qty
buy(qty::T) where {T<:Real} = qty

short(qty::T) where {T<:Real} = qty
sell(qty::T) where {T<:Real} = qty

