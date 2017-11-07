#=
functions to calculate summary statistics on the performance of a backtest
=#

function cum_pnl(results::Results)::Float64
    result = 0.0
    @inbounds for val in values(results.backtest)
        pnl::Vector = val[:PNL].values[:]
        result += sum(pnl)
    end
    return result
end


