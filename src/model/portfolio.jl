
mutable struct Portfolio
    holdings::TS
    values::TS
    weights::TS
    pnl::TS
    nav::TS
    function Portfolio(universe::Universe, initial_value::Float64=1e6)
        N = length(universe.index)
        holdings = values = weights = pnl =
            TS(zeros(N, length(universe.assets)), universe.index, universe.assets)
        nav = TS(zeros(N, 2) .+ initial_value, universe.index, [:Total, :Cash])
        return new(holdings, values, weights, pnl, nav)
    end
end

function update!(portfolio::Portfolio, asset::String, timestamp::TimeType, price::Float64)::Nothing
    i = findfirst(portfolio.nav.index .== timestamp)
    j = findfirst(portfolio.holdings.fields .== Symbol(asset))
    portfolio.holdings.values[i,j] = portfolio.holdings.values[i-1,j]
    portfolio.values.values[i,j] = portfolio.holdings.values[i,j]*price
    portfolio.pnl.values[i,j] = portfolio.values.values[i,j] - portfolio.values.values[i-1,j]
    update!(portfolio, timestamp)
    return nothing
end

function update!(portfolio::Portfolio, timestamp::TimeType)::Nothing
    portfolio.nav.values[timestamp,1] = sum(portfolio.values.values[timestamp,:]) .+ portfolio.nav.values[timestamp,2]
    portfolio.weights.values[timestamp,:] = portfolio.weights.values[timestamp,:] ./ portfolio.nav.values[timestamp,1]
    return nothing
end
