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
function liquidate(portfolio::Portfolio, asset::String)::Void
    return nothing
end

function buy(portfolio::Portfolio, asset::String, quantity::Number)::Void
    return nothing
end

function long(portfolio::Portfolio, asset::String, quantity::Number)::Void
    liquidate(portfolio, asset)
    buy(portfolio, asset, quantity)
    return nothing
end

function sell(portfolio::Portfolio, asset::String, quantity::Number)::Void
    return nothing
end

function short(portfolio::Portfolio, asset::String, quantity::Number)::Void
    liquidate(portfolio, asset)
    sell(portfolio, asset, quantity)
    return nothing
end

