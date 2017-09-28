#=
type and methods to track the evolution of a strategy's securities portfolio composition
=#

mutable struct Portfolio
    quantity::Matrix{Float64}
    weight::Matrix{Float64}
    entered::Matrix{Float64}
    settled::Matrix{Float64}
    pnl::Matrix{Float64}
    idx::Vector{<:TimeType}
    function Portfolio(universe::Universe)
        idx = get_overall_index(universe)
        quantity = weight = entry_price = close_price = pnl =
            zeros(Float64, length(idx), length(universe.assets))
        return new(quantity, weight, entered, settled, pnl, idx)
    end
end

function update_portfolio!(portfolio::Portfolio, order::Order, universe::Universe)
    i = findfirst(portfolio.idx .> order.time)
    quantity[i]
end
