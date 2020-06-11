#=
methods for handling backtest results of strategy objects
=#

struct Backtest
    trades::Dict{String,TS}
    backtest::Dict{String,TS{Float64}}  # results
    optimization::Matrix{Float64}
    function Backtest(trades::Dict{String,TS} = Dict{String,TS}(),
                      backtest::Dict{String,TS{Float64}} = Dict{String,TS{Float64}}(),
                      optimization::Matrix{Float64} = Matrix{Float64}(undef,0,0)
                      )
        return new(trades, backtest, optimization)
    end
end


function cum_pnl(results::Backtest)::Float64
    result = 0.0
    @inbounds for val in values(results.backtest)
        pnl::Vector = val[:PNL].values[:]
        result += sum(pnl)
    end
    return result
end

function cum_pnl(results::Dict{String, TS{Float64}})::Float64
    result = 0.0
    @inbounds for val in values(results)
        pnl::Vector = val[:PNL].values[:]
        result += sum(pnl)
    end
    return result
end
